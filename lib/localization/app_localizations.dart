import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lightweight JSON-backed localization (en / ur).
class AppLocalizations {
  static const List<String> supportedLocales = ['en', 'ur'];

  static Map<String, Map<String, String>> _strings = const {};

  final String localeName;

  AppLocalizations(this.localeName);

  /// Loads all locale JSON files from assets. Call once before runApp.
  static Future<void> load() async {
    final loaded = <String, Map<String, String>>{};
    for (final code in supportedLocales) {
      final raw = await rootBundle.loadString('assets/lang/$code.json');
      loaded[code] = Map<String, String>.from(
        (jsonDecode(raw) as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
    }
    _strings = loaded;
  }

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      AppLocalizations('en');

  bool get isUrdu => localeName == 'ur';

  /// Looks up [key]; supports `{0}`, `{1}`… positional placeholders.
  String t(String key, {List<String>? args}) {
    final map = _strings[localeName] ?? _strings['en'] ?? const {};
    var value = map[key] ?? _strings['en']?[key] ?? key;
    if (args != null && args.isNotEmpty) {
      for (var i = 0; i < args.length; i++) {
        value = value.replaceAll('{$i}', args[i]);
      }
    }
    return value;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale.languageCode);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
