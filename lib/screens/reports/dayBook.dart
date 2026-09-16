import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/datePicker.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/expenses/detail.dart';
import 'package:vyaparsetu/screens/invoices/detail.dart';
import 'package:vyaparsetu/screens/payments/detail.dart';
import 'package:vyaparsetu/types/reports.dart';

/// Everything recorded on one day.
class DayBookScreen extends StatefulWidget {
  const DayBookScreen({super.key});

  @override
  State<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends State<DayBookScreen> {
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<Core>().report.fetchDayBook(_date);
  }

  void _setDate(DateTime date) {
    setState(() => _date = date);
    _load();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year && _date.month == now.month && _date.day == now.day;
  }

  String _typeLabel(DayBookEntry entry) => switch (entry.kind) {
    'invoice' => InvoiceType.fromString(entry.type).displayName,
    'payment' => PaymentDirection.fromString(entry.type).displayName,
    'expense' => 'expense'.tr(),
    _ => 'transfer'.tr(),
  };

  (IconData, ChipTone) _look(DayBookEntry entry) => switch (entry.kind) {
    'invoice' => (Icons.receipt_long_outlined, ChipTone.primary),
    'payment' => entry.type == 'in'
        ? (Icons.call_received_rounded, ChipTone.success)
        : (Icons.call_made_rounded, ChipTone.danger),
    'expense' => (Icons.account_balance_wallet_outlined, ChipTone.warning),
    _ => (Icons.compare_arrows_rounded, ChipTone.neutral),
  };

  Widget? _destination(DayBookEntry entry) => switch (entry.kind) {
    'invoice' => InvoiceDetailScreen(invoiceId: entry.id),
    'payment' => PaymentDetailScreen(paymentId: entry.id),
    'expense' => ExpenseDetailScreen(expenseId: entry.id),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();

    return Scaffold(
      appBar: AppBar(title: Text('report_day_book'.tr())),
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
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'previous_day'.tr(),
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => _setDate(_date.subtract(const Duration(days: 1))),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await pickAppDate(
                          context: context,
                          initialDate: _date,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) _setDate(picked);
                      },
                      child: Text(
                        _isToday ? 'today_with_date'.tr(namedArgs: {'date': Formatters.formatDate(_date)}) : Formatters.formatDate(_date),
                        textAlign: TextAlign.center,
                        style: context.text.titleSmall,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'next_day'.tr(),
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _isToday ? null : () => _setDate(_date.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            LoadStateSection<DayBook>(
              state: core.report.dayBook,
              onRetry: _load,
              builder: (context, book) {
                final active = book.entries.where((e) => e.status != 'cancelled');
                double sum(bool Function(DayBookEntry) test) =>
                    active.where(test).fold(0.0, (total, e) => total + e.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'sales'.tr(),
                            value: Formatters.formatCurrency(sum((e) => e.kind == 'invoice' && e.type == 'sale')),
                          ),
                          InfoRow(
                            label: 'purchases'.tr(),
                            value: Formatters.formatCurrency(sum((e) => e.kind == 'invoice' && e.type == 'purchase')),
                          ),
                          InfoRow(
                            label: 'money_received'.tr(),
                            value: Formatters.formatCurrency(sum((e) => e.kind == 'payment' && e.type == 'in')),
                          ),
                          InfoRow(
                            label: 'money_paid'.tr(),
                            value: Formatters.formatCurrency(sum((e) => e.kind == 'payment' && e.type == 'out')),
                          ),
                          InfoRow(
                            label: 'expenses'.tr(),
                            value: Formatters.formatCurrency(sum((e) => e.kind == 'expense')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    if (book.entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.space2xl),
                        child: Text(
                          'nothing_recorded_on_day'.tr(),
                          style: context.text.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (index, entry) in book.entries.indexed) ...[
                              if (index > 0) const Divider(indent: 72),
                              Builder(builder: (context) {
                                final (icon, tone) = _look(entry);
                                final (background, foreground) = toneColors(context, tone);
                                final destination = _destination(entry);
                                final cancelled = entry.status == 'cancelled';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: background,
                                    child: Icon(icon, color: foreground, size: 20),
                                  ),
                                  title: Text(
                                    [_typeLabel(entry), ?entry.number].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: entry.party == null ? null : Text(entry.party!),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      AmountDisplay(
                                        amount: entry.amount,
                                        style: context.text.titleSmall?.copyWith(
                                          decoration: cancelled ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      if (cancelled)
                                        Text('record_status_cancelled'.tr(), style: context.text.labelSmall),
                                    ],
                                  ),
                                  onTap: destination == null
                                      ? null
                                      : () => Navigator.of(context).push(getPageRoute(destination)),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
