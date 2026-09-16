import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/sectionHeader.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/types/stockAdjustment.dart';

class StockAdjustmentDetailScreen extends StatefulWidget {
  final String adjustmentId;

  const StockAdjustmentDetailScreen({super.key, required this.adjustmentId});

  @override
  State<StockAdjustmentDetailScreen> createState() => _StockAdjustmentDetailScreenState();
}

class _StockAdjustmentDetailScreenState extends State<StockAdjustmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<Core>().stock.getAdjustment(widget.adjustmentId, refresh: true);

  Future<void> _cancel() async {
    final reason = await showReasonDialog(
      context,
      title: 'cancel_adjustment_title'.tr(),
      message: 'cancel_adjustment_message'.tr(),
      confirmText: 'cancel_adjustment'.tr(),
    );
    if (reason == null || !mounted) return;
    final stock = context.read<Core>().stock;
    final saved = await stock.cancelAdjustment(
      widget.adjustmentId,
      reason: reason.isEmpty ? null : reason,
    );
    if (saved == null) {
      showErrorToast(stock.error ?? 'error_generic'.tr());
    } else {
      showSuccessToast('adjustment_cancelled'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final state = core.stock.detail(widget.adjustmentId);
    final adjustment = state.value;

    return Scaffold(
      appBar: AppBar(
        title: Text('stock_adjustment'.tr()),
        actions: [
          if (adjustment != null && !adjustment.isCancelled && core.can(MemberRole.accountant))
            TextButton(onPressed: _cancel, child: Text('cancel_adjustment'.tr())),
        ],
      ),
      body: LoadStateBody<StockAdjustment>(
        state: state,
        onRetry: _refresh,
        builder: (context, adjustment) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(adjustment.reason.displayName, style: context.text.titleLarge),
                        ),
                        StatusChip.forRecord(adjustment.status),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    InfoRow(label: 'date'.tr(), value: Formatters.formatDate(adjustment.adjustmentDate)),
                    InfoRow(label: 'notes'.tr(), value: adjustment.notes),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              SectionHeader(title: 'items'.tr()),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (index, line) in adjustment.lines.indexed) ...[
                      if (index > 0) const Divider(indent: AppTheme.spaceLg),
                      ListTile(
                        title: Text(line.itemName ?? ''),
                        subtitle: line.unitCost == null
                            ? null
                            : Text('cost_per_unit_value'.tr(namedArgs: {
                                'amount': Formatters.formatCurrency(line.unitCost!),
                              })),
                        trailing: Text(
                          '${line.quantity > 0 ? '+' : '−'}${Formatters.formatQuantity(line.quantity.abs(), line.unitCode)}',
                          style: context.text.titleSmall?.copyWith(
                            color: line.quantity > 0 ? context.colors.success : context.colors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
