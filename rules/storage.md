# Storage

## Rule
Non-sensitive data goes in Hive; tokens go in `flutter_secure_storage`. Both
are opened in `main()` before the app runs. Local storage is a cache and a
preference store — never a second source of truth.

## Hive boxes

| Box | File | Data |
|---|---|---|
| `CacheBox` | `storage/hive/cache.dart` | `user`, `businesses`, `selectedBusinessId`, per-business `dashboards` |
| `UserBox` | `storage/hive/user.dart` | `lastLoginEmail`, `deviceAuthEnabled` |
| `PreferencesBox` | `storage/hive/preferences.dart` | `themeMode` only |

`CacheBox.purgeLegacyCache()` and `PreferencesBox.clearLegacyKeys()` run at
startup from `SettingsModule.load()` to drop keys older versions wrote
(language, invoice design, version checks).

The cache exists so the app opens with something on screen: the last user, the
business list and the last dashboard. Every one of them is refreshed from the
server right after.

## Secure storage

`SecureStorage` keeps `access_token` and `refresh_token` and nothing else.
`deleteAll()` runs on sign-out and when a refresh fails.

## Startup order (`main.dart`)

```dart
await Hive.initFlutter();
await openAllBoxes();                  // CacheBox + UserBox + PreferencesBox
await EasyLocalization.ensureInitialized();
final dioInstance = await DioInstance.init(baseURL: AppConstants.apiBaseUrl);
Api.initialize(dioInstance.dio);
final core = Core();
core.settings.load();                  // theme + legacy cleanup
```

## Sign-out

```dart
await SecureStorage.deleteAll();
await clearBoxes();
core.auth.handleSessionExpired();      // clears Core state
```

## DO
- Cache only what makes the first frame useful
- Key cached data by business id (`CacheBox.setDashboard(businessId, json)`)
- Clear everything on sign-out

## DON'T
- Store tokens, GSTINs or ledger data in Hive
- Read a cached value when a module already has it
- Use SharedPreferences
