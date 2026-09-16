import 'package:flutter/material.dart';
import 'package:vyaparsetu/global/themes.dart';

/// "Label ........ value" line for detail screens and totals.
///
/// Renders nothing when there is no value, so optional details can be listed
/// without checks.
class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool emphasize;
  final IconData? icon;

  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.emphasize = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (valueWidget == null && (value == null || value!.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    final labelStyle = emphasize ? context.text.titleSmall : context.text.bodyMedium;
    final valueStyle = emphasize
        ? context.text.titleMedium
        : context.text.bodyLarge?.copyWith(fontSize: 14);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: context.colors.muted),
            const SizedBox(width: AppTheme.spaceSm),
          ],
          Expanded(flex: 2, child: Text(label, style: labelStyle)),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(value!, style: valueStyle, textAlign: TextAlign.right),
            ),
          ),
        ],
      ),
    );
  }
}
