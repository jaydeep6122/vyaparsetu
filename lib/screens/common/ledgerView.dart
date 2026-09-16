import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/expenses/detail.dart';
import 'package:vyaparsetu/screens/invoices/detail.dart';
import 'package:vyaparsetu/screens/payments/detail.dart';
import 'package:vyaparsetu/types/reports.dart';

/// A party ledger or account book: summary and entries with running balance.
class LedgerView extends StatelessWidget {
  final LoadState<Ledger> state;

  /// Account books count money in and out; party ledgers debits and credits.
  final bool isAccount;
  final Future<void> Function() onRetry;

  const LedgerView({
    super.key,
    required this.state,
    required this.isAccount,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ledger = state.value;
    if (ledger == null) {
      return SizedBox(
        height: 280,
        child: state.error != null
            ? AppErrorWidget(errorMessage: state.error!, onRetry: onRetry)
            : const LoadingIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${Formatters.formatDate(ledger.period.from)} – ${Formatters.formatDate(ledger.period.to)}',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              InfoRow(
                label: 'opening_balance'.tr(),
                valueWidget: _BalanceText(balance: ledger.openingBalance, isAccount: isAccount),
              ),
              InfoRow(
                label: isAccount ? 'money_in'.tr() : 'ledger_total_debit'.tr(),
                valueWidget: AmountDisplay(amount: ledger.totalDebitOrIn, style: context.text.titleSmall),
              ),
              InfoRow(
                label: isAccount ? 'money_out'.tr() : 'ledger_total_credit'.tr(),
                valueWidget: AmountDisplay(amount: ledger.totalCreditOrOut, style: context.text.titleSmall),
              ),
              const Divider(height: AppTheme.spaceLg),
              InfoRow(
                label: 'closing_balance'.tr(),
                emphasize: true,
                valueWidget: _BalanceText(
                  balance: ledger.closingBalance,
                  isAccount: isAccount,
                  emphasize: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        if (ledger.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.space2xl),
            child: Text(
              'no_entries_in_period'.tr(),
              style: context.text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (index, entry) in ledger.entries.indexed) ...[
                  if (index > 0) const Divider(indent: AppTheme.spaceLg),
                  _EntryTile(entry: entry, isAccount: isAccount),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _BalanceText extends StatelessWidget {
  final double balance;
  final bool isAccount;
  final bool emphasize;

  const _BalanceText({required this.balance, required this.isAccount, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final style = emphasize ? context.text.titleMedium : context.text.titleSmall;
    if (isAccount) return AmountDisplay(amount: balance, showMinus: true, style: style);

    final suffix = balance > 0.004
        ? 'ledger_to_get'.tr()
        : balance < -0.004
        ? 'ledger_to_give'.tr()
        : '';
    return Text(
      '${Formatters.formatCurrency(balance.abs())} $suffix'.trim(),
      style: style?.copyWith(
        color: balance > 0.004
            ? context.colors.success
            : balance < -0.004
            ? context.colors.danger
            : null,
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final LedgerEntry entry;
  final bool isAccount;

  const _EntryTile({required this.entry, required this.isAccount});

  Widget? get _destination => switch (entry.sourceType) {
    LedgerSource.invoice => InvoiceDetailScreen(invoiceId: entry.sourceId),
    LedgerSource.payment => PaymentDetailScreen(paymentId: entry.sourceId),
    LedgerSource.expense => ExpenseDetailScreen(expenseId: entry.sourceId),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isIncrease = isAccount ? entry.amount >= 0 : entry.debit > 0;
    final amount = isAccount ? entry.amount.abs() : (entry.debit > 0 ? entry.debit : entry.credit);
    final destination = _destination;

    return ListTile(
      onTap: destination == null
          ? null
          : () => Navigator.of(context).push(getPageRoute(destination)),
      title: Text(
        entry.narration?.trim().isNotEmpty == true
            ? entry.narration!
            : entry.sourceType.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${Formatters.formatDate(entry.entryDate)} · ${entry.sourceType.displayName}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isIncrease ? '+' : '−'} ${Formatters.formatCurrency(amount)}',
            style: context.text.titleSmall?.copyWith(
              color: isAccount
                  ? (isIncrease ? colors.success : colors.danger)
                  : (isIncrease ? colors.ink : colors.success),
            ),
          ),
          Text(
            'balance_after'.tr(namedArgs: {
              'amount': isAccount
                  ? Formatters.formatCurrency(entry.balance)
                  : Formatters.formatCurrency(entry.balance.abs()),
            }),
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}
