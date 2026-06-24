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

  void _loadData() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().item.fetchQuantitySummary(businessId, widget.item.id);
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
    final quantitySummary = context.select<Core, ItemQuantitySummary?>(
      (c) => c.item.quantitySummary,
    );
    final isLoadingSummary = context.select<Core, bool>(
      (c) => c.item.isLoadingQuantitySummary,
    );
    final summaryError = context.select<Core, String?>(
      (c) => c.item.quantitySummaryError,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(getPageRoute(ItemFormScreen(existingItem: widget.item)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _deleteItem(context, widget.item),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailsSection(
              context,
              title: 'catalog_specifications'.tr(),
              items: {
                'item_name_label'.tr(): widget.item.name,
                'hsn_code_label'.tr(): widget.item.hsnCode ?? 'not_provided'.tr(),
                'measuring_unit_label'.tr(): widget.item.measuringUnit,
                'created_at_label'.tr(): Formatters.formatDate(widget.item.createdAt),
                'last_updated_label'.tr(): Formatters.formatDate(widget.item.updatedAt),
              },
            ),
            const SizedBox(height: 20),

            _buildSectionHeader(context, 'quantity_summary'.tr()),
            const SizedBox(height: 12),

            if (isLoadingSummary)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (summaryError != null && quantitySummary == null)
              _buildErrorRetry(context, summaryError)
            else if (quantitySummary != null)
              _buildQuantitySummary(context, quantitySummary),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: isDark ? Colors.white : AppTheme.gray900,
      ),
    );
  }

  Widget _buildErrorRetry(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 32),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.error),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySummary(BuildContext context, ItemQuantitySummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.gray700 : AppTheme.gray200;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildMetricColumn(context, 'sold_label'.tr(), summary.overall.sold, AppTheme.warning),
                VerticalDivider(width: 1, thickness: 1, color: borderColor),
                _buildMetricColumn(context, 'purchased_label'.tr(), summary.overall.purchased, AppTheme.success),
                VerticalDivider(width: 1, thickness: 1, color: borderColor),
                _buildMetricColumn(context, 'sale_return_label'.tr(), summary.overall.saleReturned, AppTheme.error),
                VerticalDivider(width: 1, thickness: 1, color: borderColor),
                _buildMetricColumn(context, 'purchase_return_label'.tr(), summary.overall.purchaseReturned, AppTheme.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2_rounded, size: 20, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                'net_stock'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                ),
              ),
              const Spacer(),
              Text(
                summary.overall.netStock.toStringAsFixed(2),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: summary.overall.netStock >= 0 ? AppTheme.success : AppTheme.error,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.item.measuringUnit,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.gray500 : AppTheme.gray400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(BuildContext context, String label, double value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 26,
              child: Center(
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: isDark ? AppTheme.gray400 : AppTheme.slate500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toStringAsFixed(2),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, {required String title, required Map<String, String> items}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...items.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        entry.key,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
