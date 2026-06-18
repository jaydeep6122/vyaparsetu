import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/dashboardSummary.dart';
import 'package:vyaparsetu/types/profitLoss.dart';
// import 'package:vyaparsetu/types/partyLedger.dart';
import 'package:vyaparsetu/core/Core.dart';

class DashboardModule {
  final Core core;
  DashboardModule(this.core);

  DashboardSummary? _summary;
  ProfitLoss? _profitLoss;
  // PartyLedger? _partyLedger;

  bool _isLoadingSummary = false;
  bool _isLoadingProfitLoss = false;
  // bool _isLoadingPartyLedger = false;

  String? _summaryError;
  String? _profitLossError;
  // String? _partyLedgerError;

  DashboardSummary? get summary => _summary;
  ProfitLoss? get profitLoss => _profitLoss;
  // PartyLedger? get partyLedger => _partyLedger;

  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingProfitLoss => _isLoadingProfitLoss;
  // bool get isLoadingPartyLedger => _isLoadingPartyLedger;
  bool get isLoadingGeneral => _isLoadingSummary || _isLoadingProfitLoss;

  String? get error => _summaryError ?? _profitLossError;
  String? get summaryError => _summaryError;
  String? get profitLossError => _profitLossError;
  // String? get partyLedgerError => _partyLedgerError;

  Future<void> fetchSummary(String businessId) async {
    _summary = null;
    _isLoadingSummary = true;
    _summaryError = null;
    core.notifyListeners();

    try {
      final data = await Api.instance.dashboard.getSummary(businessId);
      _summary = DashboardSummary.fromJson(data);
    } catch (e) {
      _summaryError = e.toString();
    }

    _isLoadingSummary = false;
    core.notifyListeners();
  }

  Future<void> fetchProfitLoss(String businessId, {String? fromDate, String? toDate}) async {
    _profitLoss = null;
    _isLoadingProfitLoss = true;
    _profitLossError = null;
    core.notifyListeners();

    try {
      final data = await Api.instance.dashboard.getProfitLoss(
        businessId,
        fromDate: fromDate,
        toDate: toDate,
      );
      _profitLoss = ProfitLoss.fromJson(data);
    } catch (e) {
      _profitLossError = e.toString();
    }

    _isLoadingProfitLoss = false;
    core.notifyListeners();
  }

  // Future<void> fetchPartyLedger(String businessId, String partyId) async {
  //   _partyLedger = null;
  //   _isLoadingPartyLedger = true;
  //   _partyLedgerError = null;
  //   core.notifyListeners();
  //
  //   try {
  //     final data = await Api.instance.dashboard.getPartyLedger(businessId, partyId);
  //     _partyLedger = PartyLedger.fromJson(data);
  //   } catch (e) {
  //     _partyLedgerError = e.toString();
  //   }
  //
  //   _isLoadingPartyLedger = false;
  //   core.notifyListeners();
  // }

  void clearAll() {
    _summary = null;
    _profitLoss = null;
    // _partyLedger = null;
    _summaryError = null;
    _profitLossError = null;
    // _partyLedgerError = null;
    core.notifyListeners();
  }
}
