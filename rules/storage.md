# Storage

## Rule
Non-sensitive data goes in Hive boxes. Sensitive data (tokens) goes in `flutter_secure_storage`. Both are initialized in `main()` before the app runs.

## Hive Boxes

| Box Class | File | Data |
|---|---|---|
| `CacheBox` | `storage/hive/cache.dart` | `user` (Map), `businesses` (List), `selectedBusinessId` (String?) |
| `UserBox` | `storage/hive/user.dart` | `deviceAuthEnabled` (bool), `lastLoginEmail` (String) |
| `PreferencesBox` | `storage/hive/preferences.dart` | `themeMode` (String), `locale` (String), `prevVersion` (String) |

### Box Pattern

```dart
class CacheBox {
  static Box? _box;
  static String get boxName => 'cacheBox';

  static Future<void> open() async {
    _box = await Hive.openBox(boxName);
  }

  static String? get selectedBusinessId => _box?.get('selectedBusinessId') as String?;
  static set selectedBusinessId(String? id) => _box?.put('selectedBusinessId', id);

  static Future<void> clear() async => _box?.clear();
  static Future<void> close() async => _box?.close();
}
```

## Secure Storage

```dart
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static Future<void> setAccessToken(String token) async =>
    await _storage.write(key: 'access_token', value: token);

  static Future<String?> getAccessToken() async =>
    await _storage.read(key: 'access_token');

  static Future<void> deleteAll() async =>
    await _storage.deleteAll();
}
```

## Initialization Order (in `main()`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await openAllBoxes();  // parallel: CacheBox + UserBox + PreferencesBox
  await EasyLocalization.ensureInitialized();
  // ...
  DioInstance.init(baseURL: AppConstants.apiBaseUrl);
  Api.initialize(dioInstance.dio);
  final core = Core();
  await core.settings.load();
  // ...
}
```

## Cleanup on Logout

```dart
await clearBoxes();     // clears cacheBox + userBox
await SecureStorage.deleteAll();  // clears tokens
```

## DO
- Use Hive boxes for non-sensitive app data
- Use `flutter_secure_storage` for access/refresh tokens only
- Open all boxes in parallel via `Future.wait` in `openAllBoxes()`
- Clear all storage on logout

## DON'T
- Store tokens in Hive — always use `flutter_secure_storage`
- Open Hive boxes lazily — open all at app startup
- Use SharedPreferences — all local storage is Hive-based
