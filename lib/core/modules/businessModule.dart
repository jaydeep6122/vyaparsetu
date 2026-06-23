import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/storage/hive/cache.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';

class BusinessModule {
  final Core core;
  BusinessModule(this.core);

  List<Business> _businesses = [];
  Business? _selectedBusiness;
  bool _isLoading = false;
  String? _error;

  List<Business> get businesses => _businesses;
  Business? get selectedBusiness => _selectedBusiness;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBusinesses() async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final list = await Api.instance.business.list();
      _businesses = list.map((e) => Business.fromJson(e)).toList();
      await CacheBox.setBusinesses(list);

      if (_selectedBusiness == null) {
        restoreSelectedBusiness();
      } else {
        final index = _businesses.indexWhere((b) => b.id == _selectedBusiness!.id);
        if (index != -1) {
          _selectedBusiness = _businesses[index];
        } else {
          _selectedBusiness = null;
        }
      }
    } catch (e) {
      _error = extractErrorMessage(e);
      final cachedList = CacheBox.getBusinesses();
      if (cachedList.isNotEmpty) {
        _businesses = cachedList.map((e) => Business.fromJson(e)).toList();
        restoreSelectedBusiness();
      }
    }

    _isLoading = false;
    core.notify();
  }

  void restoreSelectedBusiness() {
    final selectedId = CacheBox.getSelectedBusinessId();
    if (selectedId != null && _businesses.isNotEmpty) {
      final matched = _businesses.where((b) => b.id == selectedId);
      if (matched.isNotEmpty) {
        _selectedBusiness = matched.first;
      } else {
        if (_businesses.length == 1) {
          selectBusiness(_businesses.first);
        }
      }
    } else if (_businesses.length == 1) {
      selectBusiness(_businesses.first);
    }
  }

  Future<void> selectBusiness(Business business) async {
    _selectedBusiness = business;
    await CacheBox.setSelectedBusinessId(business.id);
    core.dashboard.loadCachedSummary(business.id);
    core.invoice.clearAll();
    core.item.clearAll();
    core.party.clearAll();
    core.payment.clearAll();
    core.expense.clearAll();
    core.notify();
  }

  Future<bool> createBusiness(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.business.create(data);
      await fetchBusinesses();
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

  Future<bool> updateBusiness(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.business.update(id, data);
      await fetchBusinesses();

      if (_selectedBusiness?.id == id) {
        final matched = _businesses.where((b) => b.id == id);
        if (matched.isNotEmpty) {
          _selectedBusiness = matched.first;
        }
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

  Future<bool> deleteBusiness(String id) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.business.delete(id);
      await fetchBusinesses();

      if (_selectedBusiness?.id == id) {
        _selectedBusiness = null;
        await CacheBox.setSelectedBusinessId(null);
        if (_businesses.isNotEmpty) {
          if (_businesses.length == 1) {
            selectBusiness(_businesses.first);
          }
        }
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

  Future<void> clearSelectedBusiness() async {
    _selectedBusiness = null;
    await CacheBox.setSelectedBusinessId(null);
    core.notify();
  }

  void clearAll() {
    _businesses = [];
    _selectedBusiness = null;
    _isLoading = false;
    _error = null;
  }

}
