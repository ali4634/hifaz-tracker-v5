import 'package:intl/intl.dart';

/// Date helpers used across the app.
class AppDateUtils {
  AppDateUtils._();

  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime fromKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static DateTime today() => DateTime.now();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Formats a date using the current locale ('en' or 'ur').
  static String format(DateTime d, String locale) {
    try {
      return DateFormat('d MMM yyyy', locale).format(d);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(d);
    }
  }

  static String formatMonthYear(DateTime d, String locale) {
    try {
      return DateFormat('MMMM yyyy', locale).format(d);
    } catch (_) {
      return DateFormat('MMMM yyyy').format(d);
    }
  }

  /// Returns today / yesterday / tomorrow labels or a plain date.
  static String relative(
    DateTime d,
    String locale, {
    required String todayLabel,
    required String yesterdayLabel,
    required String tomorrowLabel,
  }) {
    final today = dateOnly(DateTime.now());
    final day = dateOnly(d);
    if (day == today) return todayLabel;
    if (day == today.subtract(const Duration(days: 1))) return yesterdayLabel;
    if (day == today.add(const Duration(days: 1))) return tomorrowLabel;
    return format(d, locale);
  }

  static List<DateTime> daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return [
      for (var i = 0; i < last.day; i++)
        DateTime(first.year, first.month, i + 1),
    ];
  }

  /// Days (date-only) between [from] and [to] inclusive.
  static List<DateTime> range(DateTime from, DateTime to) {
    final start = dateOnly(from);
    final end = dateOnly(to);
    return [
      for (var i = 0; i <= end.difference(start).inDays; i++)
        start.add(Duration(days: i)),
    ];
  }

  static int daysBetween(DateTime a, DateTime b) =>
      dateOnly(b).difference(dateOnly(a)).inDays;

  /// Returns the month name for the given month number (1-12).
  static String monthName(int month, String locale) {
    try {
      final date = DateTime(2024, month, 1);
      return DateFormat('MMMM', locale).format(date);
    } catch (_) {
      final date = DateTime(2024, month, 1);
      return DateFormat('MMMM').format(date);
    }
  }
}
