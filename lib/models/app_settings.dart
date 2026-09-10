import 'package:hive_flutter/hive_flutter.dart';

import '../core/app_colors.dart';
import '../core/constants.dart';

part 'app_settings.g.dart';

/// Persisted application settings.
@HiveType(typeId: 6)
class AppSettings {
  /// 'dark' | 'light' | 'system'.
  @HiveField(0)
  String themeMode;

  /// 'en' | 'ur'.
  @HiveField(1)
  String locale;

  @HiveField(2)
  bool keepAwake;

  @HiveField(3)
  bool notificationsEnabled;

  /// How many times a page must be recited (revision standard).
  @HiveField(4)
  int revisionStandard;

  // ── Warning engine thresholds ─────────────────────────────────────────────
  @HiveField(5)
  int warningInactiveDays;

  @HiveField(6)
  int warningRepetitionCount;

  @HiveField(7)
  int absenceWindowDays;

  @HiveField(8)
  int absenceWarningCount;

  // ── Daily reminder time ───────────────────────────────────────────────────
  @HiveField(9)
  int notificationHour;

  @HiveField(10)
  int notificationMinute;

  /// Days without Sabaq/Sabqi/Manzil before a naagha (gap) alert is raised.
  @HiveField(11)
  int missingSabqiDays;

  /// 'emerald' | 'amber' — the app accent palette (see [AppColors]).
  @HiveField(12)
  String accent;

  // ── Performance grading thresholds ──────────────────────────────────────
  /// Minimum count for 'Behtareen' (excellent) grade.
  @HiveField(13)
  int gradingBehtareen;

  /// Minimum count for 'Behtar' (good) grade.
  @HiveField(14)
  int gradingBehtar;

  /// Minimum count for 'Acha' (passable) grade.
  @HiveField(15)
  int gradingAcha;

  // ── Madrasa info for PDF report header ───────────────────────────────────
  /// Madrasa / institution name shown in PDF reports.
  @HiveField(16)
  String madrasaName;

  /// Teacher name shown in PDF reports.
  @HiveField(17)
  String teacherName;

  AppSettings({
    this.themeMode = 'dark',
    this.locale = 'en',
    this.keepAwake = false,
    this.notificationsEnabled = false,
    this.revisionStandard = AppConstants.defaultRevisionStandard,
    this.warningInactiveDays = AppConstants.warningInactiveDays,
    this.warningRepetitionCount = AppConstants.warningRepetitionCount,
    this.absenceWindowDays = AppConstants.absenceWindowDays,
    this.absenceWarningCount = AppConstants.absenceWarningCount,
    this.notificationHour = AppConstants.defaultNotificationHour,
    this.notificationMinute = AppConstants.defaultNotificationMinute,
    this.missingSabqiDays = AppConstants.defaultNaaghaDays,
    this.accent = AppColors.accentEmerald,
    this.gradingBehtareen = AppConstants.defaultGradingBehtareen,
    this.gradingBehtar = AppConstants.defaultGradingBehtar,
    this.gradingAcha = AppConstants.defaultGradingAcha,
    this.madrasaName = '',
    this.teacherName = '',
  });

  factory AppSettings.defaults() => AppSettings();

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'locale': locale,
    'keepAwake': keepAwake,
    'notificationsEnabled': notificationsEnabled,
    'revisionStandard': revisionStandard,
    'warningInactiveDays': warningInactiveDays,
    'warningRepetitionCount': warningRepetitionCount,
    'absenceWindowDays': absenceWindowDays,
    'absenceWarningCount': absenceWarningCount,
    'notificationHour': notificationHour,
    'notificationMinute': notificationMinute,
    'missingSabqiDays': missingSabqiDays,
    'accent': accent,
    'gradingBehtareen': gradingBehtareen,
    'gradingBehtar': gradingBehtar,
    'gradingAcha': gradingAcha,
    'madrasaName': madrasaName,
    'teacherName': teacherName,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: json['themeMode'] as String? ?? 'dark',
    locale: json['locale'] as String? ?? 'en',
    keepAwake: json['keepAwake'] as bool? ?? false,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    revisionStandard:
        json['revisionStandard'] as int? ??
        AppConstants.defaultRevisionStandard,
    warningInactiveDays:
        json['warningInactiveDays'] as int? ?? AppConstants.warningInactiveDays,
    warningRepetitionCount:
        json['warningRepetitionCount'] as int? ??
        AppConstants.warningRepetitionCount,
    absenceWindowDays:
        json['absenceWindowDays'] as int? ?? AppConstants.absenceWindowDays,
    absenceWarningCount:
        json['absenceWarningCount'] as int? ?? AppConstants.absenceWarningCount,
    notificationHour:
        json['notificationHour'] as int? ??
        AppConstants.defaultNotificationHour,
    notificationMinute:
        json['notificationMinute'] as int? ??
        AppConstants.defaultNotificationMinute,
    missingSabqiDays:
        json['missingSabqiDays'] as int? ?? AppConstants.defaultNaaghaDays,
    accent: json['accent'] as String? ?? AppColors.accentEmerald,
    gradingBehtareen: json['gradingBehtareen'] as int? ??
        AppConstants.defaultGradingBehtareen,
    gradingBehtar:
        json['gradingBehtar'] as int? ?? AppConstants.defaultGradingBehtar,
    gradingAcha:
        json['gradingAcha'] as int? ?? AppConstants.defaultGradingAcha,
    madrasaName: json['madrasaName'] as String? ?? '',
    teacherName: json['teacherName'] as String? ?? '',
  );
}
