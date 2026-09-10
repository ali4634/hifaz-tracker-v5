import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';

/// Schedules the daily Sabqi-reminder notification.
///
/// Guarded to Android / iOS only — other platforms no-op gracefully.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _available = false;
  bool _tzReady = false;

  bool get available => _available;

  Future<void> init() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    tzdata.initializeTimeZones();
    _tzReady = true;
    _available = true;
  }

  Future<void> requestPermissions() async {
    if (!_available) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a daily repeating notification at [hour]:[minute] using a
  /// time-zone aware zoned schedule (reschedules itself daily).
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_available || !_tzReady) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminders',
        'Daily Reminders',
        channelDescription: 'Daily reminder for missing Sabqi logs',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: AppConstants.dailyReminderNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules a daily repeating notification for a specific student (used by
  /// the naagha / gap alerting). Uses [id] for the platform notification id.
  Future<void> scheduleStudentReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_available || !_tzReady) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'naagha_alerts',
        'Naagha Alerts',
        channelDescription: 'Daily alerts for students who skipped lessons',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels every per-student naagha (gap) reminder previously scheduled
  /// (ids in the [AppConstants.naaghaNotificationBaseId] range). Prevents
  /// stale alerts for students who have since recited.
  Future<void> cancelStudentReminders() async {
    if (!_available) return;
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(id: AppConstants.naaghaNotificationBaseId + i);
    }
  }

  Future<void> cancelAll() async {
    if (!_available) return;
    await _plugin.cancelAll();
  }
}
