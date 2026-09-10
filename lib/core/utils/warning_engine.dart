import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../utils/app_date_utils.dart';
import '../utils/math_engine.dart';
import '../../models/student.dart';
import '../../models/daily_record.dart';

/// A detected negligence warning for a student.
@immutable
class WarningInfo {
  /// One of [AppConstants.warnInactivity], [warnRepetition], [warnAbsence].
  final String type;
  final String studentId;

  /// The date the warning triggers (end of the consecutive run / today).
  final DateTime triggerDate;
  final int count;

  const WarningInfo({
    required this.type,
    required this.studentId,
    required this.triggerDate,
    required this.count,
  });

  /// Stable identifier used for acknowledgement tracking.
  String get id => '$type|${AppDateUtils.key(triggerDate)}';

  @override
  bool operator ==(Object other) => other is WarningInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    'type': type,
    'studentId': studentId,
    'triggerDate': AppDateUtils.key(triggerDate),
    'count': count,
  };
}

/// Stateless negligence & warning detection engine.
///
/// Rules (all relative to the *trailing* state of the student's records):
/// 1. Inactivity  – N consecutive present days with no lesson logged.
/// 2. Repetition  – the exact same lesson logged N consecutive present days.
/// 3. Absence     – at least N absences inside the rolling window (last W days).
class WarningEngine {
  WarningEngine._();

  /// Detects all active warnings for [student]. A warning whose id is already
  /// present in [student].acknowledgedWarnings is suppressed.
  static List<WarningInfo> detect({
    required Student student,
    required List<DailyRecord> allRecords,
    required int inactiveThreshold,
    required int repetitionThreshold,
    required int absenceWindowDays,
    required int absenceThreshold,
  }) {
    final records = allRecords.where((r) => r.studentId == student.id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final warnings = <WarningInfo>[];

    if (records.isNotEmpty) {
      // ── trailing consecutive runs over present days ──────────────────────
      int noLessonRun = 0;
      int repeatRun = 0;
      String? lastSignature;
      for (final r in records) {
        if (!r.present) {
          noLessonRun = 0;
          repeatRun = 0;
          lastSignature = null;
          continue;
        }
        final sig = r.lessonSignature;
        if (sig == null || sig.isEmpty) {
          noLessonRun += 1;
          repeatRun = 0;
          lastSignature = null;
        } else {
          noLessonRun = 0;
          repeatRun = (sig == lastSignature) ? repeatRun + 1 : 1;
          lastSignature = sig;
        }
      }

      final trigger = AppDateUtils.fromKey(records.last.date);

      if (noLessonRun >= inactiveThreshold) {
        warnings.add(
          WarningInfo(
            type: AppConstants.warnInactivity,
            studentId: student.id,
            triggerDate: trigger,
            count: noLessonRun,
          ),
        );
      }

      if (repeatRun >= repetitionThreshold) {
        warnings.add(
          WarningInfo(
            type: AppConstants.warnRepetition,
            studentId: student.id,
            triggerDate: trigger,
            count: repeatRun,
          ),
        );
      }

      // ── rolling-window absence check ─────────────────────────────────────
      final today = AppDateUtils.today();
      final windowStart = today.subtract(Duration(days: absenceWindowDays - 1));
      final todayKey = AppDateUtils.key(today);
      final startKey = AppDateUtils.key(windowStart);
      final absences = records.where((r) {
        return !r.present &&
            r.date.compareTo(startKey) >= 0 &&
            r.date.compareTo(todayKey) <= 0;
      }).length;

      if (absences >= absenceThreshold) {
        warnings.add(
          WarningInfo(
            type: AppConstants.warnAbsence,
            studentId: student.id,
            triggerDate: today,
            count: absences,
          ),
        );
      }

      // ── skipped Sabqi pages ───────────────────────────────────────────────
      // The most recent Sabqi log left more than `skippedPagesRatio` of the
      // assigned range unread → the student is skipping pages.
      DailyRecord? latestSabqi;
      for (final r in records.reversed) {
        if (r.sabqi != null) {
          latestSabqi = r;
          break;
        }
      }
      final sabqi = latestSabqi?.sabqi;
      if (sabqi != null) {
        final calc = MathEngine.computeSabqi(
          startPage: sabqi.startPage,
          endPage: sabqi.endPage,
          heardPage: sabqi.heardPage,
        );
        if (calc.totalPages > 0 &&
            calc.remainingPages >
                (calc.totalPages * AppConstants.skippedPagesRatio)) {
          warnings.add(
            WarningInfo(
              type: AppConstants.warnSkippedPages,
              studentId: student.id,
              triggerDate: AppDateUtils.fromKey(latestSabqi!.date),
              count: calc.remainingPages,
            ),
          );
        }
      }

      // ── Manzil skip detection ──────────────────────────────────────────────
      // If consecutive Manzil records skip rubas (jump forward by more than
      // 1 ruba) or go backwards, raise a warning so the teacher knows the
      // student skipped parts of the Manzil.
      final manzilRecords = records
          .where((r) => r.manzil != null)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (manzilRecords.length >= 2) {
        for (var i = 1; i < manzilRecords.length; i++) {
          final prev = manzilRecords[i - 1].manzil!;
          final curr = manzilRecords[i].manzil!;

          // Convert (juz, ruba) to a linear ruba position within the
          // student's Manzil range so we can compute the gap.
          final prevPos = _manzilPosition(prev.juz, prev.ruba, student);
          final currPos = _manzilPosition(curr.juz, curr.ruba, student);

          final gap = currPos - prevPos;

          // gap > 1 means skipped rubas forward; gap < 0 means went backwards.
          if (gap > 1 || gap < 0) {
            final skippedRubas = gap > 0 ? gap - 1 : (-gap);
            warnings.add(
              WarningInfo(
                type: AppConstants.warnManzilSkip,
                studentId: student.id,
                triggerDate: AppDateUtils.fromKey(manzilRecords[i].date),
                count: skippedRubas,
              ),
            );
            // Only report the most recent skip, not every historical one.
            break;
          }
        }
      }
    }

    final ack = student.acknowledgedWarnings.toSet();
    return warnings.where((w) => !ack.contains(w.id)).toList();
  }

  /// Converts a (juz, ruba) pair into a linear position within the student's
  /// Manzil range, counting rubas from the start. This lets us compute gaps
  /// between consecutive Manzil records.
  static int _manzilPosition(int juz, int ruba, Student student) {
    if (student.manzilReverse) {
      // Reverse: Juz 30 → 25, so position counts down.
      return (student.manzilEndJuz - juz) * 4 + ruba;
    } else {
      // Straight: Juz 1 → 30.
      return (juz - student.manzilStartJuz) * 4 + ruba;
    }
  }
}
