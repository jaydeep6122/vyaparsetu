import 'package:flutter/material.dart';
import 'package:vyaparsetu/global/themes.dart';

/// Shared date picker for the whole app.
///
/// Two things this centralises:
///
/// 1. **Range.** Entry forms used to hard-code `DateTime(2025)`–`DateTime(2030)`,
///    which made it impossible to back-date an invoice into an earlier financial
///    year and would have broken the app in 2031. The range is now relative to
///    today, so it keeps moving with the calendar.
/// 2. **Dark mode.** The stock `showDatePicker` renders light-on-light in dark
///    mode. That fix previously existed in the invoice form only; every caller
///    gets it now.
/// Default lower bound: far enough back to enter earlier financial years.
DateTime appDateFirst() => DateTime(DateTime.now().year - 5);

/// Default upper bound: allows forward-dated documents without unbounded scroll.
DateTime appDateLast() => DateTime(DateTime.now().year + 1, 12, 31);

Future<DateTime?> pickAppDate({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final now = DateTime.now();

  final effectiveFirst = firstDate ?? appDateFirst();
  final effectiveLast = lastDate ?? appDateLast();

  // Clamp rather than let showDatePicker assert if a stored date sits outside
  // the range (e.g. an old record opened for editing).
  var effectiveInitial = initialDate ?? now;
  if (effectiveInitial.isBefore(effectiveFirst)) {
    effectiveInitial = effectiveFirst;
  } else if (effectiveInitial.isAfter(effectiveLast)) {
    effectiveInitial = effectiveLast;
  }

  return showDatePicker(
    context: context,
    initialDate: effectiveInitial,
    firstDate: effectiveFirst,
    lastDate: effectiveLast,
    builder: (context, child) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      if (!isDark) return child!;
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: AppTheme.primaryDark,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppTheme.surfaceDark,
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Range equivalent of [pickAppDate], used by the report filters.
///
/// Kept separate because `showDateRangePicker` is a full-screen surface rather
/// than a dialog, so it needs its own dark-mode treatment.
Future<DateTimeRange?> pickAppDateRange({
  required BuildContext context,
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final effectiveFirst = firstDate ?? appDateFirst();
  final effectiveLast = lastDate ?? appDateLast();

  // Drop an out-of-range initial range rather than letting the picker assert.
  DateTimeRange? effectiveInitial = initialRange;
  if (effectiveInitial != null &&
      (effectiveInitial.start.isBefore(effectiveFirst) ||
          effectiveInitial.end.isAfter(effectiveLast))) {
    effectiveInitial = null;
  }

  return showDateRangePicker(
    context: context,
    firstDate: effectiveFirst,
    lastDate: effectiveLast,
    initialDateRange: effectiveInitial,
    builder: (context, child) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      if (!isDark) return child!;
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryDark,
            onPrimary: Colors.white,
            surface: AppTheme.surfaceDark,
          ),
          scaffoldBackgroundColor: AppTheme.surfaceDark,
        ),
        child: child!,
      );
    },
  );
}
