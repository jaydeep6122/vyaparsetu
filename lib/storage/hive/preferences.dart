import 'package:hive_flutter/hive_flutter.dart';
import 'package:vyaparsetu/global/constants.dart';

class PreferencesBox {
  static const String boxName = 'preferencesBox';

  static const String themeModeKey = 'themeMode';
  static const String localeKey = 'locale';
  static const String prevVersionKey = 'prevVersion';
  static const String appModeKey = 'appMode';
  static const String invoiceDesignKey = 'invoiceDesign';

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

  static Future<void> setInvoiceDesign(String design) async {
    final box = Hive.box(boxName);
    await box.put(invoiceDesignKey, design);
  }

  static String getInvoiceDesign() {
    final box = Hive.box(boxName);
    return box.get(invoiceDesignKey) ?? '';
  }

  static BillDesign? getPreferredDesign(BillType billType) {
    final saved = getInvoiceDesign();
    if (saved.isNotEmpty) {
      final design = BillDesign.fromString(saved);
      if (design.isGst == (billType == BillType.gst)) {
        return design;
      }
    }
    return null;
  }

  static BillDesign defaultDesignFor(BillType billType) {
    if (billType == BillType.gst) return BillDesign.gstClassic;
    return BillDesign.normalSimple;
  }

  static const String lastVersionCheckKey = 'lastVersionCheck';

  static Future<void> setLastVersionCheck(DateTime time) async {
    final box = Hive.box(boxName);
    await box.put(lastVersionCheckKey, time.toIso8601String());
  }

  static DateTime? getLastVersionCheck() {
    final box = Hive.box(boxName);
    final str = box.get(lastVersionCheckKey) as String?;
    return str != null ? DateTime.tryParse(str) : null;
  }
}
