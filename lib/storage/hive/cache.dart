import 'package:hive_flutter/hive_flutter.dart';

class CacheBox {
  static const String boxName = 'cacheBox';

  static const String userKey = 'user';
  static const String businessesKey = 'businesses';
  static const String selectedBusinessIdKey = 'selectedBusinessId';
  static const String dashboardsKey = 'dashboards';

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

  static Future<void> setUser(Map<String, dynamic>? userJson) async {
    if (userJson == null) {
      await _box.delete(userKey);
    } else {
      await _box.put(userKey, userJson);
    }
  }

  static Map<String, dynamic>? getUser() {
    final user = _box.get(userKey);
    return user == null ? null : Map<String, dynamic>.from(user);
  }

  static Future<void> setBusinesses(List<Map<String, dynamic>> businesses) async {
    await _box.put(businessesKey, businesses);
  }

  static List<Map<String, dynamic>> getBusinesses() {
    final list = _box.get(businessesKey) ?? [];
    return (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> setSelectedBusinessId(String? businessId) async {
    if (businessId == null) {
      await _box.delete(selectedBusinessIdKey);
    } else {
      await _box.put(selectedBusinessIdKey, businessId);
    }
  }

  static String? getSelectedBusinessId() => _box.get(selectedBusinessIdKey);

  /// Last dashboard per business, shown instantly while a fresh one loads.
  static Future<void> setDashboard(
    String businessId,
    Map<String, dynamic> json,
  ) async {
    final all = Map<String, dynamic>.from(_box.get(dashboardsKey) ?? {});
    all[businessId] = json;
    await _box.put(dashboardsKey, all);
  }

  static Map<String, dynamic>? getDashboard(String businessId) {
    final all = _box.get(dashboardsKey);
    if (all is! Map) return null;
    final json = all[businessId];
    return json is Map ? Map<String, dynamic>.from(json) : null;
  }

  /// Removes entries written by older app versions (factory module, the old
  /// dashboard summary format).
  static Future<void> purgeLegacyCache() async {
    for (final key in const [
      'selectedFactoryId',
      'cachedFactories',
      'cachedSummaries',
      'cachedBusinessSummaries',
    ]) {
      if (_box.containsKey(key)) await _box.delete(key);
    }
  }
}
