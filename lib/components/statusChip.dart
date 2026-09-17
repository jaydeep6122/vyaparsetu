import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/types/invoice.dart';

enum ChipTone { neutral, primary, success, warning, danger, info }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipTone tone;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.icon,
  });

  /// Cancelled, draft, overdue, or how much of the invoice is paid.
  factory StatusChip.forInvoice(Invoice invoice) {
    if (invoice.isCancelled) {
      return StatusChip(
        label: InvoiceStatus.cancelled.displayName,
        tone: ChipTone.danger,
      );
    }
    if (invoice.isDraft) {
      return StatusChip(label: InvoiceStatus.draft.displayName);
    }
    if (invoice.isOverdue) {
      return StatusChip(label: 'status_overdue'.tr(), tone: ChipTone.danger);
    }
    return StatusChip.forPayment(invoice.paymentStatus);
  }

  factory StatusChip.forPayment(PaymentStatus status) {
    return StatusChip(
      label: status.displayName,
      tone: switch (status) {
        PaymentStatus.paid => ChipTone.success,
        PaymentStatus.partiallyPaid => ChipTone.warning,
        PaymentStatus.unpaid => ChipTone.info,
      },
    );
  }

  factory StatusChip.forRecord(RecordStatus status) {
    return StatusChip(
      label: status.displayName,
      tone: status == RecordStatus.cancelled ? ChipTone.danger : ChipTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color bg(Color normal) => isDark ? colors.surfaceAlt : normal;
    Color fg(Color normal) => isDark ? normal.withValues(alpha: 0.8) : normal;

    final (Color background, Color foreground) = switch (tone) {
      ChipTone.neutral => (colors.surfaceAlt, colors.inkSecondary),
      ChipTone.primary => (bg(colors.primarySoft), fg(colors.primary)),
      ChipTone.success => (bg(colors.successSoft), fg(colors.success)),
      ChipTone.warning => (bg(colors.warningSoft), fg(colors.warning)),
      ChipTone.danger => (bg(colors.dangerSoft), fg(colors.danger)),
      ChipTone.info => (bg(colors.infoSoft), fg(colors.info)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: foreground,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Foreground and soft background for a tone, for icons and badges.
(Color background, Color foreground) toneColors(BuildContext context, ChipTone tone) {
  final colors = context.colors;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  Color bg(Color normal) => isDark ? colors.surfaceAlt : normal;
  Color fg(Color normal) => isDark ? normal.withValues(alpha: 0.8) : normal;

  return switch (tone) {
    ChipTone.neutral => (colors.surfaceAlt, colors.inkSecondary),
    ChipTone.primary => (bg(colors.primarySoft), fg(colors.primary)),
    ChipTone.success => (bg(colors.successSoft), fg(colors.success)),
    ChipTone.warning => (bg(colors.warningSoft), fg(colors.warning)),
    ChipTone.danger => (bg(colors.dangerSoft), fg(colors.danger)),
    ChipTone.info => (bg(colors.infoSoft), fg(colors.info)),
  };
}
