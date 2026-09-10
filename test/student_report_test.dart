import 'package:flutter_test/flutter_test.dart';

import 'package:huffa_tracker_5/models/app_settings.dart';
import 'package:huffa_tracker_5/models/daily_record.dart';
import 'package:huffa_tracker_5/models/student.dart';
import 'package:huffa_tracker_5/services/export_service.dart';

/// Regression tests for the per-student (infiradi) monthly report:
/// the text report must render cleanly (no Closure garbage) and the PDF
/// must build without throwing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Student student() => Student(
    id: 's1',
    name: 'Ahmad',
    section: 'A',
    phone: '+92 300 1234567',
    mushafLines: 15,
  );

  List<DailyRecord> records() => [
    DailyRecord(
      id: 'r1',
      studentId: 's1',
      date: '2026-08-03',
      present: true,
      sabaq: SabaqEntry(juz: 1, pageLabel: '5', lines: 10, startPage: 5, endPage: 6),
      sabqi: SabqiEntry(juz: 2, startPage: 10, endPage: 14, heardPage: 12),
      manzil: ManzilEntry(juz: 3, ruba: 2),
    ),
    DailyRecord(
      id: 'r2',
      studentId: 's1',
      date: '2026-08-04',
      present: true,
      sabqi: SabqiEntry(juz: 2, startPage: 10, endPage: 14, heardPage: 13),
    ),
    DailyRecord(
      id: 'r3',
      studentId: 's1',
      date: '2026-08-05',
      present: false,
    ),
  ];

  String t(String key, {List<String>? args}) {
    const en = {
      'appName': 'Hifaz Tracker',
      'studentMonthlyReport': 'Monthly report · {0}',
      'section': 'Section',
      'presentDays': 'Present days',
      'absentDays': 'Absent days',
      'sabaqTotal': 'Sabaq',
      'sabqiTotal': 'Sabqi',
      'manzilTotal': 'Manzil',
      'lessonsCount': 'lessons',
      'pagesCount': 'pages',
      'rubasCount': 'rubas',
      'grade': 'Grade',
      'gradeExcellent': 'Behtareen',
      'gradeGood': 'Behtar',
      'gradePassable': 'Acha',
      'gradeWeak': 'Kamzor',
      'missedSabaq': 'Missed sabaq',
      'missedSabqi': 'Missed sabqi',
      'missedManzil': 'Missed manzil',
      'noRecords': 'No records',
      'dailyRecords': 'Daily records',
      'sabaq': 'Sabaq',
      'sabqi': 'Sabqi',
      'manzil': 'Manzil',
      'juz': 'Juz',
      'ruba': 'Ruba',
      'present': 'Present',
      'absent': 'Absent',
      'noLesson': 'No lesson',
    };
    var v = en[key] ?? key;
    if (args != null) {
      for (var i = 0; i < args.length; i++) {
        v = v.replaceAll('{$i}', args[i]);
      }
    }
    return v;
  }

  group('StudentMonthlyTextReport (infiradi text report)', () {
    test('contains khulasa totals and clean grade labels (no Closure text)', () {
      final text = ExportService.instance.buildStudentMonthlyTextReport(
        student: student(),
        month: DateTime(2026, 8),
        records: records(),
        t: t,
        locale: 'en',
      );
      expect(text, contains('Ahmad'));
      expect(text, contains('Present days: 2 | Absent days: 1'));
      expect(text, isNot(contains('Closure')));
      expect(text, isNot(contains('ReportStrings')));
      expect(text, contains('Grade'));
      expect(text, contains('Sabaq: 1 lessons - 2 pages - Grade: Kamzor'));
      expect(text, contains('Missed sabaq: 2'));
    });

    test('handles an empty month without throwing', () {
      final text = ExportService.instance.buildStudentMonthlyTextReport(
        student: student(),
        month: DateTime(2026, 9),
        records: records(),
        t: t,
        locale: 'en',
      );
      expect(text, contains('No records'));
    });
  });

  group('StudentMonthlyPdfReport (infiradi PDF)', () {
    test('generates a non-empty PDF without throwing', () async {
      final bytes = await ExportService.instance.buildStudentMonthlyPdfReport(
        student: student(),
        month: DateTime(2026, 8),
        records: records(),
        settings: AppSettings.defaults(),
        t: t,
        locale: 'en',
      );
      expect(bytes, isNotEmpty);
      // PDF magic header: %PDF
      expect(bytes, isNotEmpty);
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, '%PDF');
    });

    test('generates a valid empty-state PDF when no records exist', () async {
      final bytes = await ExportService.instance.buildStudentMonthlyPdfReport(
        student: student(),
        month: DateTime(2026, 9),
        records: records(),
        settings: AppSettings.defaults(),
        t: t,
        locale: 'en',
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });
}
