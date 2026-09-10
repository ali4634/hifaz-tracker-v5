import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/daily_record.dart';
import '../models/student.dart';

import 'backup_migration_service.dart';

/// A complete exported database snapshot.
class BackupData {
  final List<Student> students;
  final List<DailyRecord> records;
  final AppSettings? settings;
  final int version;

  const BackupData({
    required this.students,
    required this.records,
    this.settings,
    this.version = 5,
  });

  Map<String, dynamic> toJson() => {
    'app': 'HifazTracker',
    'version': version,
    'exportedAt': DateTime.now().toIso8601String(),
    'students': students.map((s) => s.toJson()).toList(),
    'records': records.map((r) => r.toJson()).toList(),
    'settings': settings?.toJson(),
  };

  factory BackupData.fromJson(Map<String, dynamic> rawJson) {
    final json = BackupMigrationService.migrateIfNeeded(rawJson);
    return BackupData(
      version: json['version'] as int? ?? 5,
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

/// Backs up the whole database to a JSON file and restores from one.
class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  /// Writes a JSON backup into `<documents>/backups/` and returns the path.
  Future<String> exportBackup({required BackupData data}) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}${Platform.pathSeparator}backups');
    if (!backupDir.existsSync()) backupDir.createSync(recursive: true);

    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File(
      '${backupDir.path}${Platform.pathSeparator}hifaz_backup_$stamp.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
    );
    return file.path;
  }

  /// Picks a JSON backup file and parses it. Returns null if cancelled/invalid.
  Future<BackupData?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final Uint8List bytes;
    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      return null;
    }

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) return null;
      final map = BackupMigrationService.migrateIfNeeded(
        Map<String, dynamic>.from(decoded),
      );
      return BackupData.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
