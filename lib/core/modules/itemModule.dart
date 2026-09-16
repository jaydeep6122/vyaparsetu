import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/item.dart';

class ItemModule extends CoreModule {
  ItemModule(super.core);

  final PagedState<Item> list = PagedState();
  String _search = '';
  bool _lowStockOnly = false;
  String? _categoryId;

  String get search => _search;
  bool get lowStockOnly => _lowStockOnly;
  String? get categoryId => _categoryId;

  final Map<String, LoadState<Item>> _details = {};

  LoadState<Item> detail(String itemId) =>
      _details.putIfAbsent(itemId, LoadState.new);

  Future<void> fetchItems({bool refresh = false, bool more = false}) {
    final businessId = core.businessId;
    return loadPage(
      list,
      fetch: (offset) => Api.instance.item.list(
        businessId,
        search: _search,
        categoryId: _categoryId,
        lowStock: _lowStockOnly,
        limit: AppConstants.pageSize,
        offset: offset,
      ),
      parse: Item.fromJson,
      refresh: refresh,
      more: more,
    );
  }

  Future<void> loadMore() => fetchItems(more: true);

  Future<void> setFilters({
    String? search,
    bool? lowStockOnly,
    String? categoryId,
    bool clearCategory = false,
  }) {
    _search = search ?? _search;
    _lowStockOnly = lowStockOnly ?? _lowStockOnly;
    _categoryId = clearCategory ? null : (categoryId ?? _categoryId);
    return fetchItems(refresh: true);
  }

  Future<Item?> getItem(String itemId, {bool refresh = false}) {
    final businessId = core.businessId;
    return loadValue(
      detail(itemId),
      () async => Item.fromJson(await Api.instance.item.get(businessId, itemId)),
      refresh: refresh,
    );
  }

  /// Quick lookup for pickers, without touching the main list.
  Future<List<Item>> searchItems(String query) async {
    try {
      final page = await Api.instance.item.list(
        core.businessId,
        search: query,
        limit: 30,
      );
      return page.items.map(Item.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Item?> createItem(Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.item.create(core.businessId, data),
    );
    return json == null ? null : _saved(Item.fromJson(json));
  }

  /// Only the fields sent are changed; null clears a field.
  Future<Item?> updateItem(String itemId, Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.item.update(core.businessId, itemId, data),
    );
    return json == null ? null : _saved(Item.fromJson(json));
  }

  Future<Item?> setArchived(String itemId, {required bool archived}) async {
    final json = await runSave(
      () => Api.instance.item.setArchived(
        core.businessId,
        itemId,
        archived: archived,
      ),
    );
    return json == null ? null : _saved(Item.fromJson(json));
  }

  Item _saved(Item item) {
    detail(item.id)
      ..value = item
      ..stale = false;
    list.stale = true;
    fetchItems();
    core.report.markStale();
    return item;
  }

  void markStale() {
    list.stale = true;
    for (final state in _details.values) {
      state.stale = true;
    }
  }

  void clear() {
    list.reset();
    _details.clear();
    _search = '';
    _lowStockOnly = false;
    _categoryId = null;
  }
}
