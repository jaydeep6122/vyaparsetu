# UI Components

## Rule
Build screens out of `lib/components/`. Colours, spacing and radii come from
the theme — never raw values.

## Available components

| Component | Description |
|---|---|
| `AppButton` | `primary` / `secondary` / `outline` / `danger` / `text`, loading state, `compact`, `expand` |
| `AppTextField` | Form field with helper, prefix/suffix, password toggle, formatters |
| `AppCard` | Bordered surface used for rows, sections and summaries |
| `AmountDisplay` | Rupee amount with tabular figures and tone (positive / negative / bySign) |
| `StatusChip` | Small status pill; `forInvoice`, `forPayment`, `forRecord`; `toneColors(context, tone)` for matching icon colours |
| `SummaryCard` | Headline figure with icon, optional tap |
| `InfoRow` | "Label … value" line; renders nothing when the value is null |
| `SectionHeader` | Section title with an optional action |
| `EmptyState` | Icon, title, hint and an optional action button |
| `AppErrorWidget` | Error with retry |
| `LoadingIndicator` / `SkeletonList` | Spinner, or placeholder rows while a list loads |
| `LoadStateBody` / `LoadStateSection` | Renders a `LoadState<T>`: value, spinner or error |
| `PagedListView` | Pull-to-refresh list that loads the next page near the bottom |
| `AppSearchBar` | Debounced search with clear |
| `showPickerSheet<T>` | Bottom sheet picker with local or server search and an "add new" action |
| `FormSection`, `SelectField<T>`, `DateField`, `SwitchRow`, `ChoiceChipsField<T>` | Form building blocks |
| `showConfirmDialog`, `showReasonDialog`, `showTextInputDialog` | Standard dialogs |
| `PeriodBar` | Report period chooser (this FY, month, custom …) |
| `InitialsAvatar`, `BusinessLogo`, `decodeImageDataUri` | Avatars and inline images |
| `ImagePickerWidget`, `SignaturePadWidget` | Logo picking and signature drawing |

Domain tiles live next to their screens: `InvoiceTile`, `PartyTile`,
`PartyBalance`, `ItemTile`, `PaymentTile`, `LedgerView`.

## Theming

```dart
final colors = context.colors;   // AppColors theme extension
final text = context.text;       // TextTheme
context.isDark;                  // brightness

Container(
  padding: const EdgeInsets.all(AppTheme.spaceLg),
  decoration: BoxDecoration(
    color: colors.surface,
    border: Border.all(color: colors.border),
    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
  ),
  child: Text('Hello', style: text.titleMedium),
)
```

`AppColors` carries `primary`, `onPrimary`, `primarySoft`, `background`,
`surface`, `surfaceAlt`, `border`, `ink`, `inkSecondary`, `muted`, and
`success`/`danger`/`warning`/`info` with their `*Soft` backgrounds. Both light
and dark palettes define every token, so no widget needs an `isDark` branch.

Spacing: `spaceXs 4`, `spaceSm 8`, `spaceMd 12`, `spaceLg 16`, `spaceXl 20`,
`space2xl 24`, `space3xl 32`, `space4xl 48`. Radii: `radiusXs 6` … `radiusFull`.
Lists that sit under a FAB end with `AppTheme.fabClearance` padding.

## DO
- Check `lib/components/` before writing a widget
- Take colours from `context.colors` and text styles from `context.text`
- Keep new shared widgets in `lib/components/`, screen-specific ones in `widgets.dart` beside the screen

## DON'T
- Use raw hex colours, hardcoded padding or `GoogleFonts` in screens (the theme sets Inter)
- Branch on `isDark` — the palette already handles it
- Re-implement empty, loading or error states by hand
