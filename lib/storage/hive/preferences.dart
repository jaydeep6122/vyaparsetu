import 'package:hive_flutter/hive_flutter.dart';

class PreferencesBox {
  static const String boxName = 'preferencesBox';

  static const String themeModeKey = 'themeMode';
  static const String localeKey = 'locale';
  static const String prevVersionKey = 'prevVersion';
  static const String appModeKey = 'appMode';

  static Future<void> open() async {
    await Hive.openBox(boxName);
  }

  static Future<void> close() async {
    final box = Hive.box(boxName);
    await box.close();
  }

  static Future<void> clear() async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  // Data methods
  static Future<void> setThemeMode(String themeStr) async {
    final box = Hive.box(boxName);
    await box.put(themeModeKey, themeStr);
  }

  static String getThemeMode() {
    final box = Hive.box(boxName);
    return box.get(themeModeKey) ?? 'light';
  }

  static Future<void> setLocaleCode(String localeCode) async {
    final box = Hive.box(boxName);
    await box.put(localeKey, localeCode);
  }

  static String getLocaleCode() {
    final box = Hive.box(boxName);
    return box.get(localeKey) ?? 'en';
  }

  static Future<void> setPrevVersion(String version) async {
    final box = Hive.box(boxName);
    await box.put(prevVersionKey, version);
  }

  static String getPrevVersion() {
    final box = Hive.box(boxName);
    return box.get(prevVersionKey) ?? '';
  }

  static Future<void> setAppMode(String mode) async {
    final box = Hive.box(boxName);
    await box.put(appModeKey, mode);
  }

  static String getAppMode() {
    final box = Hive.box(boxName);
    return box.get(appModeKey) ?? 'business';
  }
}
