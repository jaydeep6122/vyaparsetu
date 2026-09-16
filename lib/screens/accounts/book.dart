import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/periodBar.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/accounts/form.dart';
import 'package:vyaparsetu/screens/accounts/transfers.dart';
import 'package:vyaparsetu/screens/common/ledgerView.dart';
import 'package:vyaparsetu/types/account.dart';

/// Money in and out of one account with a running balance (accountants).
class AccountBookScreen extends StatefulWidget {
  final Account account;

  const AccountBookScreen({super.key, required this.account});

  @override
  State<AccountBookScreen> createState() => _AccountBookScreenState();
}

class _AccountBookScreenState extends State<AccountBookScreen> {
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<Core>().account.fetchBook(
      widget.account.id,
      from: _range?.start,
      to: _range?.end,
      refresh: true,
    );
  }

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final account = core.account.accounts.value
            ?.where((a) => a.id == widget.account.id)
            .firstOrNull ??
        widget.account;
    final book = core.account.book(account.id);
    if (book.needsReload) WidgetsBinding.instance.addPostFrameCallback((_) => _load());

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            tooltip: 'transfer_money'.tr(),
            icon: const Icon(Icons.compare_arrows_rounded),
            onPressed: () => _push(const TransferFormScreen()),
          ),
          if (core.can(MemberRole.admin))
            IconButton(
              tooltip: 'edit'.tr(),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _push(AccountFormScreen(account: account)),
            ),
        ],
      ),
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
              child: Row(
                children: [
                  Icon(
                    account.accountType == AccountType.cash
                        ? Icons.payments_outlined
                        : Icons.account_balance_outlined,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('current_balance'.tr(), style: context.text.labelMedium),
                        AmountDisplay(
                          amount: account.balance,
                          showMinus: true,
                          style: context.text.headlineSmall,
                        ),
                        Text(account.subtitle, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            PeriodBar(
              range: _range,
              fyStartMonth: core.business.selectedBusiness?.fyStartMonth ?? 4,
              onChanged: (range) {
                setState(() => _range = range);
                _load();
              },
            ),
            const SizedBox(height: AppTheme.spaceMd),
            LedgerView(state: book, isAccount: true, onRetry: _load),
          ],
        ),
      ),
    );
  }
}
