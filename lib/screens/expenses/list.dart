import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/pagedList.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/expenses/detail.dart';
import 'package:vyaparsetu/screens/expenses/form.dart';
import 'package:vyaparsetu/types/expense.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().expense.fetchExpenses(),
    );
  }

  void _add() => Navigator.of(context).push(getPageRoute(const ExpenseFormScreen()));

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final expenses = core.expense;
    scheduleReload(expenses.list.needsReload, () => expenses.fetchExpenses(refresh: true));

    return Scaffold(
      appBar: AppBar(title: Text('expenses'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-expense',
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text('add_expense'.tr()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              0,
              AppTheme.spaceLg,
              AppTheme.spaceSm,
            ),
            child: AppSearchBar(
              hintText: 'search_expenses'.tr(),
              initialValue: expenses.search,
              onChanged: (query) => expenses.setFilters(search: query),
            ),
          ),
          Expanded(
            child: PagedListView<Expense>(
              items: expenses.list.items,
              isLoading: expenses.list.isLoading,
              isLoadingMore: expenses.list.isLoadingMore,
              hasMore: expenses.list.data.hasMore,
              error: expenses.list.error,
              onRefresh: () => expenses.fetchExpenses(refresh: true),
              onLoadMore: expenses.loadMore,
              emptyState: EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'no_expenses_yet'.tr(),
                description: 'no_expenses_yet_hint'.tr(),
                buttonText: 'add_expense'.tr(),
                onButtonPressed: _add,
              ),
              itemBuilder: (context, expense) => AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLg,
                  vertical: AppTheme.spaceMd,
                ),
                onTap: () => Navigator.of(context).push(
                  getPageRoute(ExpenseDetailScreen(expenseId: expense.id)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.categoryName ?? 'uncategorised'.tr(),
                            style: context.text.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              ?expense.partyName,
                              expense.expenseNumber,
                              Formatters.formatDate(expense.expenseDate),
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
                          amount: expense.totalAmount,
                          style: context.text.titleSmall?.copyWith(
                            decoration: expense.isCancelled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXs),
                        expense.isCancelled
                            ? StatusChip.forRecord(expense.status)
                            : StatusChip.forPayment(expense.paymentStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
