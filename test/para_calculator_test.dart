import 'package:flutter_test/flutter_test.dart';

import 'package:huffa_tracker_5/core/utils/math_engine.dart';
import 'package:huffa_tracker_5/core/utils/para_calculator.dart';
import 'package:huffa_tracker_5/models/student.dart';

void main() {
  group('ParaCalculator · 15-line mushaf', () {
    test('exact page ranges', () {
      expect(ParaCalculator.getStartPageForPara(1), 3);
      expect(ParaCalculator.getEndPageForPara(1), 22);
      expect(ParaCalculator.getStartPageForPara(30), 587);
      expect(ParaCalculator.getEndPageForPara(30), 611);
    });

    test('total pages', () {
      expect(ParaCalculator.getTotalPagesForPara(1), 20);
      expect(ParaCalculator.getTotalPagesForPara(30), 25);
      expect(ParaCalculator.maxPage(), 611);
    });

    test('ruba end page falls inside the para', () {
      final p = ParaCalculator.getEndPageForRuba(1, 4);
      expect(p, lessThanOrEqualTo(22));
      expect(p, greaterThanOrEqualTo(3));
    });

    test('page → para lookup', () {
      expect(ParaCalculator.getParaFromPage(3), 1);
      expect(ParaCalculator.getParaFromPage(102), 5);
      expect(ParaCalculator.getParaFromPage(611), 30);
    });

    test('invalid para throws', () {
      expect(() => ParaCalculator.getTotalPagesForPara(31), throwsArgumentError);
      expect(() => ParaCalculator.getTotalPagesForPara(0), throwsArgumentError);
    });
  });

  group('ParaCalculator · 16-line mushaf', () {
    test('exact page ranges differ from 15-line', () {
      expect(ParaCalculator.getStartPageForPara(1, linesPerPage: 16), 2);
      expect(ParaCalculator.getEndPageForPara(1, linesPerPage: 16), 20);
      expect(ParaCalculator.getStartPageForPara(30, linesPerPage: 16), 529);
      expect(ParaCalculator.getEndPageForPara(30, linesPerPage: 16), 549);
      expect(ParaCalculator.maxPage(linesPerPage: 16), 549);
    });

    test('total pages', () {
      expect(ParaCalculator.getTotalPagesForPara(1, linesPerPage: 16), 19);
      expect(ParaCalculator.getTotalPagesForPara(30, linesPerPage: 16), 21);
    });
  });

  group('MathEngine · computeParaSabqi', () {
    test('progress within the whole para for 15-line mushaf', () {
      // Para 1: pages 3–22 (20 pages). Heard up to page 12 → 10 pages done.
      final c = MathEngine.computeParaSabqi(
        juz: 1,
        startPage: 3,
        endPage: 12,
        heardPage: 12,
        linesPerPage: 15,
      );
      expect(c.totalPages, 20);
      expect(c.completedPages, 10);
      expect(c.remainingPages, 10);
      expect(c.progress, 50);
    });

    test('para 30 allows 25 pages on a 15-line mushaf', () {
      final c = MathEngine.computeParaSabqi(
        juz: 30,
        startPage: 587,
        endPage: 611,
        heardPage: 611,
        linesPerPage: 15,
      );
      expect(c.totalPages, 25);
      expect(c.completedPages, 25);
      expect(c.progress, 100);
    });

    test('16-line mushaf gives a smaller para total', () {
      final c = MathEngine.computeParaSabqi(
        juz: 30,
        startPage: 529,
        endPage: 549,
        heardPage: 549,
        linesPerPage: 16,
      );
      expect(c.totalPages, 21);
      expect(c.progress, 100);
    });

    test('out-of-range juz falls back to range-based totals', () {
      final c = MathEngine.computeParaSabqi(
        juz: 31,
        startPage: 1,
        endPage: 5,
        heardPage: 3,
        linesPerPage: 15,
      );
      expect(c.totalPages, 5);
      expect(c.completedPages, 3);
    });

    test('inverted range is flagged invalid', () {
      final c = MathEngine.computeParaSabqi(
        juz: 1,
        startPage: 12,
        endPage: 3,
        heardPage: 5,
        linesPerPage: 15,
      );
      expect(c.valid, isFalse);
      expect(c.totalPages, 0);
    });
  });

  group('Student · mushafLines field', () {
    test('defaults to 15 and round-trips through JSON', () {
      final s = Student(id: 's1', name: 'Ali', section: 'A');
      expect(s.mushafLines, 15);

      final json = s.toJson();
      expect(json['mushafLines'], 15);

      final restored = Student.fromJson(json);
      expect(restored.mushafLines, 15);
    });

    test('16-line value persists', () {
      final s = Student(id: 's1', name: 'Ali', section: 'A', mushafLines: 16);
      expect(Student.fromJson(s.toJson()).mushafLines, 16);
    });
  });
}
