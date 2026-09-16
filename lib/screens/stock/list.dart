import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/pagedList.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/stock/detail.dart';
import 'package:vyaparsetu/screens/stock/form.dart';
import 'package:vyaparsetu/types/stockAdjustment.dart';

class StockAdjustmentListScreen extends StatefulWidget {
  const StockAdjustmentListScreen({super.key});

  @override
  State<StockAdjustmentListScreen> createState() => _StockAdjustmentListScreenState();
}

class _StockAdjustmentListScreenState extends State<StockAdjustmentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().stock.fetchAdjustments(refresh: true),
    );
  }

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final stock = core.stock;
    scheduleReload(stock.list.needsReload, () => stock.fetchAdjustments(refresh: true));
    final canAdjust = core.can(MemberRole.accountant);

    return Scaffold(
      appBar: AppBar(title: Text('stock_adjustments'.tr())),
      floatingActionButton: canAdjust
          ? FloatingActionButton.extended(
              heroTag: 'new-adjustment',
              onPressed: () => _push(const StockAdjustmentFormScreen()),
              icon: const Icon(Icons.tune_rounded),
              label: Text('adjust_stock'.tr()),
            )
          : null,
      body: PagedListView<StockAdjustment>(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceLg,
          AppTheme.spaceSm,
          AppTheme.spaceLg,
          AppTheme.fabClearance,
        ),
        items: stock.list.items,
        isLoading: stock.list.isLoading,
        isLoadingMore: stock.list.isLoadingMore,
        hasMore: stock.list.data.hasMore,
        error: stock.list.error,
        onRefresh: () => stock.fetchAdjustments(refresh: true),
        onLoadMore: stock.loadMore,
        emptyState: EmptyState(
          icon: Icons.tune_rounded,
          title: 'no_adjustments_yet'.tr(),
          description: 'adjustments_hint'.tr(),
          buttonText: canAdjust ? 'adjust_stock'.tr() : null,
          onButtonPressed: canAdjust ? () => _push(const StockAdjustmentFormScreen()) : null,
        ),
        itemBuilder: (context, adjustment) => AppCard(
          onTap: () => _push(StockAdjustmentDetailScreen(adjustmentId: adjustment.id)),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: context.colors.inkSecondary),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(adjustment.reason.displayName, style: context.text.titleSmall),
                    Text(
                      [
                        Formatters.formatDate(adjustment.adjustmentDate),
                        'items_count'.tr(namedArgs: {'count': '${adjustment.lineCount}'}),
                        ?adjustment.notes,
                      ].join(' · '),
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (adjustment.isCancelled)
                StatusChip.forRecord(adjustment.status)
              else
                Icon(Icons.chevron_right_rounded, color: context.colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
