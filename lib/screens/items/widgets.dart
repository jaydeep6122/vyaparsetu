import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vyaparsetu/components/appCard.dart';
import 'package:vyaparsetu/components/statusChip.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/items/detail.dart';
import 'package:vyaparsetu/types/item.dart';

class ItemTile extends StatelessWidget {
  final Item item;

  const ItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLg,
        vertical: AppTheme.spaceMd,
      ),
      onTap: () => Navigator.of(context).push(
        getPageRoute(ItemDetailScreen(itemId: item.id)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              item.trackStock ? Icons.inventory_2_outlined : Icons.design_services_outlined,
              size: 20,
              color: colors.inkSecondary,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        [
                          ?item.categoryName,
                          if (item.hsnSac != null) 'HSN ${item.hsnSac}',
                          ?item.sku,
                        ].join(' · ').ifEmpty(item.itemType.displayName),
                        style: context.text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isArchived) ...[
                      const SizedBox(width: AppTheme.spaceSm),
                      StatusChip(label: 'archived'.tr()),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.salePrice != null)
                Text(Formatters.formatCurrency(item.salePrice!), style: context.text.titleSmall),
              if (item.trackStock)
                Text(
                  Formatters.formatQuantity(item.quantityOnHand ?? 0, item.unitCode),
                  style: context.text.bodySmall?.copyWith(
                    color: item.isLowStock ? colors.danger : null,
                    fontWeight: item.isLowStock ? FontWeight.w600 : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
