import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/storage/hive/preferences.dart';
import 'package:vyaparsetu/core/Core.dart';

class SettingsModule {
  final Core core;
  SettingsModule(this.core);

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void load() {
    _loadTheme();
    _loadLocale();
  }

  void _loadTheme() {
    final themeStr = PreferencesBox.getThemeMode();
    _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
    core.notify();
  }

  void _loadLocale() {
    final code = PreferencesBox.getLocaleCode();
    _locale = Locale(code);
    core.notify();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      await PreferencesBox.setThemeMode('dark');
    } else {
      _themeMode = ThemeMode.light;
      await PreferencesBox.setThemeMode('light');
    }
    core.notify();
  }

  Future<void> changeLocale(BuildContext context, Locale newLocale) async {
    _locale = newLocale;
    await PreferencesBox.setLocaleCode(newLocale.languageCode);
    if (context.mounted) {
      await context.setLocale(newLocale);
    }
    core.notify();
  }
}
