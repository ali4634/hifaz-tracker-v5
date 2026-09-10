import 'package:flutter_test/flutter_test.dart';

import 'package:huffa_tracker_5/core/utils/warning_engine.dart';
import 'package:huffa_tracker_5/models/daily_record.dart';
import 'package:huffa_tracker_5/models/student.dart';
import 'package:huffa_tracker_5/services/export_service.dart';
import 'package:huffa_tracker_5/services/naagha_service.dart';

void main() {
  group('WarningEngine · skipped pages (v4 port)', () {
    Student student() => Student(id: 's1', name: 'Ali', section: 'A');

    DailyRecord rec(String date, {SabqiEntry? sabqi}) => DailyRecord(
          id: 'r_$date',
          studentId: 's1',
          date: date,
          present: true,
          sabqi: sabqi,
        );

    test('more than 30% of the Sabqi range unread → warning', () {
      final warnings = WarningEngine.detect(
        student: student(),
        allRecords: [
          rec('2026-08-04', sabqi: SabqiEntry(juz: 1, startPage: 1, endPage: 10, heardPage: 3)),
        ],
        inactiveThreshold: 3,
        repetitionThreshold: 3,
        absenceWindowDays: 10,
        absenceThreshold: 3,
      );
      expect(warnings.any((w) => w.type == 'skippedPages' && w.count == 7), isTrue);
    });

    test('small remainder (≤30%) → no skipped-pages warning', () {
      final warnings = WarningEngine.detect(
        student: student(),
        allRecords: [
          rec('2026-08-04', sabqi: SabqiEntry(juz: 1, startPage: 1, endPage: 10, heardPage: 8)),
        ],
        inactiveThreshold: 3,
        repetitionThreshold: 3,
        absenceWindowDays: 10,
        absenceThreshold: 3,
      );
      expect(warnings.where((w) => w.type == 'skippedPages'), isEmpty);
    });

    test('full coverage → no skipped-pages warning', () {
      final warnings = WarningEngine.detect(
        student: student(),
        allRecords: [
          rec('2026-08-04', sabqi: SabqiEntry(juz: 1, startPage: 1, endPage: 10, heardPage: 10)),
        ],
        inactiveThreshold: 3,
        repetitionThreshold: 3,
        absenceWindowDays: 10,
        absenceThreshold: 3,
      );
      expect(warnings.where((w) => w.type == 'skippedPages'), isEmpty);
    });
  });

  group('NaaghaService (v4 port)', () {
    Student student(String id, String name) => Student(id: id, name: name, section: 'A');

    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    DailyRecord rec(String date, {SabaqEntry? sabaq, SabqiEntry? sabqi, ManzilEntry? manzil}) =>
        DailyRecord(
          id: 'r_$date',
          studentId: 's1',
          date: date,
          present: true,
          sabaq: sabaq,
          sabqi: sabqi,
          manzil: manzil,
        );

    test('student with no Sabqi for threshold days is alerted', () {
      final today = DateTime.now();
      final alerts = NaaghaService.detect(
        students: [student('s1', 'Ali')],
        records: [
          rec(
            key(today.subtract(const Duration(days: 4))),
            sabqi: SabqiEntry(juz: 1, startPage: 1, endPage: 2, heardPage: 2),
          ),
        ],
        thresholdDays: 3,
      );
      expect(alerts, hasLength(1));
      expect(alerts.first.student.name, 'Ali');
      expect(alerts.first.track, NaaghaTrack.sabqi);
      expect(alerts.first.daysWithout, 4);
    });

    test('student with Sabqi yesterday is not alerted', () {
      final today = DateTime.now();
      final alerts = NaaghaService.detect(
        students: [student('s1', 'Ali')],
        records: [
          rec(
            key(today.subtract(const Duration(days: 1))),
            sabqi: SabqiEntry(juz: 1, startPage: 1, endPage: 2, heardPage: 2),
          ),
        ],
        thresholdDays: 3,
      );
      expect(alerts, isEmpty);
    });

    test('gaps in Sabaq and Manzil are detected independently', () {
      final today = DateTime.now();
      final alerts = NaaghaService.detect(
        students: [student('s1', 'Ali')],
        records: [
          rec(key(today), sabqi: SabqiEntry(juz: 1, startPage: 1, endPage: 2, heardPage: 2)),
          rec(
            key(today.subtract(const Duration(days: 5))),
            sabaq: SabaqEntry(juz: 1, pageLabel: '3', lines: 4),
            manzil: ManzilEntry(juz: 1, ruba: 2),
          ),
        ],
        thresholdDays: 3,
      );
      // Sabqi today → no alert; Sabaq & Manzil 5 days ago → both alerted.
      expect(alerts, hasLength(2));
      expect(alerts.map((a) => a.track).toSet(), {
        NaaghaTrack.sabaq,
        NaaghaTrack.manzil,
      });
      expect(alerts.every((a) => a.daysWithout == 5), isTrue);
    });

    test('students with no records use their creation date as baseline', () {
      final created = DateTime.now().subtract(const Duration(days: 10));
      final alerts = NaaghaService.detect(
        students: [
          Student(id: 's1', name: 'Ali', section: 'A', createdAt: created.toIso8601String()),
        ],
        records: const [],
        thresholdDays: 7,
      );
      // Created 10 days ago, never recited anything → all three tracks gap.
      expect(alerts, hasLength(3));
      expect(alerts.every((a) => a.daysWithout == 10), isTrue);
    });

    test('threshold of 0 returns no alerts', () {
      expect(
        NaaghaService.detect(students: [], records: [], thresholdDays: 0),
        isEmpty,
      );
    });
  });

  group('StudentMonthlyStats (v4 khulasa port)', () {
    DailyRecord rec(String date,
        {bool present = true, SabqiEntry? sabqi, ManzilEntry? manzil, SabaqEntry? sabaq}) =>
        DailyRecord(
          id: 'r_$date',
          studentId: 's1',
          date: date,
          present: present,
          sabaq: sabaq,
          sabqi: sabqi,
          manzil: manzil,
        );

    test('counts lessons, present/absent and missed', () {
      final stats = StudentMonthlyStats.compute(records: [
        rec('2026-08-01', sabaq: SabaqEntry(juz: 1, pageLabel: '3', lines: 5)),
        rec('2026-08-02', sabqi: SabqiEntry(juz: 1, startPage: 1, endPage: 5, heardPage: 3)),
        rec('2026-08-03', manzil: ManzilEntry(juz: 1, ruba: 2)),
        rec('2026-08-04', present: false),
      ]);
      expect(stats.presentDays, 3);
      expect(stats.absentDays, 1);
      expect(stats.sabaqLessons, 1);
      expect(stats.sabqiLessons, 1);
      expect(stats.manzilLessons, 1);
      expect(stats.manzilRubas, 1);
      // absent day counts as a miss on every track
      expect(stats.missedSabaq, 3);
      expect(stats.missedSabqi, 3);
      expect(stats.missedManzil, 3);
    });

    test('latest Sabqi progress is used (para-based, 15-line mushaf)', () {
      final stats = StudentMonthlyStats.compute(records: [
        rec('2026-08-01', sabqi: SabqiEntry(juz: 1, startPage: 3, endPage: 12, heardPage: 4)),
        rec('2026-08-02', sabqi: SabqiEntry(juz: 1, startPage: 3, endPage: 12, heardPage: 12)),
      ]);
      // Para 1 (15-line): pages 3–22 → 20 pages; latest heard page 12 → 10 done.
      expect(stats.sabqiTotalPages, 20);
      expect(stats.sabqiCompletedPages, 10);
    });

    test('sabqi pages respect the student\'s mushaf lines (16-line)', () {
      final stats = StudentMonthlyStats.compute(
        records: [
          rec('2026-08-02', sabqi: SabqiEntry(juz: 1, startPage: 2, endPage: 12, heardPage: 12)),
        ],
        linesPerPage: 16,
      );
      // Para 1 (16-line): pages 2–20 → 19 pages; heard page 12 → 11 done.
      expect(stats.sabqiTotalPages, 19);
      expect(stats.sabqiCompletedPages, 11);
    });

    test('sabaqPages sums the page ranges of recorded lessons', () {
      final stats = StudentMonthlyStats.compute(records: [
        rec('2026-08-01', sabaq: SabaqEntry(juz: 1, pageLabel: 'p1', lines: 3, startPage: 3, endPage: 7)),
        rec('2026-08-02', sabaq: SabaqEntry(juz: 1, pageLabel: 'p2', lines: 4, startPage: 8, endPage: 10)),
        rec('2026-08-03', sabaq: SabaqEntry(juz: 1, pageLabel: 'p3', lines: 2)),
      ]);
      expect(stats.sabaqLessons, 3);
      // 5 pages + 3 pages; the record without pages contributes 0.
      expect(stats.sabaqPages, 8);
    });

    test('grades: 26+ behtareen, 20+ behtar, 15+ acha, else kamzor (default thresholds)', () {
      String grade(int days) => StudentMonthlyStats.compute(
            records: [
              for (var i = 0; i < days; i++)
                rec('2026-08-${(i + 1).toString().padLeft(2, '0')}', sabaq: SabaqEntry(juz: 1, pageLabel: 'p', lines: 1)),
            ],
          ).sabaqGrade((k, {args}) => k);

      expect(grade(26), 'gradeExcellent');
      expect(grade(20), 'gradeGood');
      expect(grade(15), 'gradePassable');
      expect(grade(14), 'gradeWeak');
    });
  });

  group('SabaqEntry pages (v4 page-based port)', () {
    test('pages getter computes end - start + 1', () {
      final s = SabaqEntry(juz: 1, startPage: 3, endPage: 7, lines: 5);
      expect(s.pages, 5);
    });

    test('pages is 0 when not set or inverted', () {
      expect(SabaqEntry(juz: 1).pages, 0);
      expect(SabaqEntry(juz: 1, startPage: 7, endPage: 3).pages, 0);
    });

    test('JSON round-trip keeps start/end pages', () {
      final s = SabaqEntry(juz: 2, pageLabel: 'x', startPage: 23, endPage: 30);
      final restored = SabaqEntry.fromJson(s.toJson());
      expect(restored.startPage, 23);
      expect(restored.endPage, 30);
    });
  });
}
