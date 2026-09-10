/// App-wide constants for the Hifaz Tracker.
class AppConstants {
  AppConstants._();

  static const String appName = 'Hifaz Tracker';
  static const String appVersion = '1.0.0';

  /// Supported sections (up to 3).
  static const List<String> sections = ['A', 'B', 'C'];

  static const int maxJuz = 30;
  static const List<int> juzNumbers = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
  ];
  static const List<int> rubas = [1, 2, 3, 4];

  /// Maximum allowed pages per Para (Sabqi validation rule).
  static const int maxPagesPerPara = 20;

  // ── Defaults ─────────────────────────────────────────────────────────────
  static const int defaultManzilStartJuz = 1;
  static const int defaultManzilEndJuz = 30;
  static const int defaultSabqiTargetJuz = 1;
  static const int defaultSabqiTargetPages = 10;
  static const int defaultRevisionStandard = 3;

  /// Mushaf lines per page used for para-based page calculation.
  static const int defaultMushafLines = 15;
  static const List<int> mushafLineOptions = [15, 16];
  static const int defaultNotificationHour = 17;
  static const int defaultNotificationMinute = 0;

  // ── Warning engine defaults ──────────────────────────────────────────────
  static const int warningInactiveDays = 3;
  static const int warningRepetitionCount = 3;
  static const int absenceWindowDays = 10;
  static const int absenceWarningCount = 3;

  /// Default threshold (days) without Sabaq/Sabqi/Manzil before a naagha
  /// (gap) alert fires.
  static const int defaultNaaghaDays = 3;

  // ── Performance grading defaults ───────────────────────────────────────
  /// Minimum count for 'Behtareen' (excellent) grade.
  static const int defaultGradingBehtareen = 26;

  /// Minimum count for 'Behtar' (good) grade.
  static const int defaultGradingBehtar = 20;

  /// Minimum count for 'Acha' (passable) grade.
  static const int defaultGradingAcha = 15;

  /// Minimum fraction of a Sabqi lesson that must remain unread before a
  /// "skipped pages" warning is raised (30% like v4).
  static const double skippedPagesRatio = 0.3;

  /// Notification id for the daily Sabqi reminder.
  static const int dailyReminderNotificationId = 1001;

  /// Base id for per-student naagha (gap) reminders (add a stable index).
  static const int naaghaNotificationBaseId = 2001;

  /// Hive box holding which naagha alerts the teacher has already viewed.
  static const String naaghaSeenBoxName = 'naagha_seen';

  /// Hive box names.
  static const String studentsBoxName = 'students';
  static const String recordsBoxName = 'records';
  static const String settingsBoxName = 'settings';
  static const String feesBoxName = 'fees';

  /// Warning types.
  static const String warnInactivity = 'inactivity';
  static const String warnRepetition = 'repetition';
  static const String warnAbsence = 'absence';
  static const String warnSkippedPages = 'skippedPages';
  static const String warnManzilSkip = 'manzilSkip';
}
