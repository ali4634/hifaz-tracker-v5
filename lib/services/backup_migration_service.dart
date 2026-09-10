import 'package:flutter/foundation.dart';

/// Service to handle migrating legacy Version 4 JSON backups to Version 5 data structure.
class BackupMigrationService {
  BackupMigrationService._();

  /// Inspects the raw JSON map. If it lacks a `metadata` field (indicating a Version 4 backup),
  /// converts students, attendance records, settings, and metadata to Version 5 schema.
  static Map<String, dynamic> migrateIfNeeded(Map<String, dynamic> json) {
    final hasMetadata = json['metadata'] != null;
    final isV5App = json['app'] == 'HifazTracker' &&
        json['version'] != null &&
        (json['version'] as int? ?? 0) >= 5;

    // Already a valid Version 5 structure.
    if (hasMetadata && isV5App) {
      return json;
    }

    debugPrint('BackupMigration: Migrating legacy v4 JSON backup to v5 format...');
    final migratedMap = Map<String, dynamic>.from(json);

    // 1. Version & Metadata identification
    final rawStudents = json['students'] as List<dynamic>? ??
        json['studentsList'] as List<dynamic>? ??
        [];
    final rawRecords = json['records'] as List<dynamic>? ??
        json['attendance'] as List<dynamic>? ??
        [];

    if (!hasMetadata) {
      migratedMap['metadata'] = {
        'backupVersion': 5,
        'app': 'HifazTracker',
        'appVersion': '5.0.0',
        'databaseVersion': 5,
        'createdAt': json['exportedAt'] as String? ??
            json['createdAt'] as String? ??
            DateTime.now().toIso8601String(),
        'studentCount': rawStudents.length,
        'recordCount': rawRecords.length,
      };
      migratedMap['app'] = 'HifazTracker';
      migratedMap['version'] = 5;
    }

    // 2. Students Migration (v4 -> v5)
    final migratedStudents = <Map<String, dynamic>>[];
    for (final item in rawStudents) {
      if (item is Map<String, dynamic>) {
        final sMap = Map<String, dynamic>.from(item);

        // fullName -> name
        if (sMap.containsKey('fullName') &&
            (!sMap.containsKey('name') || (sMap['name'] as String? ?? '').isEmpty)) {
          sMap['name'] = sMap['fullName'];
        }

        // phoneNumber -> phone
        if (sMap.containsKey('phoneNumber') &&
            (!sMap.containsKey('phone') || (sMap['phone'] as String? ?? '').isEmpty)) {
          sMap['phone'] = sMap['phoneNumber'];
        }

        // sectionId -> section
        if (sMap.containsKey('sectionId') &&
            (!sMap.containsKey('section') || (sMap['section'] as String? ?? '').isEmpty)) {
          sMap['section'] = sMap['sectionId'];
        }

        // manzilOrder == 'reverse' -> manzilReverse boolean
        if (sMap.containsKey('manzilOrder')) {
          final order = sMap['manzilOrder'] as String?;
          sMap['manzilReverse'] = (order == 'reverse');
        }

        migratedStudents.add(sMap);
      }
    }
    migratedMap['students'] = migratedStudents;

    // 3. Records / Attendance Migration (v4 -> v5)
    final migratedRecords = <Map<String, dynamic>>[];
    for (final item in rawRecords) {
      if (item is Map<String, dynamic>) {
        final rMap = Map<String, dynamic>.from(item);

        // isPresent -> present
        if (rMap.containsKey('isPresent') && !rMap.containsKey('present')) {
          rMap['present'] = rMap['isPresent'];
        }

        migratedRecords.add(rMap);
      }
    }
    migratedMap['records'] = migratedRecords;

    // 4. Settings Migration (v4 -> v5)
    if (json['settings'] is Map<String, dynamic>) {
      final setMap = Map<String, dynamic>.from(json['settings'] as Map<String, dynamic>);

      // isDarkMode -> themeMode ('dark' / 'light')
      if (setMap.containsKey('isDarkMode') && !setMap.containsKey('themeMode')) {
        final isDark = setMap['isDarkMode'] as bool? ?? true;
        setMap['themeMode'] = isDark ? 'dark' : 'light';
      }

      // languageCode -> locale ('ur' / 'en')
      if (setMap.containsKey('languageCode') && !setMap.containsKey('locale')) {
        setMap['locale'] = setMap['languageCode'];
      }

      migratedMap['settings'] = setMap;
    }

    return migratedMap;
  }
}
