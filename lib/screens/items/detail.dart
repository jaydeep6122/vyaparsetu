import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/types/itemQuantitySummary.dart';
import 'package:vyaparsetu/components/confirmationDialog.dart';
import 'package:vyaparsetu/helpers/formatters.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/items/form.dart';
import 'package:vyaparsetu/core/Core.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData({bool forceRefresh = false}) {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().item.fetchQuantitySummary(businessId, widget.item.id, forceRefresh: forceRefresh);
    }
  }

  void _deleteItem(BuildContext context, Item item) async {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId == null) return;

    final itemModule = context.read<Core>().item;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'delete_item'.tr(),
        content: 'delete_item_confirm'.tr(),
        confirmText: 'delete'.tr(),
        isDestructive: true,
        icon: Icons.delete_outline_rounded,
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await itemModule.deleteItem(businessId, item.id);
      if (success && context.mounted) {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) showSuccessToast('item_deleted'.tr());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Select the latest updated item from context
    final items = context.select<Core, List<Item>>((c) => c.item.items);
    final matchedItem = items.firstWhere(
      (i) => i.id == widget.item.id,
      orElse: () => widget.item,
    );

    final quantitySummary = context.select<Core, ItemQuantitySummary?>(
      (c) => c.item.quantitySummary,
    );
    final isLoadingSummary = context.select<Core, bool>(
      (c) => c.item.isLoadingQuantitySummary,
    );
    final summaryError = context.select<Core, String?>(
      (c) => c.item.quantitySummaryError,
    );

    final double netStock = quantitySummary?.overall.netStock ?? 0.0;
    final bool isPositive = netStock >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          matchedItem.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(getPageRoute(ItemFormScreen(existingItem: matchedItem)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _deleteItem(context, matchedItem),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => _loadData(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Big Available Stock Card (Color-Coded)
              Card(
                elevation: 0,
                color: isDark ? AppTheme.cardDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Left Side: Stock details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'current_stock'.tr().toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              textBaseline: TextBaseline.alphabetic,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              children: [
                                Text(
                                  Formatters.formatDouble(netStock),
                                  style: GoogleFonts.outfit(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: isPositive
                                        ? (isDark ? Colors.green[300] : Colors.green[800])
                                        : (isDark ? Colors.red[300] : Colors.red[800]),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  matchedItem.measuringUnit,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Mini status description
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isPositive ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  netStock > 0
                                      ? 'Everything looks good'
                                      : netStock == 0
                                          ? 'No stock remaining'
                                          : 'Stock is in minus',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right Side: Large visual badge
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPositive ? Icons.check_circle_rounded : Icons.warning_rounded,
                              color: isPositive ? Colors.green : Colors.red,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            netStock > 0
                                ? 'IN STOCK'
                                : netStock == 0
                                    ? 'OUT OF STOCK'
                                    : 'MINUS STOCK',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Activity Summary List
              Text(
                'quantity_summary'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),

              if (isLoadingSummary)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (summaryError != null && quantitySummary == null)
                _buildErrorRetry(context, summaryError)
              else if (quantitySummary != null) ...[
                _buildActivityItem(
                  context,
                  label: 'purchased_label'.tr() + ' (Bought)',
                  value: quantitySummary.overall.purchased,
                  unit: matchedItem.measuringUnit,
                  icon: Icons.trending_down_rounded,
                  color: AppTheme.success,
                ),
                _buildActivityItem(
                  context,
                  label: 'sold_label'.tr() + ' (Sales)',
                  value: quantitySummary.overall.sold,
                  unit: matchedItem.measuringUnit,
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.warning,
                ),
                _buildActivityItem(
                  context,
                  label: 'sale_return_label'.tr() + ' (From Customer)',
                  value: quantitySummary.overall.saleReturned,
                  unit: matchedItem.measuringUnit,
                  icon: Icons.keyboard_return_rounded,
                  color: AppTheme.error,
                ),
                _buildActivityItem(
                  context,
                  label: 'purchase_return_label'.tr() + ' (To Supplier)',
                  value: quantitySummary.overall.purchaseReturned,
                  unit: matchedItem.measuringUnit,
                  icon: Icons.keyboard_double_arrow_right_rounded,
                  color: AppTheme.secondary,
                ),
              ],

              const SizedBox(height: 20),

              // 3. Product Info Card
              _buildProductInfoCard(context, matchedItem),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorRetry(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 28),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.error),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required String label,
    required double value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.gray300 : AppTheme.gray700,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatDouble(value),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              Text(
                unit,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard(BuildContext context, Item item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: isDark ? AppTheme.gray700 : AppTheme.gray200),
          const SizedBox(height: 8),
          _buildInfoRow(context, 'item_name_label'.tr(), item.name, Icons.shopping_bag_outlined),
          _buildInfoRow(
            context,
            'Tax Code (HSN)',
            (item.hsnCode != null && item.hsnCode!.trim().isNotEmpty) ? item.hsnCode! : 'not_provided'.tr(),
            Icons.tag_rounded,
          ),
          _buildInfoRow(context, 'measuring_unit_label'.tr(), item.measuringUnit, Icons.scale_rounded),
          _buildInfoRow(context, 'Added On', Formatters.formatDate(item.createdAt), Icons.calendar_today_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? AppTheme.gray400 : AppTheme.slate500),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.gray400 : AppTheme.slate500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
