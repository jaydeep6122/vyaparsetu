import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/periodBar.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/types/reports.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<Core>().report.fetchProfitLoss(from: _range?.start, to: _range?.end);
  }

  Widget _row(BuildContext context, String label, double amount, {bool emphasize = false, bool subtract = false}) {
    final style = emphasize ? context.text.titleMedium : context.text.titleSmall;
    return InfoRow(
      label: label,
      emphasize: emphasize,
      valueWidget: subtract
          ? Text('− ${AmountDisplay(amount: amount).amount == 0 ? '₹0' : ''}', style: style)
          : AmountDisplay(amount: amount, showMinus: true, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();

    return Scaffold(
      appBar: AppBar(title: Text('report_profit_loss'.tr())),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLg,
            AppTheme.spaceSm,
            AppTheme.spaceLg,
            AppTheme.space3xl,
          ),
          children: [
            PeriodBar(
              range: _range,
              fyStartMonth: core.business.selectedBusiness?.fyStartMonth ?? 4,
              onChanged: (range) {
                setState(() => _range = range);
                _load();
              },
            ),
            const SizedBox(height: AppTheme.spaceMd),
            LoadStateSection<ProfitLoss>(
              state: core.report.profitLoss,
              onRetry: _load,
              builder: (context, report) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    color: report.netProfit >= 0 ? context.colors.successSoft : context.colors.dangerSoft,
                    borderColor: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.netProfit >= 0 ? 'net_profit'.tr() : 'net_loss'.tr(),
                          style: context.text.labelMedium,
                        ),
                        AmountDisplay(
                          amount: report.netProfit,
                          tone: AmountTone.bySign,
                          style: context.text.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  AppCard(
                    child: Column(
                      children: [
                        _row(context, 'net_sales'.tr(), report.netSales),
                        _row(context, 'charges_recovered'.tr(), report.chargesRecovered),
                        const Divider(),
                        _row(context, 'revenue'.tr(), report.revenue, emphasize: true),
                        _row(context, 'cost_of_goods_sold'.tr(), -report.costOfGoodsSold),
                        _row(context, 'non_stock_purchases'.tr(), -report.nonStockPurchases),
                        _row(context, 'freight_and_charges'.tr(), -report.freightAndCharges),
                        const Divider(),
                        _row(context, 'gross_profit'.tr(), report.grossProfit, emphasize: true),
                        _row(context, 'expenses'.tr(), -report.expenses),
                        const Divider(),
                        _row(context, 'net_profit'.tr(), report.netProfit, emphasize: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text('profit_loss_note'.tr(), style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
