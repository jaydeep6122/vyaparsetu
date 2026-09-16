import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/amountDisplay.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/items/detail.dart';
import 'package:vyaparsetu/types/reports.dart';

/// Quantity and value in stock for every tracked item.
class StockSummaryScreen extends StatefulWidget {
  const StockSummaryScreen({super.key});

  @override
  State<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

class _StockSummaryScreenState extends State<StockSummaryScreen> {
  String _search = '';
  bool _lowOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => context.read<Core>().report.fetchStockSummary(refresh: true);

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final state = core.report.stockSummary;
    scheduleReload(state.needsReload, _refresh);

    return Scaffold(
      appBar: AppBar(title: Text('stock_summary'.tr())),
      body: LoadStateBody<StockSummary>(
        state: state,
        onRetry: _refresh,
        builder: (context, summary) {
          final needle = _search.toLowerCase();
          final rows = summary.items.where((row) {
            if (_lowOnly && !row.isLow) return false;
            if (needle.isEmpty) return true;
            return row.name.toLowerCase().contains(needle) ||
                (row.sku?.toLowerCase().contains(needle) ?? false);
          }).toList();
          final lowCount = summary.items.where((row) => row.isLow).length;

          return RefreshIndicator(
            onRefresh: _refresh,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('stock_value'.tr(), style: context.text.labelMedium),
                            AmountDisplay(amount: summary.totalValue, style: context.text.headlineSmall),
                            Text('stock_value_hint'.tr(), style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('items_count'.tr(namedArgs: {'count': '${summary.items.length}'}),
                              style: context.text.titleSmall),
                          if (lowCount > 0)
                            Text(
                              'low_stock_count'.tr(namedArgs: {'count': '$lowCount'}),
                              style: context.text.bodySmall?.copyWith(color: context.colors.danger),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                AppSearchBar(
                  hintText: 'search_items'.tr(),
                  initialValue: _search,
                  onChanged: (query) => setState(() => _search = query),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: Text('low_stock'.tr()),
                    selected: _lowOnly,
                    onSelected: (value) => setState(() => _lowOnly = value),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                if (rows.isEmpty)
                  EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: summary.items.isEmpty ? 'no_stock_items'.tr() : 'no_items_match'.tr(),
                    description: summary.items.isEmpty ? 'no_stock_items_hint'.tr() : null,
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (index, row) in rows.indexed) ...[
                          if (index > 0) const Divider(indent: AppTheme.spaceLg),
                          ListTile(
                            onTap: () => Navigator.of(context).push(
                              getPageRoute(ItemDetailScreen(itemId: row.id)),
                            ),
                            title: Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              [
                                ?row.sku,
                                if (row.averageCost != null)
                                  'avg_cost'.tr(namedArgs: {
                                    'amount': Formatters.formatCurrency(row.averageCost!),
                                  }),
                              ].join(' · '),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatQuantity(row.quantityOnHand, row.unitCode),
                                  style: context.text.titleSmall?.copyWith(
                                    color: row.isLow ? context.colors.danger : null,
                                  ),
                                ),
                                Text(Formatters.formatCurrency(row.stockValue), style: context.text.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
