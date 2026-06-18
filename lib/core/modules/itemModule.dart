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

  ItemQuantitySummary? _quantitySummary;
  bool _isLoadingQuantitySummary = false;
  String? _quantitySummaryError;

  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ItemQuantitySummary? get quantitySummary => _quantitySummary;
  bool get isLoadingQuantitySummary => _isLoadingQuantitySummary;
  String? get quantitySummaryError => _quantitySummaryError;

  Future<void> fetchItems(String businessId) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      final list = await Api.instance.item.list(businessId);
      _items = list.map((e) => Item.fromJson(e)).toList();
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
  }

  Future<bool> createItem(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.item.create(businessId, data);
      await fetchItems(businessId);
      _isLoading = false;
      core.notifyListeners();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
    return false;
  }

  Future<bool> updateItem(String businessId, String itemId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.item.update(businessId, itemId, data);
      await fetchItems(businessId);
      _isLoading = false;
      core.notifyListeners();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
    return false;
  }

  Future<bool> deleteItem(String businessId, String itemId) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.item.delete(businessId, itemId);
      await fetchItems(businessId);
      _isLoading = false;
      core.notifyListeners();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
    return false;
  }

  Future<void> fetchQuantitySummary(String businessId, String itemId) async {
    _quantitySummary = null;
    _isLoadingQuantitySummary = true;
    _quantitySummaryError = null;
    core.notifyListeners();

    try {
      final data = await Api.instance.item.getQuantitySummary(businessId, itemId);
      _quantitySummary = ItemQuantitySummary.fromJson(data);
    } catch (e) {
      _quantitySummaryError = extractErrorMessage(e);
    }

    _isLoadingQuantitySummary = false;
    core.notifyListeners();
  }

  void clearQuantitySummary() {
    _quantitySummary = null;
    _quantitySummaryError = null;
    core.notifyListeners();
  }

  void clearAll() {
    _items = [];
    _isLoading = false;
    _error = null;
    _quantitySummary = null;
    _isLoadingQuantitySummary = false;
    _quantitySummaryError = null;
    core.notifyListeners();
  }
}
