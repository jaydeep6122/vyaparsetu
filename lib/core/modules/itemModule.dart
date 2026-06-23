import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/item.dart';
import 'package:vyaparsetu/types/itemQuantitySummary.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';

class ItemModule {
  final Core core;
  ItemModule(this.core);
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  final Map<String, ItemQuantitySummary> _quantitySummaries = {};

  ItemQuantitySummary? _quantitySummary;
  bool _isLoadingQuantitySummary = false;
  String? _quantitySummaryError;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ItemQuantitySummary? get quantitySummary => _quantitySummary;
  bool get isLoadingQuantitySummary => _isLoadingQuantitySummary;
  String? get quantitySummaryError => _quantitySummaryError;

  ItemQuantitySummary? getQuantitySummaryFor(String itemId) =>
      _quantitySummaries[itemId];

  Future<void> fetchItems(
    String businessId, {
    bool forceRefresh = false,
  }) async {
    if (_hasFetched && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final list = await Api.instance.item.list(businessId);
      _items = list.map((e) => Item.fromJson(e)).toList();
      _hasFetched = true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
  }

  Future<Item?> createItem(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final response = await Api.instance.item.create(businessId, data);
      final newItem = Item.fromJson(response);
      _items.insert(0, newItem);
      _isLoading = false;
      core.notify();
      return newItem;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return null;
  }

  Future<bool> updateItem(
    String businessId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.item.update(businessId, itemId, data);
      final idx = _items.indexWhere((i) => i.id == itemId);
      if (idx != -1) {
        final existing = _items[idx];
        final existingMap = existing.toJson();
        data.forEach((key, value) {
          existingMap[key] = value;
        });
        _items[idx] = Item.fromJson(existingMap);
      }
      _isLoading = false;
      core.notify();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return false;
  }

  Future<bool> deleteItem(String businessId, String itemId) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.item.delete(businessId, itemId);
      _items.removeWhere((i) => i.id == itemId);
      _isLoading = false;
      core.notify();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return false;
  }

  Future<void> fetchQuantitySummary(
    String businessId,
    String itemId, {
    bool forceRefresh = false,
  }) async {
    _quantitySummary = _quantitySummaries[itemId];
    _quantitySummaryError = null;

    final hasCache = _quantitySummary != null;
    if (!hasCache || forceRefresh) {
      _isLoadingQuantitySummary = true;
      core.notify();
    }

    try {
      final data = await Api.instance.item.getQuantitySummary(
        businessId,
        itemId,
      );
      final summary = ItemQuantitySummary.fromJson(data);
      _quantitySummaries[itemId] = summary;
      _quantitySummary = summary;
    } catch (e) {
      _quantitySummaryError = extractErrorMessage(e);
    }

    _isLoadingQuantitySummary = false;
    core.notify();
  }

  void clearQuantitySummary() {
    // No-op to preserve cache
  }
  void clearAll() {
    _items = [];
    _isLoading = false;
    _error = null;
    _quantitySummary = null;
    _isLoadingQuantitySummary = false;
    _quantitySummaryError = null;
    _quantitySummaries.clear();
    _hasFetched = false;
    core.notify();
  }
}
