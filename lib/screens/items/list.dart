import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/components/loadingIndicator.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/errorWidget.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/items/form.dart';
import 'package:vyaparsetu/screens/items/detail.dart';
import 'package:vyaparsetu/core/Core.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().item.fetchItems(businessId);
    }
  }

  Widget _buildItemList(
    bool isDark,
    ThemeData theme,
    bool isLoading,
    List<Item> items,
    String? error,
    String? businessId,
  ) {
    if (isLoading && items.isEmpty) {
      return const LoadingIndicator(
        message: 'Loading items...',
        isShimmer: true,
      );
    }

    if (error != null) {
      return AppErrorWidget(errorMessage: error, onRetry: _loadData);
    }

    final filtered = _filterItems(items);

    return RefreshIndicator(
      color: isDark ? Colors.white : AppTheme.primary,
      onRefresh: () async {
        if (businessId != null) {
          await context.read<Core>().item.fetchItems(businessId, forceRefresh: true);
        }
      },
      child: filtered.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No items found',
                        description:
                            _searchQuery.isNotEmpty
                                ? 'No match for "$_searchQuery" inside this catalog.'
                                : 'Add items here to reference in invoices.',
                        buttonText: _searchQuery.isEmpty ? 'add_item'.tr() : null,
                        onButtonPressed:
                            _searchQuery.isEmpty
                                ? () => Navigator.of(
                                  context,
                                ).push(getPageRoute(const ItemFormScreen())).then((_) {
                                  if (mounted) _loadData();
                                })
                                : null,
                      ),
                    ),
                  ),
                );
              },
            )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () {
                Navigator.of(
                  context,
                ).push(getPageRoute(ItemDetailScreen(item: item))).then((_) {
                  if (mounted) _loadData();
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          isDark
                              ? AppTheme.gray800
                              : AppTheme.primary.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: isDark ? Colors.white : AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unit: ${item.measuringUnit}${item.hsnCode != null ? " | HSN: ${item.hsnCode}" : ""}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color:
                                  isDark ? AppTheme.gray400 : AppTheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.iconTheme.color?.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Item> _filterItems(List<Item> list) {
    return list.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.hsnCode != null &&
              item.hsnCode!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final businessId = context.select<Core, String?>(
      (c) => c.business.selectedBusiness?.id,
    );
    final isLoading = context.select<Core, bool>((c) => c.item.isLoading);
    final items = context.select<Core, List<Item>>((c) => c.item.items);
    final error = context.select<Core, String?>((c) => c.item.error);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Items',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppSearchBar(
              hintText: 'Search items by name or HSN...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: _buildItemList(
              isDark,
              theme,
              isLoading,
              items,
              error,
              businessId,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'items_fab',
        onPressed: () {
          Navigator.of(context).push(getPageRoute(const ItemFormScreen())).then(
            (_) {
              if (mounted) _loadData();
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
