import '../constants.dart';
import 'para_calculator.dart';

/// A position in the Manzil (old lesson review) cycle: Juz + Ruba (quarter).
class ManzilPosition {
  final int juz;
  final int ruba;

  const ManzilPosition(this.juz, this.ruba);

  static const ManzilPosition none = ManzilPosition(0, 0);

  bool get isSet =>
      juz >= 1 && juz <= AppConstants.maxJuz && ruba >= 1 && ruba <= 4;

  String get key => '$juz-$ruba';

  @override
  bool operator ==(Object other) =>
      other is ManzilPosition && other.juz == juz && other.ruba == ruba;

  @override
  int get hashCode => Object.hash(juz, ruba);

  @override
  String toString() => 'Juz $juz · Ruba $ruba';
}

/// Pure business logic: Sabqi page math, Manzil cycle & suggestion rules.
class MathEngine {
  MathEngine._();

  /// Total number of Rubas in one full Manzil pass from [startJuz] to [endJuz].
  static int manzilTotalRubas(int startJuz, int endJuz) =>
      ((endJuz - startJuz).abs() + 1) * 4;

  /// Zero-based index of [pos] within the current cycle (0 = first Ruba).
  static int manzilIndexInCycle(
    ManzilPosition pos,
    int startJuz, {
    required bool reverse,
  }) {
    if (!reverse) return (pos.juz - startJuz) * 4 + (pos.ruba - 1);
    return (startJuz - pos.juz) * 4 + (pos.ruba - 1);
  }

  /// The next lesson after logging [pos] (Ruba 4 advances the Juz; the end of
  /// the target range wraps back to the start Juz → a new cycle begins).
  static ManzilPosition nextManzilPosition(
    ManzilPosition pos,
    int startJuz,
    int endJuz, {
    required bool reverse,
  }) {
    if (pos.ruba < 4) return ManzilPosition(pos.juz, pos.ruba + 1);
    if (reverse) {
      // Reverse order: Juz 30 → 29 → … → endJuz, then wrap to startJuz.
      if (pos.juz > endJuz) return ManzilPosition(pos.juz - 1, 1);
      return ManzilPosition(startJuz, 1);
    }
    // Straight order: Juz 1 → 2 → … → endJuz, then wrap to startJuz.
    if (pos.juz < endJuz) return ManzilPosition(pos.juz + 1, 1);
    return ManzilPosition(startJuz, 1);
  }

  /// Whether logging [pos] completes a full cycle (wrap-around).
  static bool completesCycle(ManzilPosition pos, int endJuz) =>
      pos.ruba == 4 && pos.juz == endJuz;

  /// A suggestion for the next Manzil lesson is the position *after* the last
  /// logged one. When nothing has been logged yet, returns the start position.
  static ManzilPosition suggestNextManzil({
    required bool hasLog,
    required ManzilPosition? lastLogged,
    required int startJuz,
    required int endJuz,
    required bool reverse,
  }) {
    if (!hasLog || lastLogged == null || !lastLogged.isSet) {
      return ManzilPosition(startJuz, 1);
    }
    return nextManzilPosition(lastLogged, startJuz, endJuz, reverse: reverse);
  }

  // ── Sabqi / Tahreer math ─────────────────────────────────────────────────

  /// Result of the Sabqi page calculation.
  ///
  /// - totalPages       = (endPage - startPage) + 1
  /// - completedPages   = (heardPage - startPage) + 1  (clamped to [0, total])
  /// - remainingPages   = totalPages - completedPages
  /// - progress         = completed / total * 100 (0–100)
  static SabqiCalc computeSabqi({
    required int startPage,
    required int endPage,
    required int heardPage,
  }) {
    if (endPage < startPage) {
      // Invalid range → zero everything so callers can show validation.
      return SabqiCalc(
        totalPages: 0,
        completedPages: 0,
        remainingPages: 0,
        progress: 0,
        valid: false,
      );
    }
    final totalPages = endPage - startPage + 1;
    final completedPages = ((heardPage - startPage) + 1).clamp(0, totalPages);
    final remainingPages = totalPages - completedPages;
    final progress = ((completedPages / totalPages) * 100).round();
    final overLimit = totalPages > AppConstants.maxPagesPerPara;
    return SabqiCalc(
      totalPages: totalPages,
      completedPages: completedPages,
      remainingPages: remainingPages,
      progress: progress,
      valid: !overLimit,
      overPageLimit: overLimit,
    );
  }

  /// Para-based Sabqi progress (mushaf-lines aware): how far into the whole
  /// [juz] the student has been heard, using the exact 15/16-line page tables.
  ///
  /// [endPage] is the last page the student recited up to (heard page). Falls
  /// back to the range-based totals when [juz] is out of range.
  static SabqiCalc computeParaSabqi({
    required int juz,
    required int startPage,
    required int endPage,
    required int heardPage,
    required int linesPerPage,
  }) {
    if (endPage < startPage) {
      // Inverted range → zero everything so callers can show validation.
      return SabqiCalc(
        totalPages: 0,
        completedPages: 0,
        remainingPages: 0,
        progress: 0,
        valid: false,
      );
    }
    if (juz < 1 || juz > AppConstants.maxJuz) {
      return computeSabqi(
        startPage: startPage,
        endPage: endPage,
        heardPage: heardPage,
      );
    }
    final paraStart = ParaCalculator.getStartPageForPara(
      juz,
      linesPerPage: linesPerPage,
    );
    final total = ParaCalculator.getTotalPagesForPara(
      juz,
      linesPerPage: linesPerPage,
    );
    final completed = ((heardPage - paraStart) + 1).clamp(0, total);
    final remaining = total - completed;
    final progress = ((completed / total) * 100).round();
    return SabqiCalc(
      totalPages: total,
      completedPages: completed,
      remainingPages: remaining,
      progress: progress,
      valid: true,
    );
  }
}

/// Immutable result of the Sabqi calculation.
class SabqiCalc {
  final int totalPages;
  final int completedPages;
  final int remainingPages;
  final int progress;
  final bool valid;
  final bool overPageLimit;

  const SabqiCalc({
    required this.totalPages,
    required this.completedPages,
    required this.remainingPages,
    required this.progress,
    this.valid = true,
    this.overPageLimit = false,
  });
}
