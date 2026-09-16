import 'package:hive_flutter/hive_flutter.dart';

class PreferencesBox {
  static const String boxName = 'preferencesBox';

  static const String themeModeKey = 'themeMode';

  static Box get _box => Hive.box(boxName);

  static Future<void> open() async {
    await Hive.openBox(boxName);
  }

  static Future<void> close() async {
    await _box.close();
  }

  static Future<void> clear() async {
    await _box.clear();
  }

  /// 'light', 'dark' or 'system'.
  static Future<void> setThemeMode(String themeMode) async {
    await _box.put(themeModeKey, themeMode);
  }

  static String getThemeMode() => _box.get(themeModeKey) ?? 'system';

  /// Removes preferences written by older app versions.
  static Future<void> clearLegacyKeys() async {
    for (final key in const [
      'appMode',
      'locale',
      'invoiceDesign',
      'prevVersion',
      'lastVersionCheck',
    ]) {
      if (_box.containsKey(key)) await _box.delete(key);
    }
  }
}
