import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'localization/app_localizations.dart';
import 'models/app_settings.dart';
import 'models/daily_record.dart';
import 'models/fee_record.dart';
import 'models/student.dart';
import 'providers/app_provider.dart';
import 'providers/google_drive_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

/// Boots the app.
///
/// Every step is individually guarded so that a single failing plugin (missing
/// assets, a corrupted Hive box, an unsupported notifications plugin) can never
/// leave the user stuck on the native splash screen: `runApp` always runs, and
/// the affected feature simply degrades gracefully instead of blocking the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Localization JSON — never fatal.
  try {
    await AppLocalizations.load();
  } catch (e) {
    debugPrint('AppLocalizations.load failed (falling back to raw keys): $e');
  }

  // Hive + adapters.
  try {
    await Hive.initFlutter();
    Hive
      ..registerAdapter(StudentAdapter())
      ..registerAdapter(DailyRecordAdapter())
      ..registerAdapter(SabaqEntryAdapter())
      ..registerAdapter(SabqiEntryAdapter())
      ..registerAdapter(ManzilEntryAdapter())
      ..registerAdapter(AppSettingsAdapter())
      ..registerAdapter(FeeRecordAdapter());
  } catch (e) {
    debugPrint('Hive init failed: $e');
  }

  final storage = StorageService.instance;
  try {
    await storage.init();
  } catch (e) {
    debugPrint('Storage init failed: $e');
  }

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider(storage)..init()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storage)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => GoogleDriveProvider(storage)..init(),
        ),
      ],
      child: const HifazApp(),
    ),
  );
}
