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

  Future<void> fetchParties(
    String businessId, {
    String? partyType,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      final list = await Api.instance.party.list(
        businessId,
        partyType: partyType,
        search: search,
      );
      _parties = list.map((e) => Party.fromJson(e)).toList();
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
  }

  Future<bool> createParty(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.party.create(businessId, data);
      await fetchParties(businessId);
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

  Future<bool> updateParty(String businessId, String partyId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.party.update(businessId, partyId, data);
      await fetchParties(businessId);
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

  Future<bool> deleteParty(String businessId, String partyId) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.party.delete(businessId, partyId);
      await fetchParties(businessId);
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

  Future<void> fetchPartyLedger(String businessId, String partyId) async {
    _partyLedger = null;
    _isLoadingPartyLedger = true;
    _partyLedgerError = null;
    core.notifyListeners();

    try {
      final data = await Api.instance.party.getPartyLedger(businessId, partyId);
      _partyLedger = PartyLedger.fromJson(data);
    } catch (e) {
      _partyLedgerError = extractErrorMessage(e);
    }

    _isLoadingPartyLedger = false;
    core.notifyListeners();
  }

  void clearPartyLedger() {
    _partyLedger = null;
    _partyLedgerError = null;
    core.notifyListeners();
  }

  Future<void> fetchPartyQuantitySummary(String businessId, String partyId) async {
    _partyQuantitySummary = null;
    _isLoadingPartyQuantitySummary = true;
    _partyQuantitySummaryError = null;
    core.notifyListeners();

    try {
      final data = await Api.instance.party.getPartyQuantitySummary(businessId, partyId);
      _partyQuantitySummary = PartyQuantitySummary.fromJson(data);
    } catch (e) {
      _partyQuantitySummaryError = extractErrorMessage(e);
    }

    _isLoadingPartyQuantitySummary = false;
    core.notifyListeners();
  }

  void clearPartyQuantitySummary() {
    _partyQuantitySummary = null;
    _partyQuantitySummaryError = null;
    core.notifyListeners();
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
    core.notifyListeners();
  }
}
