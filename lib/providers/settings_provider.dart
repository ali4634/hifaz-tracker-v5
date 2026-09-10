import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// App settings + runtime side effects (wakelock, notifications).
class SettingsProvider extends ChangeNotifier {
  final StorageService storage;

  SettingsProvider(this.storage);

  late AppSettings settings;

  ThemeMode get themeMode => switch (settings.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Locale get locale => Locale(settings.locale);

  Future<void> init() async {
    settings = storage.settings ?? AppSettings.defaults();
    await _applyRuntimeSettings();
    notifyListeners();
  }

  Future<void> _persist() async {
    await storage.putSettings(settings);
    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setThemeMode(String mode) async {
    settings.themeMode = mode;
    await _persist();
  }

  Future<void> setLocale(String code) async {
    settings.locale = code;
    await _persist();
  }

  /// Switches the accent palette ('emerald' | 'amber').
  Future<void> setAccent(String accent) async {
    if (settings.accent == accent) return;
    settings.accent = accent;
    await _persist();
  }

  Future<void> setKeepAwake(bool value) async {
    settings.keepAwake = value;
    await _persist();
    await _applyKeepAwake();
  }

  Future<void> setNotificationsEnabled(
    bool value, {
    String title = '',
    String body = '',
  }) async {
    settings.notificationsEnabled = value;
    await _persist();
    await _applyNotifications(title: title, body: body);
  }

  Future<void> setNotificationTime(
    int hour,
    int minute, {
    String title = '',
    String body = '',
  }) async {
    settings.notificationHour = hour;
    settings.notificationMinute = minute;
    await _persist();
    if (settings.notificationsEnabled) {
      await _applyNotifications(title: title, body: body);
    }
  }

  Future<void> setRevisionStandard(int value) async {
    settings.revisionStandard = value.clamp(1, 10);
    await _persist();
  }

  Future<void> setWarningThresholds({
    required int inactiveDays,
    required int repetitionCount,
    required int absenceWindow,
    required int absenceCount,
  }) async {
    settings
      ..warningInactiveDays = inactiveDays
      ..warningRepetitionCount = repetitionCount
      ..absenceWindowDays = absenceWindow
      ..absenceWarningCount = absenceCount;
    await _persist();
  }

  Future<void> setNaaghaDays(int days) async {
    settings.missingSabqiDays = days.clamp(1, 30);
    await _persist();
  }

  // ── Grading thresholds ────────────────────────────────────────────────────

  Future<void> setGradingThresholds({
    required int behtareen,
    required int behtar,
    required int acha,
  }) async {
    settings
      ..gradingBehtareen = behtareen
      ..gradingBehtar = behtar
      ..gradingAcha = acha;
    await _persist();
  }

  Future<void> setMadrasaName(String name) async {
    settings.madrasaName = name;
    await _persist();
  }

  Future<void> setTeacherName(String name) async {
    settings.teacherName = name;
    await _persist();
  }

  // ── Runtime effects ───────────────────────────────────────────────────────

  Future<void> _applyRuntimeSettings() async {
    await _applyKeepAwake();
    await _applyNotifications();
  }

  Future<void> _applyKeepAwake() async {
    try {
      if (settings.keepAwake) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Wakelock unavailable on this platform — safe to ignore.
    }
  }

  Future<void> _applyNotifications({
    String title = '',
    String body = '',
  }) async {
    final svc = NotificationService.instance;
    if (!settings.notificationsEnabled) {
      await svc.cancelAll();
      return;
    }
    await svc.requestPermissions();
    await svc.scheduleDailyReminder(
      hour: settings.notificationHour,
      minute: settings.notificationMinute,
      title: title.isEmpty ? 'Sabqi reminder' : title,
      body: body.isEmpty ? 'Log today\'s Sabqi lessons!' : body,
    );
  }
}
