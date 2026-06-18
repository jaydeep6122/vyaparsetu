# Naming

## Rule
ALL file names use `camelCase`. Class names use `PascalCase`. Screen files omit `_screen` suffix.

## File Names

| Category | Convention | Examples |
|---|---|---|
| Core modules | camelCase + `Module` suffix | `authModule.dart`, `settingsModule.dart` |
| Screen files | camelCase (short) | `login.dart`, `list.dart`, `form.dart`, `detail.dart`, `settings.dart` |
| API modules | camelCase (entity name) | `auth.dart`, `business.dart`, `invoice.dart` |
| Types/Models | camelCase (entity name) | `invoice.dart`, `user.dart`, `party.dart` |
| Components | camelCase (descriptive) | `appButton.dart`, `emptyState.dart`, `confirmationDialog.dart` |
| Services | camelCase | `invoicePdfService.dart` |
| Storage | camelCase (box purpose) | `user.dart`, `cache.dart`, `preferences.dart`, `secureStorage.dart` |
| Helpers | camelCase | `navigation.dart`, `formatters.dart`, `toastNotifications.dart` |

## Class Names

| File | Class Name | Notes |
|---|---|---|
| `authModule.dart` | `AuthModule` | PascalCase, matches filename |
| `login.dart` | `LoginScreen` | Screen classes always end with `Screen` |
| `list.dart` | `ItemListScreen` | Entity + List + Screen |
| `form.dart` | `InvoiceFormScreen` | Entity + Form + Screen |
| `invoice.dart` (api) | `InvoiceApi` | Entity + Api |
| `invoice.dart` (types) | `Invoice` | Entity name only |
| `appButton.dart` | `AppButton` | Descriptive PascalCase |
| `cache.dart` | `CacheBox` | Entity + Box |
| `user.dart` | `UserBox` | Entity + Box |
| `invoicePdfService.dart` | `InvoicePdfService` | Descriptive PascalCase |

## Variables & Properties

- Variables in screens referencing Core modules: use `{module}Module` or `provider` suffix
  ```dart
  final businessModule = context.read<Core>().business;
  await businessModule.fetchBusinesses();
  ```
- Avoid single-letter variable names except in trivial lambdas
- Booleans: prefix with `is`, `has`, `show`, `can`
  ```dart
  bool isLoading;
  bool hasError;
  bool showDetails;
  ```

## DO
- Name screen files as `login.dart`, not `loginScreen.dart` or `login_screen.dart`
- Keep component names descriptive: `emptyState.dart`, `statusChip.dart`
- Match class name to filename (PascalCase class, camelCase file)

## DON'T
- Use `_screen` suffix on filenames (`login_screen.dart` → `login.dart`)
- Use `snake_case` for filenames (`app_text_field.dart` → `appTextField.dart`)
- Use `kebab-case` for filenames
- Name screens with full className as filename (`loginScreen.dart` → `login.dart`)
