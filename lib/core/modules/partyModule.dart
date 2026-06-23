import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/partyLedger.dart';
import 'package:vyaparsetu/types/partyQuantitySummary.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';

class PartyModule {
  final Core core;
  PartyModule(this.core);

  List<Party> _parties = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  final Map<String, PartyLedger> _partyLedgers = {};
  final Map<String, PartyQuantitySummary> _partyQuantitySummaries = {};

  PartyLedger? _partyLedger;
  bool _isLoadingPartyLedger = false;
  String? _partyLedgerError;

  PartyQuantitySummary? _partyQuantitySummary;
  bool _isLoadingPartyQuantitySummary = false;
  String? _partyQuantitySummaryError;

  List<Party> get parties => _parties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PartyLedger? get partyLedger => _partyLedger;
  bool get isLoadingPartyLedger => _isLoadingPartyLedger;
  String? get partyLedgerError => _partyLedgerError;

  PartyQuantitySummary? get partyQuantitySummary => _partyQuantitySummary;
  bool get isLoadingPartyQuantitySummary => _isLoadingPartyQuantitySummary;
  String? get partyQuantitySummaryError => _partyQuantitySummaryError;

  PartyLedger? getPartyLedgerFor(String partyId) => _partyLedgers[partyId];
  PartyQuantitySummary? getPartyQuantitySummaryFor(String partyId) =>
      _partyQuantitySummaries[partyId];

  void adjustPartyBalance(String partyId, double amountChange) {
    final idx = _parties.indexWhere((p) => p.id == partyId);
    if (idx != -1) {
      final p = _parties[idx];
      _parties[idx] = p.copyWith(
        currentBalance: p.currentBalance + amountChange,
      );
      core.notify();
    }
  }

  Future<void> fetchParties(
    String businessId, {
    String? partyType,
    String? search,
    bool forceRefresh = false,
  }) async {
    if (_hasFetched && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final list = await Api.instance.party.list(
        businessId,
        partyType: partyType,
        search: search,
      );
      _parties = list.map((e) => Party.fromJson(e)).toList();
      _hasFetched = true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
  }

  Future<bool> createParty(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final response = await Api.instance.party.create(businessId, data);
      final newParty = Party.fromJson(response);
      _parties.insert(0, newParty);
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

  Future<bool> updateParty(
    String businessId,
    String partyId,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.party.update(businessId, partyId, data);
      final idx = _parties.indexWhere((p) => p.id == partyId);
      if (idx != -1) {
        final existing = _parties[idx];
        final existingMap = existing.toJson();
        data.forEach((key, value) {
          existingMap[key] = value;
        });
        _parties[idx] = Party.fromJson(existingMap);
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

  Future<bool> deleteParty(String businessId, String partyId) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.party.delete(businessId, partyId);
      _parties.removeWhere((p) => p.id == partyId);
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

  Future<void> fetchPartyLedger(
    String businessId,
    String partyId, {
    bool forceRefresh = false,
  }) async {
    _partyLedger = _partyLedgers[partyId];
    _partyLedgerError = null;

    final hasCache = _partyLedger != null;
    if (!hasCache || forceRefresh) {
      _isLoadingPartyLedger = true;
      core.notify();
    }

    try {
      final data = await Api.instance.party.getPartyLedger(businessId, partyId);
      final ledger = PartyLedger.fromJson(data);
      _partyLedgers[partyId] = ledger;
      _partyLedger = ledger;
    } catch (e) {
      _partyLedgerError = extractErrorMessage(e);
    }

    _isLoadingPartyLedger = false;
    core.notify();
  }

  void clearPartyLedger() {
    // No-op to preserve cache
  }

  Future<void> fetchPartyQuantitySummary(
    String businessId,
    String partyId, {
    bool forceRefresh = false,
  }) async {
    _partyQuantitySummary = _partyQuantitySummaries[partyId];
    _partyQuantitySummaryError = null;

    final hasCache = _partyQuantitySummary != null;
    if (!hasCache || forceRefresh) {
      _isLoadingPartyQuantitySummary = true;
      core.notify();
    }

    try {
      final data = await Api.instance.party.getPartyQuantitySummary(
        businessId,
        partyId,
      );
      final summary = PartyQuantitySummary.fromJson(data);
      _partyQuantitySummaries[partyId] = summary;
      _partyQuantitySummary = summary;
    } catch (e) {
      _partyQuantitySummaryError = extractErrorMessage(e);
    }

    _isLoadingPartyQuantitySummary = false;
    core.notify();
  }

  void clearPartyQuantitySummary() {
    // No-op to preserve cache
  }
  void clearAll() {
    _parties = [];
    _partyLedger = null;
    _isLoading = false;
    _isLoadingPartyLedger = false;
    _error = null;
    _partyLedgerError = null;
    _partyQuantitySummary = null;
    _isLoadingPartyQuantitySummary = false;
    _partyQuantitySummaryError = null;
    _partyLedgers.clear();
    _partyQuantitySummaries.clear();
    _hasFetched = false;
    core.notify();
  }
}
