# VyaparSetu Project Rules

> Flutter `3.35.5` | SDK `^3.9.2` | Provider + Core | Backend: `vyaparsetubackend.onrender.com/v1`

## Quick Rules

| Area | Rule |
|---|---|
| **Files** | ALL camelCase (`authModule.dart`, `appTextField.dart`) |
| **Screens** | No `_screen` suffix — just `login.dart`, `list.dart`, `form.dart` |
| **Core modules** | `Module` suffix (`authModule.dart` → `AuthModule`) |
| **State** | Single `Core` ChangeNotifier. Use `context.select<Core, T>()` for watching, `context.read<Core>()` for one-time reads. |
| **Models** | Immutable, `fromJson`/`toJson`, `copyWith`. Snake_case JSON keys. |
| **API** | `Api.instance.<module>.<method>()`. All API calls inside Core modules. |
| **Storage** | Hive (cache, user, preferences) + `flutter_secure_storage` for tokens. |
| **Navigation** | `Navigator.push(getPageRoute(Widget()))`. No named routes. |
| **PDF** | `InvoicePdfService` — JK's Classic layout. Sale invoices only. |
| **Theming** | `AppTheme` constants. `SettingsModule` controls light/dark. |
| **Components** | Use existing `lib/components/` widgets before creating new. |
| **Localization** | 3 locales (EN/HI/GU). Usage: `'key'.tr()`. |

## Detailed Rules

- [Structure](rules/structure.md) — Directory layout and purposes
- [State Management](rules/stateManagement.md) — Core, modules, `context.read`/`context.select`
- [Naming](rules/naming.md) — File, class, variable naming conventions
- [API](rules/api.md) — Api singleton, Dio, request patterns
- [Models](rules/models.md) — Type definitions, JSON serialization, enums
- [UI Screens](rules/uiScreens.md) — Screen structure, provider wiring, navigation
- [UI Components](rules/uiComponents.md) — Reusable widgets, theming, dark mode
- [Storage](rules/storage.md) — Hive boxes, secure storage, initialization order
- [PDF](rules/pdf.md) — Invoice PDF generation, layout, constraints
- [Localization](rules/localization.md) — Translation keys, locale switching
