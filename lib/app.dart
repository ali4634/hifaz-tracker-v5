import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'localization/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

class HifazApp extends StatelessWidget {
  const HifazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final accent = settings.settings.accent;
        // Resolve the brightness MaterialApp will actually render (honouring
        // "system") and point the theme-aware AppColors getters at the right
        // palette. Both theme builders below run on every rebuild, so the flag
        // is resolved here — after both are constructed nothing overrides it.
        final brightness = switch (settings.themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        AppColors.setBrightness(brightness);
        return MaterialApp(
          title: 'Hifaz Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(accent: accent),
          darkTheme: AppTheme.dark(accent: accent),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: const [Locale('en'), Locale('ur')],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeScreen(),
        );
      },
    );
  }
}
