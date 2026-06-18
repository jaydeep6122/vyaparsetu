# Localization

## Rule
All user-facing strings use `easy_localization` translation keys. Three supported locales: English, Hindi, Gujarati.

## Setup

```dart
EasyLocalization(
  supportedLocales: const [Locale('en'), Locale('hi'), Locale('gu')],
  path: 'assets/translations',
  fallbackLocale: const Locale('en'),
  child: ChangeNotifierProvider.value(
    value: core,
    child: const VyaparSetuApp(),
  ),
)
```

## Usage

```dart
// In widgets
Text('welcome'.tr());
Text('total_sales'.tr());
Text('invoice_no'.tr(args: ['INV-001']));

// In MaterialApp
localizationsDelegates: context.localizationDelegates,
supportedLocales: context.supportedLocales,
locale: settings.locale,  // from SettingsModule
```

## Translation Files

```
assets/translations/
├── en.json
├── hi.json
└── gu.json
```

## Switching Locale

```dart
// Through SettingsModule (recommended)
await core.settings.changeLocale(context, const Locale('hi'));
```

Internally:
1. Set locale in PreferencesBox for persistence
2. Call `context.setLocale(newLocale)`

## Language Picker UI

- **Login screen:** `PopupMenuButton` with EN / HI / GU options
- **Settings screen:** Bottom sheet with radio-style locale picker

## DO
- Use `'key'.tr()` for all user-facing strings
- Group keys by feature/ screen (e.g., `login.email_hint`, `invoice.form.party_label`)
- Persist locale choice in `PreferencesBox`
- Use `SettingsModule.changeLocale()` to switch

## DON'T
- Hardcode user-facing strings in English
- Use `MaterialApp`'s built-in localization without `EasyLocalization`
- Add a new locale without creating the corresponding JSON file
- Use `context.locale` directly for persistence — go through `SettingsModule`
