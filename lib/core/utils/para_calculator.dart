/// ParaCalculator — exact page lookup for 15-line and 16-line Mushaf.
///
/// Ported from v4's `para_calculator.dart`. No estimates, no line-based math;
/// every value comes from the exact Para → [startPage, endPage] tables below.
class ParaCalculator {
  ParaCalculator._();

  // ──────────────────────────────────────────────────────────────────────────
  // 15-Line Mushaf — Exact Para → [startPage, endPage]
  // ──────────────────────────────────────────────────────────────────────────
  static const Map<int, List<int>> _table15Line = {
    1: [3, 22],
    2: [23, 42],
    3: [43, 62],
    4: [63, 82],
    5: [83, 102],
    6: [103, 122],
    7: [123, 142],
    8: [143, 162],
    9: [163, 182],
    10: [183, 202],
    11: [203, 222],
    12: [223, 242],
    13: [243, 262],
    14: [263, 282],
    15: [283, 302],
    16: [303, 322],
    17: [323, 342],
    18: [343, 362],
    19: [363, 382],
    20: [383, 402],
    21: [403, 422],
    22: [423, 442],
    23: [443, 462],
    24: [463, 482],
    25: [483, 502],
    26: [503, 522],
    27: [523, 542],
    28: [543, 562],
    29: [563, 586],
    30: [587, 611],
  };

  // ──────────────────────────────────────────────────────────────────────────
  // 16-Line Mushaf — Exact Para → [startPage, endPage]
  // ──────────────────────────────────────────────────────────────────────────
  static const Map<int, List<int>> _table16Line = {
    1: [2, 20],
    2: [21, 38],
    3: [39, 56],
    4: [57, 74],
    5: [75, 92],
    6: [93, 110],
    7: [111, 128],
    8: [129, 146],
    9: [147, 164],
    10: [165, 182],
    11: [183, 200],
    12: [201, 218],
    13: [219, 236],
    14: [237, 254],
    15: [255, 272],
    16: [273, 290],
    17: [291, 308],
    18: [309, 326],
    19: [327, 344],
    20: [345, 362],
    21: [363, 380],
    22: [381, 398],
    23: [399, 416],
    24: [417, 434],
    25: [435, 452],
    26: [453, 470],
    27: [471, 488],
    28: [489, 508],
    29: [509, 528],
    30: [529, 549],
  };

  static Map<int, List<int>> _table(int mushafLines) =>
      mushafLines == 16 ? _table16Line : _table15Line;

  static void _checkPara(int paraNumber) {
    if (paraNumber < 1 || paraNumber > 30) {
      throw ArgumentError('Para must be 1–30, got $paraNumber');
    }
  }

  /// Start page for a given Para number.
  static int getStartPageForPara(int paraNumber, {int linesPerPage = 15}) {
    _checkPara(paraNumber);
    return _table(linesPerPage)[paraNumber]![0];
  }

  /// End page for a given Para number.
  static int getEndPageForPara(int paraNumber, {int linesPerPage = 15}) {
    _checkPara(paraNumber);
    return _table(linesPerPage)[paraNumber]![1];
  }

  /// Total pages in a given Para (endPage - startPage + 1).
  static int getTotalPagesForPara(int paraNumber, {int linesPerPage = 15}) {
    final start = getStartPageForPara(paraNumber, linesPerPage: linesPerPage);
    final end = getEndPageForPara(paraNumber, linesPerPage: linesPerPage);
    return end - start + 1;
  }

  /// End page for a specific Ruba (1-4) in a Para.
  static int getEndPageForRuba(
    int paraNumber,
    int ruba, {
    int linesPerPage = 15,
  }) {
    final start = getStartPageForPara(paraNumber, linesPerPage: linesPerPage);
    final total = getTotalPagesForPara(paraNumber, linesPerPage: linesPerPage);
    final perRuba = total / 4.0;
    return (start + (perRuba * ruba) - 1).round();
  }

  /// Simple page count from any start→end range.
  static int calcPages(int startPage, int endPage) {
    if (endPage < startPage) return 0;
    return endPage - startPage + 1;
  }

  /// Which Para does this page belong to?
  static int getParaFromPage(int pageNumber, {int linesPerPage = 15}) {
    for (final entry in _table(linesPerPage).entries) {
      if (pageNumber >= entry.value[0] && pageNumber <= entry.value[1]) {
        return entry.key;
      }
    }
    throw ArgumentError(
      'Page $pageNumber is out of range for $linesPerPage-line Mushaf',
    );
  }

  /// Whether [startPage]..[endPage] is a valid range inside [paraNumber].
  static bool isValidPageRange(
    int startPage,
    int endPage,
    int paraNumber, {
    int linesPerPage = 15,
  }) {
    final expectedStart = getStartPageForPara(
      paraNumber,
      linesPerPage: linesPerPage,
    );
    final expectedEnd = getEndPageForPara(
      paraNumber,
      linesPerPage: linesPerPage,
    );
    return startPage >= expectedStart && endPage <= expectedEnd;
  }

  /// Human-readable Para info — "Para 5 (pages 83–102)".
  static String formatParaInfo(int paraNumber, {int linesPerPage = 15}) {
    final start = getStartPageForPara(paraNumber, linesPerPage: linesPerPage);
    final end = getEndPageForPara(paraNumber, linesPerPage: linesPerPage);
    return 'Para $paraNumber (pages $start–$end)';
  }

  /// Maximum page number for this Mushaf type.
  static int maxPage({int linesPerPage = 15}) =>
      getEndPageForPara(30, linesPerPage: linesPerPage);
}
