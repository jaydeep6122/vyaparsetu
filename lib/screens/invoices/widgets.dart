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

  @override
  Widget build(BuildContext context) {
    final showDue = !invoice.isDraft &&
        !invoice.isCancelled &&
        invoice.paymentStatus == PaymentStatus.partiallyPaid;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      onTap: () => Navigator.of(context).push(
        getPageRoute(InvoiceDetailScreen(invoiceId: invoice.id)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.partyName.isEmpty ? 'walk_in_customer'.tr() : invoice.partyName,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (invoice.invoiceType != InvoiceType.sale) invoice.invoiceType.displayName,
                    invoice.invoiceNumber,
                    Formatters.formatDate(invoice.invoiceDate),
                  ].join(' · '),
                  style: context.text.bodySmall,
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
                  decoration: invoice.isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXs),
              if (showDue)
                Text(
                  'due_amount'.tr(namedArgs: {
                    'amount': Formatters.formatCurrency(invoice.outstanding),
                  }),
                  style: context.text.labelSmall?.copyWith(color: context.colors.warning),
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
