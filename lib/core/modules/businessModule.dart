import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';
import 'package:vyaparsetu/storage/hive/cache.dart';
import 'package:vyaparsetu/types/business.dart';
import 'package:vyaparsetu/types/member.dart';

class BusinessModule extends CoreModule {
  BusinessModule(super.core);

  List<Business> _businesses = [];
  Business? _selectedBusiness;
  bool _isLoading = false;
  String? _loadError;

  List<Business> get businesses => _businesses;
  Business? get selectedBusiness => _selectedBusiness;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  final LoadState<List<DocumentSeries>> documentSeries = LoadState();

  Future<void> _cacheBusinesses() => CacheBox.setBusinesses(
    _businesses.map((business) => business.toJson()).toList(),
  );

  Future<void> fetchBusinesses() async {
    _isLoading = true;
    _loadError = null;
    core.notify();

    try {
      final list = await Api.instance.business.list();
      _businesses = list.map(Business.fromJson).toList();
      await _cacheBusinesses();
    } catch (e) {
      _loadError = extractErrorMessage(e);
      if (_businesses.isEmpty) {
        _businesses = CacheBox.getBusinesses().map(Business.fromJson).toList();
      }
    }

    // Keep the selection pointing at the fresh copy (role and settings may
    // have changed), or restore it after a cold start.
    final selectedId = _selectedBusiness?.id ?? CacheBox.getSelectedBusinessId();
    final match = _businesses.where((b) => b.id == selectedId).firstOrNull;
    if (match != null) {
      _selectedBusiness = match;
    } else if (_businesses.length == 1) {
      await selectBusiness(_businesses.first);
    } else {
      _selectedBusiness = null;
    }

    _isLoading = false;
    core.notify();
  }

  Future<void> selectBusiness(Business business) async {
    final changed = _selectedBusiness?.id != business.id;
    _selectedBusiness = business;
    await CacheBox.setSelectedBusinessId(business.id);
    if (changed) {
      documentSeries.reset();
      core.resetBusinessData();
    }
    core.notify();
  }

  Future<Business?> createBusiness(Map<String, dynamic> data) async {
    final json = await runSave(() => Api.instance.business.create(data));
    if (json == null) return null;
    final business = Business.fromJson(json);
    _businesses = [..._businesses, business];
    await _cacheBusinesses();
    await selectBusiness(business);
    return business;
  }

  /// Updates the selected business. Only the fields sent are changed.
  Future<Business?> updateBusiness(Map<String, dynamic> data) async {
    final current = _selectedBusiness;
    if (current == null) return null;

    final json = await runSave(
      () => Api.instance.business.update(current.id, data),
    );
    if (json == null) return null;
    final business = Business.fromJson(json);
    _businesses = [
      for (final b in _businesses) b.id == business.id ? business : b,
    ];
    _selectedBusiness = business;
    await _cacheBusinesses();
    core.notify();
    return business;
  }

  /// Owner only. Hides the business; its books are kept.
  Future<bool> archiveBusiness() async {
    final current = _selectedBusiness;
    if (current == null) return false;

    final done = await runSave(
      () => Api.instance.business.archive(current.id).then((_) => true),
    );
    if (done != true) return false;
    _businesses = _businesses.where((b) => b.id != current.id).toList();
    _selectedBusiness = null;
    await CacheBox.setSelectedBusinessId(null);
    await _cacheBusinesses();
    core.resetBusinessData();
    return true;
  }

  Future<List<DocumentSeries>?> fetchDocumentSeries({bool refresh = false}) {
    final id = _selectedBusiness!.id;
    return loadValue(
      documentSeries,
      () async => (await Api.instance.business.documentSeries(id))
          .map(DocumentSeries.fromJson)
          .toList(),
      refresh: refresh,
    );
  }

  Future<bool> updateDocumentSeries(
    String seriesId, {
    String? prefix,
    int? nextNumber,
    int? padding,
  }) async {
    final id = _selectedBusiness!.id;
    final json = await runSave(
      () => Api.instance.business.updateDocumentSeries(id, seriesId, {
        'prefix': ?prefix,
        'next_number': ?nextNumber,
        'padding': ?padding,
      }),
    );
    if (json == null) return false;
    await fetchDocumentSeries(refresh: true);
    return true;
  }

  void clearAll() {
    _businesses = [];
    _selectedBusiness = null;
    _isLoading = false;
    _loadError = null;
    documentSeries.reset();
  }
}
