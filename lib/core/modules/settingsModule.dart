import 'package:flutter/material.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/storage/hive/cache.dart';
import 'package:vyaparsetu/storage/hive/preferences.dart';

class SettingsModule {
  final Core core;
  SettingsModule(this.core);

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void load() {
    _themeMode = switch (PreferencesBox.getThemeMode()) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    // Older versions stored factory mode, language, invoice design and
    // version-check data that nothing reads any more.
    PreferencesBox.clearLegacyKeys();
    CacheBox.purgeLegacyCache();
    core.notify();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await PreferencesBox.setThemeMode(mode.name);
    core.notify();
  }
}
