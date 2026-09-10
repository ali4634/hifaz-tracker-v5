import 'package:flutter/foundation.dart';

import '../core/utils/app_date_utils.dart';
import '../core/utils/id_gen.dart';
import '../core/utils/math_engine.dart';
import '../core/utils/warning_engine.dart';
import '../models/app_settings.dart';
import '../models/daily_record.dart';
import '../models/fee_record.dart';
import '../models/student.dart';
import '../services/backup_service.dart';
import '../services/naagha_service.dart';
import '../services/storage_service.dart';

/// Central application state: students, records, current section & date,
/// plus the negligence warning cache.
class AppProvider extends ChangeNotifier {
  final StorageService storage;

  AppProvider(this.storage);

  List<Student> _students = [];
  List<DailyRecord> _records = [];
  List<FeeRecord> _fees = [];
  String _selectedSection = 'A';
  DateTime _selectedDate = AppDateUtils.today();
  final Map<String, List<WarningInfo>> _warnings = {};
  Set<String> _naaghaSeen = {};
  bool _initialized = false;

  bool get initialized => _initialized;
  List<Student> get students => List.unmodifiable(_students);
  List<DailyRecord> get records => List.unmodifiable(_records);
  List<FeeRecord> get fees => List.unmodifiable(_fees);
  String get selectedSection => _selectedSection;
  DateTime get selectedDate => _selectedDate;

  Student? studentById(String id) {
    for (final s in _students) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Students of the currently selected section; starred students pinned first.
  List<Student> get sectionStudents {
    final list = _students.where((s) => s.section == _selectedSection).toList()
      ..sort((a, b) {
        if (a.isStarred != b.isStarred) return a.isStarred ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }

  DailyRecord? recordForOn(String studentId, DateTime date) {
    final key = AppDateUtils.key(date);
    for (final r in _records) {
      if (r.studentId == studentId && r.date == key) return r;
    }
    return null;
  }

  DailyRecord? recordFor(String studentId) =>
      recordForOn(studentId, _selectedDate);

  List<DailyRecord> recordsForStudent(String studentId) =>
      _records.where((r) => r.studentId == studentId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<WarningInfo> warningsFor(String studentId) =>
      List.unmodifiable(_warnings[studentId] ?? const []);

  int get totalWarnings =>
      _warnings.values.fold(0, (sum, list) => sum + list.length);

  // ── Naagha (gap) alerts ──────────────────────────────────────────────────

  /// All students with a gap (naagha) in Sabaq, Sabqi or Manzil of at least
  /// [thresholdDays] consecutive days. Computed on demand so the threshold is
  /// always read fresh from settings.
  List<NaaghaAlert> naaghaAlerts(int thresholdDays) => NaaghaService.detect(
    students: _students,
    records: _records,
    thresholdDays: thresholdDays,
  );

  /// Keys (`studentId|track`) of naagha alerts the teacher has already viewed,
  /// so the bell badge stays clean until a new gap appears.
  Set<String> get naaghaSeenKeys => Set.unmodifiable(_naaghaSeen);

  /// Number of students (across all sections) with at least one active gap
  /// that has NOT been viewed yet. Drives the bell badge / banner.
  int naaghaUnseenStudentCount(int thresholdDays) {
    final alerts = naaghaAlerts(thresholdDays);
    final unseen = alerts.where((a) => !_naaghaSeen.contains(a.seenKey));
    return unseen.map((a) => a.student.id).toSet().length;
  }

  /// Marks [alerts] as viewed so they stop counting towards the bell badge.
  Future<void> markNaaghaSeen(Iterable<NaaghaAlert> alerts) async {
    final before = _naaghaSeen.length;
    _naaghaSeen.addAll(alerts.map((a) => a.seenKey));
    if (_naaghaSeen.length == before) return;
    await storage.putNaaghaSeen(_naaghaSeen.toList());
    notifyListeners();
  }

  // ── Init / bulk operations ────────────────────────────────────────────────

  Future<void> init() async {
    _students = storage.students;
    _records = storage.records;
    _fees = storage.fees;
    _naaghaSeen = storage.naaghaSeen.toSet();
    if (_students.isNotEmpty) {
      _selectedSection = _students.first.section;
    }
    _recomputeWarnings();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _recomputeWarnings() async {
    final settings = storage.settings ?? AppSettings.defaults();
    final byStudent = <String, List<WarningInfo>>{};
    for (final s in _students) {
      final w = WarningEngine.detect(
        student: s,
        allRecords: _records,
        inactiveThreshold: settings.warningInactiveDays,
        repetitionThreshold: settings.warningRepetitionCount,
        absenceWindowDays: settings.absenceWindowDays,
        absenceThreshold: settings.absenceWarningCount,
      );
      if (w.isNotEmpty) byStudent[s.id] = w;
    }
    _warnings
      ..clear()
      ..addAll(byStudent);
  }

  void _recomputeAndNotify() {
    _recomputeWarnings();
    notifyListeners();
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void setSection(String section) {
    if (_selectedSection == section) return;
    _selectedSection = section;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = AppDateUtils.dateOnly(date);
    notifyListeners();
  }

  void nextDay() => setDate(_selectedDate.add(const Duration(days: 1)));
  void previousDay() =>
      setDate(_selectedDate.subtract(const Duration(days: 1)));

  // ── Student CRUD ──────────────────────────────────────────────────────────

  Future<void> addStudent(Student student) async {
    _students.add(student);
    await storage.putStudent(student);
    _recomputeAndNotify();
  }

  Future<void> updateStudent(Student student) async {
    final i = _students.indexWhere((s) => s.id == student.id);
    if (i >= 0) _students[i] = student;
    await storage.putStudent(student);
    _recomputeAndNotify();
  }

  Future<void> deleteStudent(String id) async {
    _students.removeWhere((s) => s.id == id);
    _records.removeWhere((r) => r.studentId == id);
    await storage.deleteStudent(id);
    await storage.deleteRecordsForStudent(id);
    final before = _naaghaSeen.length;
    _naaghaSeen.removeWhere((k) => k.startsWith('$id|'));
    if (_naaghaSeen.length != before) {
      await storage.putNaaghaSeen(_naaghaSeen.toList());
    }
    _recomputeAndNotify();
  }

  Future<void> toggleStar(String id) async {
    final s = studentById(id);
    if (s == null) return;
    s.isStarred = !s.isStarred;
    await storage.putStudent(s);
    _recomputeAndNotify();
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  Future<void> toggleAttendance(String studentId) async {
    final existing = recordFor(studentId);
    if (existing == null) {
      final rec = DailyRecord(
        id: IdGen.newId(),
        studentId: studentId,
        date: AppDateUtils.key(_selectedDate),
        present: true,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
      _records.add(rec);
      await storage.putRecord(rec);
    } else {
      existing.present = !existing.present;
      existing.lastUpdated = DateTime.now().millisecondsSinceEpoch;
      await storage.putRecord(existing);
    }
    _recomputeAndNotify();
  }

  // ── Lesson entry ──────────────────────────────────────────────────────────

  /// Saves attendance + lesson tracks for [studentId] on [date].
  ///
  /// When a Manzil lesson is logged, the student's current position advances
  /// and, on wrap-around, the cycle counter increments.
  Future<void> saveLessons({
    required String studentId,
    required DateTime date,
    required bool present,
    SabaqEntry? sabaq,
    SabqiEntry? sabqi,
    ManzilEntry? manzil,
  }) async {
    final key = AppDateUtils.key(date);
    var rec = recordForOn(studentId, date);
    if (rec == null) {
      rec = DailyRecord(
        id: IdGen.newId(),
        studentId: studentId,
        date: key,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
      _records.add(rec);
    }
    rec
      ..present = present
      ..sabaq = sabaq
      ..sabqi = sabqi
      ..manzil = manzil
      ..lastUpdated = DateTime.now().millisecondsSinceEpoch;
    await storage.putRecord(rec);

    if (manzil != null) {
      final student = studentById(studentId);
      if (student != null) {
        final logged = ManzilPosition(manzil.juz, manzil.ruba);
        final next = MathEngine.nextManzilPosition(
          logged,
          student.manzilStartJuz,
          student.manzilEndJuz,
          reverse: student.manzilReverse,
        );
        student
          ..currentManzilJuz = next.juz
          ..currentManzilRuba = next.ruba;
        if (MathEngine.completesCycle(logged, student.manzilEndJuz)) {
          student.manzilCycle += 1;
        }
        await storage.putStudent(student);
      }
    }

    // A freshly logged lesson resolves that track's gap, so drop the
    // "seen" state — a NEW gap later will ring the bell again.
    final loggedTracks = <NaaghaTrack>[
      if (sabaq != null) NaaghaTrack.sabaq,
      if (sabqi != null) NaaghaTrack.sabqi,
      if (manzil != null) NaaghaTrack.manzil,
    ];
    if (loggedTracks.isNotEmpty) {
      var pruned = false;
      for (final t in loggedTracks) {
        pruned = _naaghaSeen.remove('$studentId|${t.name}') || pruned;
      }
      if (pruned) await storage.putNaaghaSeen(_naaghaSeen.toList());
    }

    _recomputeAndNotify();
  }

  // ── Fees ────────────────────────────────────────────────────────────────────

  FeeRecord? feeForStudentMonth(String studentId, int month, int year) {
    for (final f in _fees) {
      if (f.studentId == studentId && f.month == month && f.year == year) {
        return f;
      }
    }
    return null;
  }

  List<FeeRecord> feesForMonth(int month, int year) {
    return _fees.where((f) => f.month == month && f.year == year).toList();
  }

  /// Toggle fee paid status for a student in the given month.
  Future<void> toggleFee({
    required String studentId,
    required int month,
    required int year,
  }) async {
    final existing = feeForStudentMonth(studentId, month, year);
    if (existing != null) {
      final newPaid = !existing.paid;
      final newFee = FeeRecord(
        id: existing.id,
        studentId: existing.studentId,
        month: existing.month,
        year: existing.year,
        paid: newPaid,
        paidDate: newPaid
            ? '$year-${month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
            : null,
      );
      final idx = _fees.indexWhere((f) => f.id == existing.id);
      if (idx != -1) _fees[idx] = newFee;
      await storage.putFee(newFee);
    } else {
      final fee = FeeRecord(
        id: '${studentId}_${year}_${month.toString().padLeft(2, '0')}',
        studentId: studentId,
        month: month,
        year: year,
        paid: true,
        paidDate: '$year-${month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
      );
      _fees.add(fee);
      await storage.putFee(fee);
    }
    notifyListeners();
  }

  /// Number of students in a section who have paid fees for the given month.
  int paidCountForMonth(String section, int month, int year) {
    final sectionStudentIds = _students
        .where((s) => s.section == section)
        .map((s) => s.id)
        .toSet();
    return _fees
        .where((f) =>
            f.month == month &&
            f.year == year &&
            f.paid &&
            sectionStudentIds.contains(f.studentId))
        .length;
  }

  /// Total students in a section.
  int totalStudentsInSection(String section) {
    return _students.where((s) => s.section == section).length;
  }

  // ── Warnings ──────────────────────────────────────────────────────────────

  Future<void> acknowledgeWarning(String studentId, WarningInfo warning) async {
    final s = studentById(studentId);
    if (s == null) return;
    if (!s.acknowledgedWarnings.contains(warning.id)) {
      s.acknowledgedWarnings.add(warning.id);
      await storage.putStudent(s);
    }
    _recomputeAndNotify();
  }

  Future<void> resetAcknowledgedWarnings(String studentId) async {
    final s = studentById(studentId);
    if (s == null || s.acknowledgedWarnings.isEmpty) return;
    s.acknowledgedWarnings.clear();
    await storage.putStudent(s);
    _recomputeAndNotify();
  }

  // ── Backup / restore ──────────────────────────────────────────────────────

  Future<String> exportBackup() => BackupService.instance.exportBackup(
    data: BackupData(
      students: _students,
      records: _records,
      settings: storage.settings,
    ),
  );

  /// Replaces all in-memory + persisted data with a backup snapshot.
  Future<void> restoreBackup(BackupData data) async {
    await storage.clearAll();
    for (final s in data.students) {
      await storage.putStudent(s);
    }
    for (final r in data.records) {
      await storage.putRecord(r);
    }
    if (data.settings != null) {
      await storage.putSettings(data.settings!);
    }
    _students = storage.students;
    _records = storage.records;
    if (_students.isNotEmpty) {
      _selectedSection = _students.first.section;
    }
    _recomputeAndNotify();
  }

  Future<void> eraseAllData() async {
    await storage.clearAll();
    _students = [];
    _records = [];
    _naaghaSeen = {};
    _recomputeAndNotify();
  }

  // ── Cloud sync support ────────────────────────────────────────────────────

  /// Merges a remote (cloud) snapshot into the local store. For a single-phone
  /// workflow the local data is the source of truth, so only rows that are
  /// MISSING locally are restored — local rows are never overwritten.
  Future<void> mergeRemoteData({
    List<Student> remoteStudents = const [],
    List<DailyRecord> remoteRecords = const [],
  }) async {
    var changed = false;
    for (final s in remoteStudents) {
      if (studentById(s.id) != null) continue;
      _students.add(s);
      await storage.putStudent(s);
      changed = true;
    }
    for (final r in remoteRecords) {
      if (_records.any((x) => x.id == r.id)) continue;
      _records.add(r);
      await storage.putRecord(r);
      changed = true;
    }
    if (changed) _recomputeAndNotify();
  }
}
