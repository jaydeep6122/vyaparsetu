# Naming

## Rule
File names are `camelCase`, classes `PascalCase`, and screen files carry no
`_screen` suffix.

## File names

| Category | Convention | Examples |
|---|---|---|
| Core modules | camelCase + `Module` | `partyModule.dart`, `reportModule.dart` |
| Screens | camelCase, short | `login.dart`, `list.dart`, `form.dart`, `detail.dart` |
| Screen-only widgets | `widgets.dart` beside the screen | `screens/invoices/widgets.dart` |
| API modules | camelCase entity | `party.dart`, `invoice.dart`, `report.dart` |
| Types | camelCase entity | `party.dart`, `stockAdjustment.dart`, `reports.dart` |
| Components | camelCase, descriptive | `appButton.dart`, `pickerSheet.dart`, `loadStateBody.dart` |
| Helpers | camelCase | `inputFormatters.dart`, `imageData.dart` |
| Services | camelCase + `Service` | `invoicePdfService.dart` |

## Class names

| File | Class |
|---|---|
| `partyModule.dart` | `PartyModule` |
| `list.dart` (parties) | `PartyListScreen` |
| `form.dart` (invoices) | `InvoiceFormScreen` |
| `party.dart` (api) | `PartyApi` |
| `party.dart` (types) | `Party` |
| `cache.dart` | `CacheBox` |

Screens always end in `Screen`, API classes in `Api`, Hive boxes in `Box`.

## Members

- Private form state uses a leading underscore: `_formKey`, `_lines`, `_party`.
- Booleans read as a question: `isSaving`, `hasMore`, `showTransport`, `canPay`.
- Draft classes inside a form are private and end in `Draft`
  (`_LineDraft`, `_ChargeDraft`).
- Small anonymous shapes use records with named fields:
  `typedef PartyRef = ({String id, String name});`
- Module variables in screens read as the module:
  `final parties = context.watch<Core>().party;`

## Translation keys

snake_case, flat, named after what the user sees (`save_bill`,
`no_parties_yet_hint`). Enum keys are `<enum>_<wire value>`
(`payment_mode_bank_transfer`).

## DO
- Match the class name to the file name
- Keep feature directories flat: `list`, `form`, `detail`, `widgets`

## DON'T
- Use `snake_case` or `kebab-case` file names
- Add `_screen` / `_page` suffixes
- Abbreviate beyond common usage (`gst`, `hsn`, `lr`, `upi` are fine)
