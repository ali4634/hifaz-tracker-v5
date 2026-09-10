import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/daily_record.dart';
import '../models/fee_record.dart';
import '../models/student.dart';

/// Thin persistence layer over Hive boxes.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  late final Box<Student> studentsBox;
  late final Box<DailyRecord> recordsBox;
  late final Box<AppSettings> settingsBox;
  late final Box<FeeRecord> feesBox;
  late final Box naaghaSeenBox;

  Future<void> init() async {
    studentsBox = await _openBox<Student>(AppConstants.studentsBoxName);
    recordsBox = await _openBox<DailyRecord>(AppConstants.recordsBoxName);
    settingsBox = await _openBox<AppSettings>(AppConstants.settingsBoxName);
    feesBox = await _openBox<FeeRecord>(AppConstants.feesBoxName);
    naaghaSeenBox = await _openBox<dynamic>(AppConstants.naaghaSeenBoxName);
  }

  /// Opens a box, recovering from a corrupted file (e.g. a crash mid-write or
  /// a schema change from an older build) by deleting it and starting fresh —
  /// mirroring v4's database repair. A damaged box must never block startup.
  Future<Box<T>> _openBox<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint('Hive box "$name" corrupted ($e) — deleting and recreating.');
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {
        // Even deletion failed; attempt to open anyway (may be empty).
      }
      return Hive.openBox<T>(name);
    }
  }

  // ── Students ──────────────────────────────────────────────────────────────
  List<Student> get students => studentsBox.values.toList();

  Future<void> putStudent(Student student) =>
      studentsBox.put(student.id, student);

  Future<void> deleteStudent(String id) => studentsBox.delete(id);

  // ── Records ───────────────────────────────────────────────────────────────
  List<DailyRecord> get records => recordsBox.values.toList();

  Future<void> putRecord(DailyRecord record) =>
      recordsBox.put(record.id, record);

  Future<void> deleteRecord(String id) => recordsBox.delete(id);

  Future<void> deleteRecordsForStudent(String studentId) async {
    final ids = recordsBox.values
        .where((r) => r.studentId == studentId)
        .map((r) => r.id)
        .toList();
    await recordsBox.deleteAll(ids);
  }

  // ── Fees ───────────────────────────────────────────────────────────────────
  List<FeeRecord> get fees => feesBox.values.toList();

  Future<void> putFee(FeeRecord fee) =>
      feesBox.put(fee.id, fee);

  Future<void> deleteFee(String id) => feesBox.delete(id);

  Future<void> deleteFeesForStudent(String studentId) async {
    final ids = feesBox.values
        .where((f) => f.studentId == studentId)
        .map((f) => f.id)
        .toList();
    await feesBox.deleteAll(ids);
  }

  FeeRecord? feeForStudentMonth(String studentId, int month, int year) {
    for (final f in feesBox.values) {
      if (f.studentId == studentId && f.month == month && f.year == year) {
        return f;
      }
    }
    return null;
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  AppSettings? get settings => settingsBox.get('main');

  Future<void> putSettings(AppSettings settings) =>
      settingsBox.put('main', settings);

  // ── Naagha seen state ─────────────────────────────────────────────────────
  List<String> get naaghaSeen => List<String>.from(
    naaghaSeenBox.get('seen', defaultValue: const <String>[]) as List,
  );

  Future<void> putNaaghaSeen(List<String> keys) =>
      naaghaSeenBox.put('seen', keys);

  Future<void> clearAll() async {
    await studentsBox.clear();
    await recordsBox.clear();
    await settingsBox.clear();
    await feesBox.clear();
    await naaghaSeenBox.clear();
  }
}
