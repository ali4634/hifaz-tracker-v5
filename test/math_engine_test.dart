import 'package:flutter_test/flutter_test.dart';

import 'package:huffa_tracker_5/core/utils/math_engine.dart';
import 'package:huffa_tracker_5/core/utils/warning_engine.dart';
import 'package:huffa_tracker_5/models/daily_record.dart';
import 'package:huffa_tracker_5/models/student.dart';

void main() {
  group('MathEngine · Manzil cycle', () {
    test('straight order advances Juz after Ruba 4', () {
      final next = MathEngine.nextManzilPosition(
        const ManzilPosition(1, 4),
        1,
        30,
        reverse: false,
      );
      expect(next, const ManzilPosition(2, 1));
    });

    test('straight order wraps 30/4 back to 1/1', () {
      final next = MathEngine.nextManzilPosition(
        const ManzilPosition(30, 4),
        1,
        30,
        reverse: false,
      );
      expect(next, const ManzilPosition(1, 1));
      expect(MathEngine.completesCycle(const ManzilPosition(30, 4), 30), isTrue);
    });

    test('reverse order decrements Juz (30 → 29)', () {
      final next = MathEngine.nextManzilPosition(
        const ManzilPosition(30, 4),
        30,
        25,
        reverse: true,
      );
      expect(next, const ManzilPosition(29, 1));
    });

    test('reverse order wraps 25/4 back to 30/1', () {
      final next = MathEngine.nextManzilPosition(
        const ManzilPosition(25, 4),
        30,
        25,
        reverse: true,
      );
      expect(next, const ManzilPosition(30, 1));
    });

    test('suggestion returns start position when nothing logged', () {
      final s = MathEngine.suggestNextManzil(
        hasLog: false,
        lastLogged: null,
        startJuz: 3,
        endJuz: 30,
        reverse: false,
      );
      expect(s, const ManzilPosition(3, 1));
    });

    test('manzilIndexInCycle is 0 at start and grows per Ruba', () {
      expect(
        MathEngine.manzilIndexInCycle(const ManzilPosition(1, 1), 1, reverse: false),
        0,
      );
      expect(
        MathEngine.manzilIndexInCycle(const ManzilPosition(1, 3), 1, reverse: false),
        2,
      );
      expect(
        MathEngine.manzilIndexInCycle(const ManzilPosition(29, 1), 30, reverse: true),
        4,
      );
    });

    test('total rubas for Juz 1→30 is 120', () {
      expect(MathEngine.manzilTotalRubas(1, 30), 120);
      expect(MathEngine.manzilTotalRubas(30, 25), 24);
    });
  });

  group('MathEngine · Sabqi pages', () {
    test('basic calculation', () {
      final c = MathEngine.computeSabqi(startPage: 1, endPage: 5, heardPage: 3);
      expect(c.totalPages, 5);
      expect(c.completedPages, 3);
      expect(c.remainingPages, 2);
      expect(c.progress, 60);
      expect(c.valid, isTrue);
    });

    test('completed pages are clamped to total', () {
      final c = MathEngine.computeSabqi(startPage: 1, endPage: 5, heardPage: 99);
      expect(c.completedPages, 5);
      expect(c.remainingPages, 0);
      expect(c.progress, 100);
    });

    test('heard before start clamps to 0', () {
      final c = MathEngine.computeSabqi(startPage: 4, endPage: 6, heardPage: 2);
      expect(c.completedPages, 0);
      expect(c.remainingPages, 3);
      expect(c.progress, 0);
    });

    test('invalid range is flagged invalid', () {
      final c = MathEngine.computeSabqi(startPage: 8, endPage: 3, heardPage: 5);
      expect(c.valid, isFalse);
    });

    test('over 20 pages per para is invalid', () {
      final c = MathEngine.computeSabqi(startPage: 1, endPage: 21, heardPage: 5);
      expect(c.valid, isFalse);
      expect(c.overPageLimit, isTrue);
    });
  });

  group('WarningEngine', () {
    Student student({List<String> ack = const []}) => Student(
          id: 's1',
          name: 'Ali',
          section: 'A',
          acknowledgedWarnings: ack,
        );

    DailyRecord rec(String date, {bool present = true, ManzilEntry? manzil}) =>
        DailyRecord(
          id: 'r_$date',
          studentId: 's1',
          date: date,
          present: present,
          manzil: manzil,
        );

    test('inactivity: 3 present days with no lesson', () {
      final warnings = WarningEngine.detect(
        student: student(),
        allRecords: [
          rec('2026-08-03'),
          rec('2026-08-04'),
          rec('2026-08-05'),
        ],
        inactiveThreshold: 3,
        repetitionThreshold: 3,
        absenceWindowDays: 10,
        absenceThreshold: 3,
      );
      expect(warnings.any((w) => w.type == 'inactivity' && w.count == 3), isTrue);
    });

    test('inactivity suppressed when lessons exist', () {
      final warnings = WarningEngine.detect(
        student: student(),
        allRecords: [
          rec('2026-08-03', manzil: ManzilEntry(juz: 1, ruba: 1)),
          rec('2026-08-04', manzil: ManzilEntry(juz: 1, ruba: 2)),
          rec('2026-08-05', manzil: ManzilEntry(juz: 1, ruba: 3)),
        ],
        inactiveThreshold: 3,
        repetitionThreshold: 3,
        absenceWindowDays: 10,
        absenceThreshold: 3,
      );
      expect(warnings, isEmpty);
    });

    test('repetition: same lesson 3 days in a row', () {
      final warnings = WarningEngine.detect(
        student: student(),
        allRecords: [
          rec('2026-08-03', manzil: ManzilEntry(juz: 2, ruba: 1)),
          rec('2026-08-04', manzil: ManzilEntry(juz: 2, ruba: 1)),
          rec('2026-08-05', manzil: ManzilEntry(juz: 2, ruba: 1)),
        ],
        inactiveThreshold: 3,
        repetitionThreshold: 3,
        absenceWindowDays: 10,
        absenceThreshold: 3,
      );
      expect(warnings.any((w) => w.type == 'repetition' && w.count == 3), isTrue);
    });

    test('absence: 3 absences in the last 10 days', () {
      final today = DateTime.now();
      String d(int offset) {
        final day = today.subtract(Duration(days: offset));
        return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      }

      final warnings = WarningEngine.detect(
        student: student(),
        allRecords: [
          rec(d(1), present: false),
          rec(d(3), present: false),
          rec(d(5), present: false),
        ],
        inactiveThreshold: 3,
        repetitionThreshold: 3,
        absenceWindowDays: 10,
        absenceThreshold: 3,
      );
      expect(warnings.any((w) => w.type == 'absence' && w.count == 3), isTrue);
    });

    test('acknowledged warnings are suppressed', () {
      final s = student(ack: ['inactivity|2026-08-05']);
      final warnings = WarningEngine.detect(
        student: s,
        allRecords: [
          rec('2026-08-03'),
          rec('2026-08-04'),
          rec('2026-08-05'),
        ],
        inactiveThreshold: 3,
        repetitionThreshold: 3,
        absenceWindowDays: 10,
        absenceThreshold: 3,
      );
      expect(warnings.where((w) => w.type == 'inactivity'), isEmpty);
    });
  });
}
