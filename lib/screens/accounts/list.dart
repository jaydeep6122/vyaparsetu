import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/components/summaryCard.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/accounts/book.dart';
import 'package:vyaparsetu/screens/accounts/form.dart';
import 'package:vyaparsetu/screens/accounts/transfers.dart';
import 'package:vyaparsetu/types/account.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => context.read<Core>().account.fetchAccounts(refresh: true);

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final state = core.account.accounts;
    scheduleReload(state.needsReload, _refresh);
    final isAccountant = core.can(MemberRole.accountant);
    final isAdmin = core.can(MemberRole.admin);

    VoidCallback? openFor(Account account) {
      if (isAccountant) return () => _push(AccountBookScreen(account: account));
      if (isAdmin) return () => _push(AccountFormScreen(account: account));
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('cash_and_bank'.tr()),
        actions: [
          if (isAccountant)
            IconButton(
              tooltip: 'transfer_money'.tr(),
              icon: const Icon(Icons.compare_arrows_rounded),
              onPressed: () => _push(const TransferFormScreen()),
            ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'add-account',
              onPressed: () => _push(const AccountFormScreen()),
              icon: const Icon(Icons.add_rounded),
              label: Text('add_account'.tr()),
            )
          : null,
      body: LoadStateBody<List<Account>>(
        state: state,
        onRetry: _refresh,
        builder: (context, accounts) {
          final active = accounts.where((a) => !a.isArchived).toList();
          final archived = accounts.where((a) => a.isArchived).toList();
          double total(AccountType type) => active
              .where((a) => a.accountType == type)
              .fold(0.0, (sum, account) => sum + account.balance);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceSm,
                AppTheme.spaceLg,
                AppTheme.fabClearance,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'cash_in_hand'.tr(),
                        value: Formatters.formatCurrency(total(AccountType.cash)),
                        icon: Icons.payments_outlined,
                        tone: ChipTone.success,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: SummaryCard(
                        title: 'in_bank'.tr(),
                        value: Formatters.formatCurrency(total(AccountType.bank)),
                        icon: Icons.account_balance_outlined,
                        tone: ChipTone.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceLg),
                for (final account in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                    child: _AccountTile(account: account, onTap: openFor(account)),
                  ),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceLg),
                  SectionHeader(title: 'archived'.tr()),
                  for (final account in archived)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                      child: _AccountTile(
                        account: account,
                        onTap: isAdmin ? () => _push(AccountFormScreen(account: account)) : null,
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const _AccountTile({required this.account, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCash = account.accountType == AccountType.cash;
    final (background, foreground) = toneColors(
      context,
      isCash ? ChipTone.success : ChipTone.info,
    );

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              isCash ? Icons.payments_outlined : Icons.account_balance_outlined,
              color: foreground,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.name,
                        style: context.text.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (account.isDefault) ...[
                      const SizedBox(width: AppTheme.spaceSm),
                      StatusChip(label: 'default'.tr(), tone: ChipTone.primary),
                    ],
                  ],
                ),
                Text(account.subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          AmountDisplay(amount: account.balance, showMinus: true, style: context.text.titleSmall),
        ],
      ),
    );
  }
}
