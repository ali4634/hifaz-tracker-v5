import '../core/constants.dart';
import '../core/utils/app_date_utils.dart';
import '../models/daily_record.dart';
import '../models/student.dart';
import 'notification_service.dart';

/// The three lesson tracks that can have a gap (naagha).
enum NaaghaTrack { sabaq, sabqi, manzil }

/// A student who hasn't recited a given track for [daysWithout] days.
class NaaghaAlert {
  final Student student;
  final NaaghaTrack track;
  final int daysWithout;

  const NaaghaAlert({
    required this.student,
    required this.track,
    required this.daysWithout,
  });

  /// Stable key used to remember that this exact alert (student + track) has
  /// already been viewed, so the bell badge can stay clean until the gap
  /// re-appears after being resolved.
  String get seenKey => '${student.id}|${track.name}';
}

/// Detects students who made a gap (naagha) in Sabaq, Sabqi or Manzil and
/// schedules daily reminders for them.
///
/// A gap is measured in calendar days: for each track we count how many
/// consecutive days backwards from today have no record containing that
/// track. A student with no record at all for a track is treated as having
/// a gap since their creation date.
class NaaghaService {
  NaaghaService._();

  /// Students with at least [thresholdDays] consecutive days (backwards from
  /// today) without a record for each track that breaches the threshold.
  static List<NaaghaAlert> detect({
    required List<Student> students,
    required List<DailyRecord> records,
    required int thresholdDays,
  }) {
    if (thresholdDays < 1) return const [];
    final alerts = <NaaghaAlert>[];
    final today = AppDateUtils.today();

    for (final student in students) {
      // Latest record date per track (kept as 'yyyy-MM-dd' string keys so
      // string comparison works for ordering).
      String? lastSabaq;
      String? lastSabqi;
      String? lastManzil;

      for (final r in records) {
        if (r.studentId != student.id) continue;
        if (r.sabaq != null &&
            (lastSabaq == null || r.date.compareTo(lastSabaq) > 0)) {
          lastSabaq = r.date;
        }
        if (r.sabqi != null &&
            (lastSabqi == null || r.date.compareTo(lastSabqi) > 0)) {
          lastSabqi = r.date;
        }
        if (r.manzil != null &&
            (lastManzil == null || r.date.compareTo(lastManzil) > 0)) {
          lastManzil = r.date;
        }
      }

      // Students who never logged a track at all are measured from the day
      // they were added, so brand-new students don't fire spurious alerts.
      final baseline = _baselineKey(student);

      final sabaqDays = _daysSince(lastSabaq ?? baseline, today);
      final sabqiDays = _daysSince(lastSabqi ?? baseline, today);
      final manzilDays = _daysSince(lastManzil ?? baseline, today);

      if (sabaqDays >= thresholdDays) {
        alerts.add(
          NaaghaAlert(
            student: student,
            track: NaaghaTrack.sabaq,
            daysWithout: sabaqDays,
          ),
        );
      }
      if (sabqiDays >= thresholdDays) {
        alerts.add(
          NaaghaAlert(
            student: student,
            track: NaaghaTrack.sabqi,
            daysWithout: sabqiDays,
          ),
        );
      }
      if (manzilDays >= thresholdDays) {
        alerts.add(
          NaaghaAlert(
            student: student,
            track: NaaghaTrack.manzil,
            daysWithout: manzilDays,
          ),
        );
      }
    }
    return alerts;
  }

  static String _baselineKey(Student student) {
    final created = DateTime.tryParse(student.createdAt);
    return AppDateUtils.key(
      created == null ? AppDateUtils.today() : AppDateUtils.dateOnly(created),
    );
  }

  static int _daysSince(String dateKey, DateTime today) {
    final date = AppDateUtils.fromKey(dateKey);
    return AppDateUtils.daysBetween(date, today);
  }

  /// Schedules a daily repeating notification for each student that has at
  /// least one gap. All previously scheduled per-student alerts are cancelled
  /// first to avoid stale reminders.
  static Future<void> scheduleNotifications({
    required List<NaaghaAlert> alerts,
    required int hour,
    required int minute,
    required String title,
    required String Function(Student student, List<NaaghaAlert> alerts)
    bodyBuilder,
  }) async {
    final svc = NotificationService.instance;
    await svc.cancelStudentReminders();

    // Group alerts by student so each student gets a single reminder listing
    // all their gaps.
    final byStudent = <String, List<NaaghaAlert>>{};
    for (final alert in alerts) {
      byStudent.putIfAbsent(alert.student.id, () => []).add(alert);
    }

    var i = 0;
    for (final entry in byStudent.entries) {
      await svc.scheduleStudentReminder(
        id: AppConstants.naaghaNotificationBaseId + i,
        hour: hour,
        minute: minute,
        title: title,
        body: bodyBuilder(entry.value.first.student, entry.value),
      );
      i++;
    }
  }
}
