import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/periodBar.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/types/reports.dart';

class GstSummaryScreen extends StatefulWidget {
  const GstSummaryScreen({super.key});

  @override
  State<GstSummaryScreen> createState() => _GstSummaryScreenState();
}

class _GstSummaryScreenState extends State<GstSummaryScreen> {
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<Core>().report.fetchGstSummary(from: _range?.start, to: _range?.end);
  }

  InfoRow _money(String label, double amount, {bool emphasize = false}) => InfoRow(
    label: label,
    emphasize: emphasize,
    value: Formatters.formatCurrency(amount),
  );

  Widget _taxCard(BuildContext context, String title, TaxTotals totals, List<Widget> extra) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.text.titleSmall),
          const SizedBox(height: AppTheme.spaceSm),
          _money('taxable_value'.tr(), totals.taxable),
          _money('cgst'.tr(), totals.cgst),
          _money('sgst'.tr(), totals.sgst),
          _money('igst'.tr(), totals.igst),
          if (totals.cess > 0) _money('cess'.tr(), totals.cess),
          ...extra,
          const Divider(),
          _money('total_tax'.tr(), totals.totalTax, emphasize: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();

    return Scaffold(
      appBar: AppBar(title: Text('report_gst_summary'.tr())),
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
            LoadStateSection<GstSummary>(
              state: core.report.gstSummary,
              onRetry: _load,
              builder: (context, report) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    color: context.colors.primarySoft,
                    borderColor: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.netTaxPayable >= 0 ? 'net_gst_payable'.tr() : 'net_gst_credit'.tr(),
                          style: context.text.labelMedium,
                        ),
                        AmountDisplay(
                          amount: report.netTaxPayable.abs(),
                          style: context.text.headlineMedium,
                        ),
                        Text('net_gst_hint'.tr(), style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  _taxCard(context, 'output_tax'.tr(), report.output, [
                    if (report.outputChargesTax > 0) _money('tax_on_charges'.tr(), report.outputChargesTax),
                    _money('b2b_taxable'.tr(), report.b2bTaxable),
                    _money('b2c_taxable'.tr(), report.b2cTaxable),
                  ]),
                  const SizedBox(height: AppTheme.spaceMd),
                  _taxCard(context, 'input_tax'.tr(), report.input, const []),
                  if (report.nonGstSales > 0) ...[
                    const SizedBox(height: AppTheme.spaceMd),
                    AppCard(child: _money('non_gst_sales'.tr(), report.nonGstSales)),
                  ],
                  if (report.hsnSummary.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceLg),
                    SectionHeader(title: 'hsn_summary'.tr()),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (index, row) in report.hsnSummary.indexed) ...[
                            if (index > 0) const Divider(indent: AppTheme.spaceLg),
                            ListTile(
                              title: Text(
                                '${row.hsnSac ?? 'hsn_not_set'.tr()} · ${Formatters.formatPercent(row.taxRate)}',
                              ),
                              subtitle: Text(
                                '${Formatters.formatQuantity(row.quantity, row.unitCode)} · '
                                '${'tax_label'.tr()} ${Formatters.formatCurrency(row.cgst + row.sgst + row.igst + row.cess)}',
                              ),
                              trailing: Text(
                                Formatters.formatCurrency(row.taxableValue),
                                style: context.text.titleSmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceMd),
                  Text('gst_summary_note'.tr(), style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
