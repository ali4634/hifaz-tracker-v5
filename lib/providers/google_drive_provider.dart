import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/daily_record.dart';
import '../models/student.dart';
import '../services/google_drive_service.dart';
import '../services/storage_service.dart';

/// State management for Google Drive backup/restore.
///
/// The app is offline-first: Google Drive operations are optional and never
/// block the local workflow.
class GoogleDriveProvider extends ChangeNotifier {
  final StorageService storage;

  GoogleDriveProvider(this.storage);

  bool _initialized = false;
  bool _busy = false;
  bool _signedIn = false;
  String? _error;
  DateTime? _lastBackupAt;
  List<DriveBackupEntry> _backups = [];

  bool get initialized => _initialized;
  bool get busy => _busy;
  bool get signedIn => _signedIn;
  String? get error => _error;
  DateTime? get lastBackupAt => _lastBackupAt;
  List<DriveBackupEntry> get backups => List.unmodifiable(_backups);
  String? get currentUserEmail => GoogleDriveService.instance.currentUser?.email;

  Future<void> init() async {
    GoogleDriveService.instance.init();

    // Restore last backup time from local storage.
    final box = await _openMetaBox();
    final saved = box.get('lastBackupAt');
    if (saved is int && saved > 0) {
      _lastBackupAt = DateTime.fromMillisecondsSinceEpoch(saved);
    }
    _initialized = true;
    notifyListeners();
  }

  /// Signs in to Google.
  Future<bool> signIn() async {
    _error = null;
    _busy = true;
    notifyListeners();

    try {
      final ok = await GoogleDriveService.instance.signIn();
      _signedIn = ok;
      if (!ok) {
        _error = 'Google Sign-In was cancelled';
      }
    } catch (e) {
      _error = e.toString();
      _signedIn = false;
    } finally {
      _busy = false;
      notifyListeners();
    }
    return _signedIn;
  }

  /// Signs out of Google.
  Future<void> signOut() async {
    try {
      await GoogleDriveService.instance.signOut();
    } catch (_) {}
    _signedIn = false;
    _backups = [];
    notifyListeners();
  }

  /// Creates a backup to Google Drive.
  Future<bool> backup({
    required List<Student> students,
    required List<DailyRecord> records,
    required AppSettings? settings,
  }) async {
    _error = null;
    _busy = true;
    notifyListeners();

    try {
      if (!_signedIn) {
        final ok = await signIn();
        if (!ok) return false;
      }

      final metadata = await GoogleDriveService.instance.backup(
        students: students,
        records: records,
        settings: settings,
      );

      _lastBackupAt = DateTime.parse(metadata.createdAt);
      final box = await _openMetaBox();
      await box.put('lastBackupAt', _lastBackupAt!.millisecondsSinceEpoch);
      _busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  /// Lists available backups on Google Drive.
  Future<void> refreshBackupList() async {
    _error = null;
    _busy = true;
    notifyListeners();

    try {
      if (!_signedIn) {
        final ok = await signIn();
        if (!ok) return;
      }

      _backups = await GoogleDriveService.instance.listBackups();
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Restores a backup from Google Drive.
  ///
  /// Returns the restored data, or null on failure. The caller should
  /// apply the data to AppProvider and SettingsProvider.
  Future<DriveBackupData?> restore({required String fileId}) async {
    _error = null;
    _busy = true;
    notifyListeners();

    try {
      if (!_signedIn) {
        final ok = await signIn();
        if (!ok) return null;
      }

      final data = await GoogleDriveService.instance.restore(fileId: fileId);
      _busy = false;
      notifyListeners();
      return data;
    } catch (e) {
      _error = e.toString();
      _busy = false;
      notifyListeners();
      return null;
    }
  }

  Future<Box> _openMetaBox() async {
    final boxName = 'google_drive_meta';
    try {
      return await _openBox(boxName);
    } catch (_) {
      try {
        await _deleteBox(boxName);
        return await _openBox(boxName);
      } catch (_) {
        return await _openBox(boxName);
      }
    }
  }

  Future<Box> _openBox(String name) async {
    try {
      return await Hive.openBox(name);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {}
      return Hive.openBox(name);
    }
  }

  Future<void> _deleteBox(String name) async {
    try {
      await Hive.deleteBoxFromDisk(name);
    } catch (_) {}
  }
}
