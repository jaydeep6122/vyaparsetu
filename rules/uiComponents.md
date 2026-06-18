# UI Components

## Rule
Use existing components from `lib/components/` before building new. Theme everything through `AppTheme`.

## Available Components

| Component | Description |
|---|---|
| `AmountDisplay` | Formatted currency text, colored for receivable/expense |
| `AppButton` | Primary/secondary/outlined button with loading state |
| `AppTextField` | Styled input field with password visibility toggle |
| `ConfirmationDialog` | Reusable confirm/cancel dialog |
| `EmptyState` | Placeholder for empty lists with optional action button |
| `AppErrorWidget` | Error display with optional retry callback |
| `ImagePickerWidget` | Camera/gallery image picker with preview |
| `LoadingIndicator` | Spinner (with optional message) or shimmer skeleton |
| `PremiumNavBar` | Custom bottom navigation bar |
| `AppSearchBar` | Debounced search input with clear button |
| `SectionHeader` | Section title with optional "View All" link |
| `SignaturePadWidget` | Drawing pad for signatures |
| `StatusChip` | Colored chip with named constructors (paid, unpaid, partiallyPaid) |
| `SummaryCard` | Dashboard metric card with icon, value, colored accent |

## Theming

```dart
// Use AppTheme constants — never raw values
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppTheme.radiusMd),   // not 12
    boxShadow: [AppTheme.shadowSm],                            // not custom shadow
    gradient: AppTheme.primaryGradient,                        // not hand-written gradient
  ),
  padding: EdgeInsets.all(AppTheme.spaceMd),                   // not 16
  child: Text(
    'Hello',
    style: GoogleFonts.outfit(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
)
```

## Dark Mode

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;

// Conditional color:
color: isDark ? AppTheme.primaryDark : AppTheme.primary,

// Or use theme directly (preferred):
color: Theme.of(context).colorScheme.primary,
```

## DO
- Browse `lib/components/` before creating a new widget
- Use `AppTheme` constants for colors, spacing, border radius, shadows, gradients
- Use `GoogleFonts.outfit()` for text styling
- Use `Theme.of(context)` for Material Design properties
- Wrap reusable UI patterns as components in `lib/components/`

## DON'T
- Use raw color hex values (e.g., `Color(0xFF...)`) — use AppTheme colors
- Use hardcoded padding/spacing values — use `AppTheme.space*` constants
- Use hardcoded border radius — use `AppTheme.radius*` constants
- Define components in screen files — extract to `lib/components/`
