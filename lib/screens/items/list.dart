import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vyaparsetu/components/emptyState.dart';
import 'package:vyaparsetu/components/loadStateBody.dart';
import 'package:vyaparsetu/components/pagedList.dart';
import 'package:vyaparsetu/components/searchBar.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/global/themes.dart';
import 'package:vyaparsetu/helpers/navigation.dart';
import 'package:vyaparsetu/screens/common/pickers.dart';
import 'package:vyaparsetu/screens/items/form.dart';
import 'package:vyaparsetu/screens/items/widgets.dart';
import 'package:vyaparsetu/screens/reports/stockSummary.dart';
import 'package:vyaparsetu/types/item.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().item.fetchItems(),
    );
  }

  void _add() => Navigator.of(context).push(getPageRoute(const ItemFormScreen()));

  Future<void> _chooseCategory() async {
    final items = context.read<Core>().item;
    if (items.categoryId != null) {
      setState(() => _categoryName = null);
      await items.setFilters(clearCategory: true);
      return;
    }
    final category = await pickCategory(context, CategoryKind.item);
    if (category == null) return;
    setState(() => _categoryName = category.name);
    await items.setFilters(categoryId: category.id);
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final items = core.item;
    scheduleReload(items.list.needsReload, () => items.fetchItems(refresh: true));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('tab_items'.tr()),
        actions: [
          IconButton(
            tooltip: 'stock_summary'.tr(),
            icon: const Icon(Icons.inventory_outlined),
            onPressed: () => Navigator.of(context).push(getPageRoute(const StockSummaryScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-item',
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text('add_item'.tr()),
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
              hintText: 'search_items_hint'.tr(),
              initialValue: items.search,
              onChanged: (query) => items.setFilters(search: query),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              children: [
                FilterChip(
                  label: Text('low_stock'.tr()),
                  selected: items.lowStockOnly,
                  onSelected: (value) => items.setFilters(lowStockOnly: value),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                FilterChip(
                  label: Text(
                    items.categoryId == null
                        ? 'category'.tr()
                        : (_categoryName ?? 'category'.tr()),
                  ),
                  avatar: const Icon(Icons.category_outlined, size: 18),
                  selected: items.categoryId != null,
                  onSelected: (_) => _chooseCategory(),
                ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<Item>(
              items: items.list.items,
              isLoading: items.list.isLoading,
              isLoadingMore: items.list.isLoadingMore,
              hasMore: items.list.data.hasMore,
              error: items.list.error,
              onRefresh: () => items.fetchItems(refresh: true),
              onLoadMore: items.loadMore,
              itemBuilder: (context, item) => ItemTile(item: item),
              emptyState: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: items.search.isEmpty && !items.lowStockOnly && items.categoryId == null
                    ? 'no_items_yet'.tr()
                    : 'no_items_match'.tr(),
                description: 'no_items_yet_hint'.tr(),
                buttonText: 'add_item'.tr(),
                buttonIcon: Icons.add_rounded,
                onButtonPressed: _add,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
