# Localization

## Rule
Every user-facing string goes through an `easy_localization` key. The app ships
**English only** for now; keys stay in place so more languages can be added
without touching screens.

## Setup

```dart
EasyLocalization(
  supportedLocales: const [Locale('en')],
  path: 'assets/translations',
  fallbackLocale: const Locale('en'),
  startLocale: const Locale('en'),
  saveLocale: false,
  child: ChangeNotifierProvider.value(value: core, child: const VyaparSetuApp()),
)
```

`MaterialApp` uses `context.localizationDelegates`, `context.supportedLocales`
and `context.locale`. There is no language picker and no locale in
`PreferencesBox`.

## Usage

```dart
Text('save_changes'.tr());
Text('due_amount'.tr(namedArgs: {'amount': Formatters.formatCurrency(due)}));
```

Placeholders are always `namedArgs` with `{name}` in the JSON — never
positional `args`, which break when a sentence is reordered.

## Keys

- Flat, snake_case, one file: `assets/translations/en.json`.
- Screen strings read like the UI: `save_bill`, `no_parties_yet_hint`.
- Enums build their key from the wire value, so every enum value needs a key:
  `party_type_customer`, `payment_mode_upi`, `role_admin` (+ `role_admin_description`).
- Server field names used in validation errors map through `field_<name>`.
- Unique-constraint messages map through `error_<thing>_exists`
  (see `helpers/userFriendlyErrors.dart`).

## Checking for gaps

`tr()` returns the key itself when it is missing, so a raw `snake_case` string
on screen means a missing key. To check everything at once:

```bash
python3 - <<'PY'
import json, re, pathlib
keys = json.load(open('assets/translations/en.json'))
used = set()
for f in pathlib.Path('lib').rglob('*.dart'):
    used |= set(re.findall(r"'([a-z0-9_]+)'\.tr\(", f.read_text()))
print(sorted(k for k in used if k not in keys))
PY
```

Dynamic keys (`'party_type_$value'`) are not caught by that scan — add them by
hand when an enum gains a value.

## DO
- Add the key to `en.json` in the same change that uses it
- Keep the JSON sorted alphabetically so merges stay clean
- Write plain shopkeeper English: "You'll get", "Send reminder"

## DON'T
- Hardcode user-facing English in widgets
- Reuse one key with different meanings in two screens
- Translate log messages, enum wire values or API payloads
