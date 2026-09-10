import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/daily_record.dart';
import '../models/student.dart';
import 'backup_migration_service.dart';

/// Google Drive backup metadata stored alongside the backup JSON.
class BackupMetadata {
  final int backupVersion;
  final String app;
  final String appVersion;
  final int databaseVersion;
  final String createdAt;
  final int studentCount;
  final int recordCount;

  const BackupMetadata({
    required this.backupVersion,
    required this.app,
    required this.appVersion,
    required this.databaseVersion,
    required this.createdAt,
    required this.studentCount,
    required this.recordCount,
  });

  Map<String, dynamic> toJson() => {
    'backupVersion': backupVersion,
    'app': app,
    'appVersion': appVersion,
    'databaseVersion': databaseVersion,
    'createdAt': createdAt,
    'studentCount': studentCount,
    'recordCount': recordCount,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    backupVersion: json['backupVersion'] as int? ?? 1,
    app: json['app'] as String? ?? 'HifzTracker',
    appVersion: json['appVersion'] as String? ?? '1.0.0',
    databaseVersion: json['databaseVersion'] as int? ?? 1,
    createdAt: json['createdAt'] as String? ?? '',
    studentCount: json['studentCount'] as int? ?? 0,
    recordCount: json['recordCount'] as int? ?? 0,
  );
}

/// A backup entry listed from Google Drive.
class DriveBackupEntry {
  final String fileId;
  final String fileName;
  final DateTime createdAt;
  final int studentCount;
  final int recordCount;

  const DriveBackupEntry({
    required this.fileId,
    required this.fileName,
    required this.createdAt,
    required this.studentCount,
    required this.recordCount,
  });
}

/// Complete backup data for Google Drive.
class DriveBackupData {
  final List<Student> students;
  final List<DailyRecord> records;
  final AppSettings? settings;
  final BackupMetadata metadata;

  const DriveBackupData({
    required this.students,
    required this.records,
    this.settings,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'metadata': metadata.toJson(),
    'students': students.map((s) => s.toJson()).toList(),
    'records': records.map((r) => r.toJson()).toList(),
    'settings': settings?.toJson(),
  };

  factory DriveBackupData.fromJson(Map<String, dynamic> rawJson) {
    final json = BackupMigrationService.migrateIfNeeded(rawJson);
    return DriveBackupData(
      metadata: json['metadata'] != null
          ? BackupMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>,
            )
          : BackupMetadata(
              backupVersion: 5,
              app: 'HifazTracker',
              appVersion: '5.0.0',
              databaseVersion: 5,
              createdAt: DateTime.now().toIso8601String(),
              studentCount: (json['students'] as List?)?.length ?? 0,
              recordCount: (json['records'] as List?)?.length ?? 0,
            ),
      students: (json['students'] as List<dynamic>? ?? const [])
          .map((e) => Student.fromJson(e as Map<String, dynamic>))
          .toList(),
      records: (json['records'] as List<dynamic>? ?? const [])
          .map((e) => DailyRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: json['settings'] == null
          ? null
          : AppSettings.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }
}

/// Google Drive backup and restore service.
///
/// Uses Google Sign-In for authentication and the Google Drive API v3 for
/// file operations. The app remains fully offline — Google Sign-In is only
/// triggered when the user explicitly performs a backup or restore.
class GoogleDriveService {
  GoogleDriveService._();

  static final GoogleDriveService instance = GoogleDriveService._();

  static const _folderName = 'Hifz Tracker Backups';
  static const _filePrefix = 'HifzTracker_Backup_';
  static const _scopes = [drive.DriveApi.driveFileScope];

  GoogleSignIn? _googleSignIn;
  http.Client? _authClient;
  String? _folderId;

  bool get isSignedIn => _authClient != null;
  bool get isSignedOut => _authClient == null;

  GoogleSignInAccount? get currentUser => _googleSignIn?.currentUser;

  /// Initializes Google Sign-In. Must be called before any other method.
  void init() {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );
  }

  /// Signs in to Google. Returns true on success.
  Future<bool> signIn() async {
    try {
      if (_googleSignIn == null) init();
      final account = await _googleSignIn!.signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      _authClient = _AuthHeadersClient(authHeaders);
      return true;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return false;
    }
  }

  /// Signs out of Google.
  Future<void> signOut() async {
    try {
      await _googleSignIn?.disconnect();
    } catch (_) {}
    _authClient = null;
    _folderId = null;
  }

  /// Gets or creates the backup folder in Google Drive.
  Future<String> _getOrCreateFolder() async {
    if (_folderId != null) return _folderId!;

    final client = _getClient();
    final driveApi = drive.DriveApi(client);

    // Search for existing folder.
    final result = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false",
      $fields: 'files(id, name)',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      _folderId = result.files!.first.id;
      return _folderId!;
    }

    // Create folder.
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await driveApi.files.create(folder);
    _folderId = created.id;
    return _folderId!;
  }

  /// Backs up all app data to Google Drive.
  ///
  /// Returns a [BackupMetadata] on success, or throws on failure.
  Future<BackupMetadata> backup({
    required List<Student> students,
    required List<DailyRecord> records,
    required AppSettings? settings,
  }) async {
    final client = _getClient();
    final driveApi = drive.DriveApi(client);
    final folderId = await _getOrCreateFolder();

    final now = DateTime.now();
    final stamp = '${now.year}-${_pad(now.month)}-${_pad(now.day)}_'
        '${_pad(now.hour)}-${_pad(now.minute)}-${_pad(now.second)}';
    final fileName = '$_filePrefix$stamp.json';

    final metadata = BackupMetadata(
      backupVersion: 1,
      app: 'HifzTracker',
      appVersion: AppConstants.appVersion,
      databaseVersion: 1,
      createdAt: now.toIso8601String(),
      studentCount: students.length,
      recordCount: records.length,
    );

    final backupData = DriveBackupData(
      students: students,
      records: records,
      settings: settings,
      metadata: metadata,
    );

    final jsonContent = const JsonEncoder.withIndent('  ').convert(
      backupData.toJson(),
    );
    final bytes = utf8.encode(jsonContent);

    // Check if a file with the same name exists (overwrite).
    final existing = await driveApi.files.list(
      q: "'$folderId' in parents and name='$fileName' and trashed=false",
      $fields: 'files(id)',
    );

    final media = drive.Media(
      Stream.fromIterable([bytes]),
      bytes.length,
      contentType: 'application/json',
    );

    if (existing.files != null && existing.files!.isNotEmpty) {
      // Update existing file.
      final fileId = existing.files!.first.id!;
      await driveApi.files.update(
        drive.File()..name = fileName,
        fileId,
        uploadMedia: media,
      );
    } else {
      // Create new file.
      final file = drive.File()
        ..name = fileName
        ..parents = [folderId];
      await driveApi.files.create(file, uploadMedia: media);
    }

    // Clean up old backups (keep last 10).
    await _cleanupOldBackups(driveApi, folderId);

    return metadata;
  }

  /// Lists available backups on Google Drive.
  Future<List<DriveBackupEntry>> listBackups() async {
    final client = _getClient();
    final driveApi = drive.DriveApi(client);
    final folderId = await _getOrCreateFolder();

    final result = await driveApi.files.list(
      q: "'$folderId' in parents and name contains '$_filePrefix' and trashed=false",
      $fields: 'files(id, name, createdTime)',
      orderBy: 'createdTime desc',
    );

    final entries = <DriveBackupEntry>[];
    if (result.files == null || result.files!.isEmpty) return entries;

    for (final file in result.files!) {
      if (file.id == null || file.name == null) continue;

      // Try to download and read metadata from the file.
      DriveBackupEntry entry;
      try {
        final media = await driveApi.files.get(
          file.id!,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;
        final content = await media.stream
            .fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
        final decoded = jsonDecode(utf8.decode(content));
        final data = DriveBackupData.fromJson(decoded as Map<String, dynamic>);
        entry = DriveBackupEntry(
          fileId: file.id!,
          fileName: file.name!,
          createdAt: data.metadata.createdAt.isNotEmpty
              ? DateTime.tryParse(data.metadata.createdAt) ??
                    file.createdTime ?? DateTime.now()
              : file.createdTime ?? DateTime.now(),
          studentCount: data.metadata.studentCount,
          recordCount: data.metadata.recordCount,
        );
      } catch (_) {
        entry = DriveBackupEntry(
          fileId: file.id!,
          fileName: file.name!,
          createdAt: file.createdTime ?? DateTime.now(),
          studentCount: 0,
          recordCount: 0,
        );
      }
      entries.add(entry);
    }

    return entries;
  }

  /// Restores a specific backup from Google Drive.
  Future<DriveBackupData> restore({required String fileId}) async {
    final client = _getClient();
    final driveApi = drive.DriveApi(client);

    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final content = await media.stream
        .fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
    final decoded = jsonDecode(utf8.decode(content));
    return DriveBackupData.fromJson(decoded as Map<String, dynamic>);
  }

  /// Cleans up old backups, keeping only the most recent [maxKeep].
  Future<void> _cleanupOldBackups(
    drive.DriveApi driveApi,
    String folderId, {
    int maxKeep = 10,
  }) async {
    try {
      final result = await driveApi.files.list(
        q: "'$folderId' in parents and name contains '$_filePrefix' and trashed=false",
        $fields: 'files(id, createdTime)',
        orderBy: 'createdTime desc',
      );

      if (result.files == null || result.files!.length <= maxKeep) return;

      // Delete excess files (oldest first).
      final toDelete = result.files!.sublist(maxKeep);
      for (final file in toDelete) {
        if (file.id != null) {
          await driveApi.files.delete(file.id!);
        }
      }
    } catch (e) {
      debugPrint('Failed to clean up old backups: $e');
    }
  }

  http.Client _getClient() {
    if (_authClient == null) {
      throw StateError('Not signed in to Google. Call signIn() first.');
    }
    return _authClient!;
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Internal HTTP client that injects Google auth headers into every request.
class _AuthHeadersClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthHeadersClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request..headers.addAll(_headers));
  }

  @override
  void close() => _inner.close();
}
