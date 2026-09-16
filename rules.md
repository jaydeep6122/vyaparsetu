# VyaparSetu Project Rules

> Flutter `3.35.5` | SDK `^3.9.2` | Provider + Core | Backend: `vyaparsetubackend.onrender.com/v1`

## Quick Rules

| Area | Rule |
|---|---|
| **Files** | ALL camelCase (`authModule.dart`, `appTextField.dart`) |
| **Screens** | No `_screen` suffix — just `login.dart`, `list.dart`, `form.dart` |
| **Core modules** | `Module` suffix, all extend `CoreModule` (`partyModule.dart` → `PartyModule`) |
| **State** | Single `Core` ChangeNotifier. `context.read` for actions, `context.select` for one value, `context.watch` on screens that show several. |
| **Server is truth** | Never compute balances, stock or invoice totals in the app. Mark stale, refetch. |
| **Models** | Immutable, `fromJson` (+ `toJson` only where something is cached). Snake_case JSON, parsed with `helpers/json.dart`. |
| **API** | `Api.instance.<module>.<method>()`, called only from Core modules. Screens pass plain snake_case maps. |
| **Storage** | Hive (`CacheBox`, `UserBox`, `PreferencesBox`) + `flutter_secure_storage` for tokens. |
| **Navigation** | `Navigator.push(getPageRoute(Widget()))`. No named routes. |
| **PDF** | `InvoicePdfService.generate()` — classic layout for GST, simple for non-GST. Nothing else. |
| **Theming** | `context.colors` / `context.text` + `AppTheme` spacing and radii. No `isDark` branches. |
| **Components** | Use `lib/components/` before writing a widget. |
| **Roles** | `core.can(MemberRole.accountant)` etc. Hide what the backend would refuse. |
| **Localization** | English only, but every string is a key: `'save'.tr()`. |

## Detailed Rules

- [Structure](rules/structure.md) — Directory layout and purposes
- [State Management](rules/stateManagement.md) — Core, CoreModule, PagedState/LoadState
- [Naming](rules/naming.md) — File, class, variable naming conventions
- [API](rules/api.md) — Api singleton, Dio, response envelope
- [Models](rules/models.md) — Type definitions, JSON parsing, enums
- [UI Screens](rules/uiScreens.md) — Screen structure, loading, navigation
- [UI Components](rules/uiComponents.md) — Reusable widgets and theming
- [Storage](rules/storage.md) — Hive boxes, secure storage, startup order
- [PDF](rules/pdf.md) — Bill generation, layouts, sharing
- [Localization](rules/localization.md) — Translation keys and checks
