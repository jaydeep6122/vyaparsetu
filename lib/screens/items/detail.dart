import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/appButton.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/infoRow.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/screens/items/form.dart';
import 'package:vyaparsetu/screens/stock/form.dart';
import 'package:vyaparsetu/types/item.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      context.read<Core>().item.getItem(widget.itemId, refresh: true);

  void _push(Widget screen) => Navigator.of(context).push(getPageRoute(screen));

  Future<void> _toggleArchive(Item item) async {
    final items = context.read<Core>().item;
    final saved = await items.setArchived(item.id, archived: !item.isArchived);
    if (saved == null) {
      showErrorToast(items.error ?? 'error_generic'.tr());
    } else {
      showSuccessToast(saved.isArchived ? 'item_archived'.tr() : 'item_restored'.tr());
    }
  }

  String? _price(double? price, bool includesTax) {
    if (price == null) return null;
    final note = includesTax ? 'incl_tax'.tr() : 'excl_tax'.tr();
    return '${Formatters.formatCurrency(price)} ($note)';
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final state = core.item.detail(widget.itemId);
    scheduleReload(state.needsReload, _refresh);
    final item = state.value;
    final isAccountant = core.can(MemberRole.accountant);

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.name ?? 'item'.tr()),
        actions: [
          if (item != null)
            IconButton(
              tooltip: 'edit'.tr(),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _push(ItemFormScreen(item: item)),
            ),
          if (item != null && isAccountant)
            PopupMenuButton<String>(
              onSelected: (_) => _toggleArchive(item),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Text(item.isArchived ? 'restore'.tr() : 'archive'.tr()),
                ),
              ],
            ),
        ],
      ),
      body: LoadStateBody<Item>(
        state: state,
        onRetry: _refresh,
        builder: (context, item) => RefreshIndicator(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: context.text.titleLarge),
                              Text(
                                [item.itemType.displayName, ?item.categoryName].join(' · '),
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (item.isArchived) StatusChip(label: 'archived'.tr()),
                        if (item.isLowStock)
                          StatusChip(label: 'low_stock'.tr(), tone: ChipTone.danger),
                      ],
                    ),
                    if (item.trackStock) ...[
                      const SizedBox(height: AppTheme.spaceLg),
                      Text('in_stock'.tr(), style: context.text.labelMedium),
                      Text(
                        Formatters.formatQuantity(item.quantityOnHand ?? 0, item.unitCode),
                        style: context.text.headlineSmall?.copyWith(
                          color: item.isLowStock ? context.colors.danger : null,
                        ),
                      ),
                      if (isAccountant) ...[
                        const SizedBox(height: AppTheme.spaceMd),
                        AppButton(
                          text: 'adjust_stock'.tr(),
                          icon: Icons.tune_rounded,
                          variant: AppButtonVariant.secondary,
                          compact: true,
                          onPressed: () => _push(StockAdjustmentFormScreen(item: item)),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              AppCard(
                child: Column(
                  children: [
                    InfoRow(label: 'sale_price'.tr(), value: _price(item.salePrice, item.priceIncludesTax)),
                    InfoRow(
                      label: 'purchase_price'.tr(),
                      value: _price(item.purchasePrice, item.priceIncludesTax),
                    ),
                    InfoRow(
                      label: 'gst_rate'.tr(),
                      value: item.taxRate == null
                          ? 'no_gst_rate'.tr()
                          : Formatters.formatPercent(item.taxRate!),
                    ),
                    if ((item.cessRate ?? 0) > 0)
                      InfoRow(label: 'cess'.tr(), value: Formatters.formatPercent(item.cessRate!)),
                    InfoRow(
                      label: item.itemType == ItemType.service ? 'sac_code'.tr() : 'hsn_code'.tr(),
                      value: item.hsnSac,
                    ),
                    InfoRow(label: 'unit'.tr(), value: item.unitCode),
                    InfoRow(label: 'sku'.tr(), value: item.sku),
                    InfoRow(label: 'barcode'.tr(), value: item.barcode),
                    if (item.trackStock)
                      InfoRow(
                        label: 'low_stock_alert'.tr(),
                        value: item.lowStockThreshold == null
                            ? null
                            : Formatters.formatQuantity(item.lowStockThreshold!, item.unitCode),
                      ),
                    if (item.trackStock && (item.openingStock ?? 0) > 0)
                      InfoRow(
                        label: 'opening_stock'.tr(),
                        value: Formatters.formatQuantity(item.openingStock!, item.unitCode),
                      ),
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
