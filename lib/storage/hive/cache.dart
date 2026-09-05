import 'package:hive_flutter/hive_flutter.dart';

class CacheBox {
  static const String boxName = 'cacheBox';

  static const String userKey = 'user';
  static const String businessesKey = 'businesses';
  static const String selectedBusinessIdKey = 'selectedBusinessId';
  static const String selectedFactoryIdKey = 'selectedFactoryId';

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
  static Future<void> setUser(Map<String, dynamic>? userJson) async {
    final box = Hive.box(boxName);
    if (userJson == null) {
      await box.delete(userKey);
    } else {
      await box.put(userKey, userJson);
    }
  }

  static Map<String, dynamic>? getUser() {
    final box = Hive.box(boxName);
    final user = box.get(userKey);
    return user == null ? null : Map<String, dynamic>.from(user);
  }

  static Future<void> setBusinesses(List<Map<String, dynamic>> businesses) async {
    final box = Hive.box(boxName);
    await box.put(businessesKey, businesses);
  }

  static List<Map<String, dynamic>> getBusinesses() {
    final box = Hive.box(boxName);
    final list = box.get(businessesKey) ?? [];
    return (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> setSelectedBusinessId(String? businessId) async {
    final box = Hive.box(boxName);
    if (businessId == null) {
      await box.delete(selectedBusinessIdKey);
    } else {
      await box.put(selectedBusinessIdKey, businessId);
    }
  }

  static String? getSelectedBusinessId() {
    final box = Hive.box(boxName);
    return box.get(selectedBusinessIdKey);
  }

  /// Removes cache entries left behind by the factory module.
  ///
  /// Existing installs still hold these keys, and nothing reads them any more,
  /// so purge them once on startup rather than leaving stale data on disk.
  static Future<void> purgeFactoryCache() async {
    final box = Hive.box(boxName);
    for (final key in const [
      selectedFactoryIdKey,
      'cachedFactories',
      'cachedSummaries',
    ]) {
      if (box.containsKey(key)) {
        await box.delete(key);
      }
    }
  }

  // --- Persistent Business Dashboard Caching ---
  static const String cachedBusinessSummariesKey = 'cachedBusinessSummaries';

  static Future<void> setCachedBusinessSummaries(Map<String, dynamic> summaries) async {
    final box = Hive.box(boxName);
    await box.put(cachedBusinessSummariesKey, summaries);
  }

  static Map<String, dynamic> getCachedBusinessSummaries() {
    final box = Hive.box(boxName);
    final data = box.get(cachedBusinessSummariesKey) ?? {};
    return Map<String, dynamic>.from(data);
  }
}
