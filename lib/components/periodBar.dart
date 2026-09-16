import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/datePicker.dart';
import 'package:vyaparsetu/helpers/formatters.dart';

/// Chooses a report period. Null means the current financial year, which the
/// server uses by default.
class PeriodBar extends StatelessWidget {
  final DateTimeRange? range;
  final int fyStartMonth;
  final ValueChanged<DateTimeRange?> onChanged;

  const PeriodBar({
    super.key,
    required this.range,
    required this.fyStartMonth,
    required this.onChanged,
  });

  Future<void> _choose(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fyStart = DateTime(
      now.month >= fyStartMonth ? now.year : now.year - 1,
      fyStartMonth,
    );

    final presets = <(String, DateTimeRange?)>[
      ('period_this_fy'.tr(), null),
      ('period_today'.tr(), DateTimeRange(start: today, end: today)),
      ('period_this_month'.tr(), DateTimeRange(start: DateTime(now.year, now.month), end: today)),
      (
        'period_last_month'.tr(),
        DateTimeRange(
          start: DateTime(now.year, now.month - 1),
          end: DateTime(now.year, now.month, 0),
        ),
      ),
      (
        'period_last_fy'.tr(),
        DateTimeRange(
          start: DateTime(fyStart.year - 1, fyStartMonth),
          end: fyStart.subtract(const Duration(days: 1)),
        ),
      ),
    ];

    final choice = await showModalBottomSheet<(bool, DateTimeRange?)>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                0,
                AppTheme.spaceLg,
                AppTheme.spaceSm,
              ),
              child: Text('choose_period'.tr(), style: sheetContext.text.titleLarge),
            ),
            for (final (label, preset) in presets)
              ListTile(
                title: Text(label),
                onTap: () => Navigator.of(sheetContext).pop((true, preset)),
              ),
            ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: Text('period_custom'.tr()),
              onTap: () => Navigator.of(sheetContext).pop((false, null)),
            ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    final (isPreset, preset) = choice;
    if (isPreset) {
      onChanged(preset);
      return;
    }
    final custom = await pickAppDateRange(
      context: context,
      initialRange: range,
      lastDate: today,
    );
    if (custom != null) onChanged(custom);
  }

  @override
  Widget build(BuildContext context) {
    final current = range;
    final label = current == null
        ? 'period_this_fy'.tr()
        : current.start == current.end
        ? Formatters.formatDate(current.start)
        : '${Formatters.formatDate(current.start)} – ${Formatters.formatDate(current.end)}';

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      onTap: () => _choose(context),
      child: Row(
        children: [
          Icon(Icons.date_range_outlined, size: 20, color: context.colors.primary),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(child: Text(label, style: context.text.titleSmall)),
          Icon(Icons.expand_more_rounded, color: context.colors.muted),
        ],
      ),
    );
  }
}
