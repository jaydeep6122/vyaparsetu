import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/accounts/list.dart';
import 'package:vyaparsetu/screens/reports/dayBook.dart';
import 'package:vyaparsetu/screens/reports/gstSummary.dart';
import 'package:vyaparsetu/screens/reports/outstanding.dart';
import 'package:vyaparsetu/screens/reports/profitLoss.dart';
import 'package:vyaparsetu/screens/reports/stockSummary.dart';

class ReportCenterScreen extends StatelessWidget {
  const ReportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      (Icons.call_received_rounded, ChipTone.success, 'report_receivables', 'report_receivables_hint',
          const OutstandingScreen(type: OutstandingType.receivable)),
      (Icons.call_made_rounded, ChipTone.danger, 'report_payables', 'report_payables_hint',
          const OutstandingScreen(type: OutstandingType.payable)),
      (Icons.trending_up_rounded, ChipTone.primary, 'report_profit_loss', 'report_profit_loss_hint',
          const ProfitLossScreen()),
      (Icons.receipt_outlined, ChipTone.info, 'report_gst_summary', 'report_gst_summary_hint',
          const GstSummaryScreen()),
      (Icons.today_outlined, ChipTone.warning, 'report_day_book', 'report_day_book_hint',
          const DayBookScreen()),
      (Icons.inventory_outlined, ChipTone.neutral, 'stock_summary', 'report_stock_summary_hint',
          const StockSummaryScreen()),
      (Icons.account_balance_outlined, ChipTone.info, 'cash_and_bank', 'report_cash_bank_hint',
          const AccountListScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('reports'.tr())),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        itemCount: reports.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceSm),
        itemBuilder: (context, index) {
          if (index == reports.length) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Text(
                'party_ledger_tip'.tr(),
                style: context.text.bodySmall,
                textAlign: TextAlign.center,
              ),
            );
          }
          final (icon, tone, title, hint, screen) = reports[index];
          final (background, foreground) = toneColors(context, tone);
          return AppCard(
            onTap: () => Navigator.of(context).push(getPageRoute(screen)),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: foreground),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.tr(), style: context.text.titleSmall),
                      Text(hint.tr(), style: context.text.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.colors.muted),
              ],
            ),
          );
        },
      ),
    );
  }
}
