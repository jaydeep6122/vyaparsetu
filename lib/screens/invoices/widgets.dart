import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/invoices/detail.dart';
import 'package:vyaparsetu/types/invoice.dart';

/// One bill in a list: party, number and date, total and status.
class InvoiceTile extends StatelessWidget {
  final Invoice invoice;

  const InvoiceTile({super.key, required this.invoice});

  IconData _getIcon() {
    switch (invoice.invoiceType) {
      case InvoiceType.sale:
        return Icons.receipt_long_rounded;
      case InvoiceType.purchase:
        return Icons.shopping_bag_outlined;
      case InvoiceType.saleReturn:
      case InvoiceType.purchaseReturn:
        return Icons.assignment_return_outlined;
    }
  }

  Color _getColor(BuildContext context) {
    switch (invoice.invoiceType) {
      case InvoiceType.sale:
        return context.colors.primary;
      case InvoiceType.purchase:
        return context.colors.info;
      case InvoiceType.saleReturn:
      case InvoiceType.purchaseReturn:
        return context.colors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDue =
        !invoice.isDraft &&
        !invoice.isCancelled &&
        invoice.paymentStatus == PaymentStatus.partiallyPaid;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getColor(context);
    
    final bgColor = isDark ? context.colors.surfaceAlt : color.withValues(alpha: 0.1);
    final iconColor = isDark ? color.withValues(alpha: 0.8) : color;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      onTap: () => Navigator.of(
        context,
      ).push(getPageRoute(InvoiceDetailScreen(invoiceId: invoice.id))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), color: iconColor, size: 20),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.partyName.isEmpty
                      ? 'walk_in_customer'.tr()
                      : invoice.partyName,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (invoice.invoiceType != InvoiceType.sale)
                      invoice.invoiceType.displayName,
                    invoice.invoiceNumber,
                    Formatters.formatDate(invoice.invoiceDate),
                  ].join(' · '),
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountDisplay(
                amount: invoice.totalAmount,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: invoice.isCancelled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXs),
              if (showDue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? context.colors.surfaceAlt : context.colors.warningSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    'due_amount'.tr(
                      namedArgs: {
                        'amount': Formatters.formatCurrency(
                          invoice.outstanding,
                        ),
                      },
                    ),
                    style: context.text.labelSmall?.copyWith(
                      color: isDark ? context.colors.warning.withValues(alpha: 0.8) : context.colors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                StatusChip.forInvoice(invoice),
            ],
          ),
        ],
      ),
    );
  }
}
