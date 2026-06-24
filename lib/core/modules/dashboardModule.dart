import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/dashboardSummary.dart';
import 'package:vyaparsetu/types/profitLoss.dart';
// import 'package:vyaparsetu/types/partyLedger.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/storage/hive/cache.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/global/constants.dart';

class DashboardModule {
  final Core core;
  DashboardModule(this.core) {
    try {
      final selectedId = CacheBox.getSelectedBusinessId();
      if (selectedId != null) {
        final cached = CacheBox.getCachedBusinessSummaries();
        if (cached.containsKey(selectedId)) {
          _summary = DashboardSummary.fromJson(Map<String, dynamic>.from(cached[selectedId]));
        }
      }
    } catch (_) {}
  }

  void loadCachedSummary(String businessId) {
    try {
      final cached = CacheBox.getCachedBusinessSummaries();
      if (cached.containsKey(businessId)) {
        _summary = DashboardSummary.fromJson(Map<String, dynamic>.from(cached[businessId]));
      } else {
        _summary = null;
      }
    } catch (_) {
      _summary = null;
    }
    _profitLoss = null;
    _summaryError = null;
    _profitLossError = null;
    core.notify();
  }

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

  Future<void> fetchSummary(String businessId, {bool forceRefresh = false}) async {
    final showLoading = _summary == null || forceRefresh;
    if (showLoading) {
      _isLoadingSummary = true;
      _summaryError = null;
      core.notify();
    } else {
      _summaryError = null;
    }

    try {
      final data = await Api.instance.dashboard.getSummary(businessId);
      _summary = DashboardSummary.fromJson(data);
      _summaryError = null;

      try {
        final cached = CacheBox.getCachedBusinessSummaries();
        cached[businessId] = data;
        await CacheBox.setCachedBusinessSummaries(cached);
      } catch (_) {}
    } catch (e) {
      _summaryError = e.toString();
      if (_summary != null) {
        showErrorToast('Failed to update dashboard: $_summaryError');
      }
    }

    _isLoadingSummary = false;
    core.notify();
  }

  Future<void> fetchProfitLoss(
    String businessId, {
    String? fromDate,
    String? toDate,
  }) async {
    _profitLoss = null;
    _isLoadingProfitLoss = true;
    _profitLossError = null;
    core.notify();

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
    core.notify();
  }

  // Future<void> fetchPartyLedger(String businessId, String partyId) async {
  //   _partyLedger = null;
  //   _isLoadingPartyLedger = true;
  //   _partyLedgerError = null;
  //   core.notify();
  //
  //   try {
  //     final data = await Api.instance.dashboard.getPartyLedger(businessId, partyId);
  //     _partyLedger = PartyLedger.fromJson(data);
  //   } catch (e) {
  //     _partyLedgerError = e.toString();
  //   }
  //
  //   _isLoadingPartyLedger = false;
  //   core.notify();
  // }

  void clearAll() {
    _summary = null;
    _profitLoss = null;
    // _partyLedger = null;
    _summaryError = null;
    _profitLossError = null;
    // _partyLedgerError = null;
    core.notify();
  }

  void adjustDashboardPayment({
    required PaymentType type,
    required double amountChange,
    required PaymentMode mode,
  }) {
    if (_summary == null) return;

    double cashDelta = 0;
    double bankDelta = 0;
    double upiDelta = 0;

    if (mode == PaymentMode.cash) {
      cashDelta = amountChange;
    } else if (mode == PaymentMode.bank) {
      bankDelta = amountChange;
    } else if (mode == PaymentMode.upi) {
      upiDelta = amountChange;
    }

    final sign = (type == PaymentType.payment_in) ? 1.0 : -1.0;

    final updatedCashBook = CashBook(
      cash: _summary!.cashBook.cash + (cashDelta * sign),
      bank: _summary!.cashBook.bank + (bankDelta * sign),
      upi: _summary!.cashBook.upi + (upiDelta * sign),
      totalMoney: _summary!.cashBook.totalMoney + (amountChange * sign),
    );

    MetricBreakdown totalReceivables = _summary!.totalReceivables;
    MetricBreakdown received = _summary!.received;
    MetricBreakdown totalPayables = _summary!.totalPayables;
    MetricBreakdown totalPaid = _summary!.totalPaid;

    if (type == PaymentType.payment_in) {
      totalReceivables = MetricBreakdown(
        base: totalReceivables.base,
        tax: totalReceivables.tax,
        total: totalReceivables.total - amountChange,
      );
      received = MetricBreakdown(
        base: received.base,
        tax: received.tax,
        total: received.total + amountChange,
      );
    } else {
      totalPayables = MetricBreakdown(
        base: totalPayables.base,
        tax: totalPayables.tax,
        total: totalPayables.total - amountChange,
      );
      totalPaid = MetricBreakdown(
        base: totalPaid.base,
        tax: totalPaid.tax,
        total: totalPaid.total + amountChange,
      );
    }

    _summary = DashboardSummary(
      totalSales: _summary!.totalSales,
      totalPurchases: _summary!.totalPurchases,
      totalReceivables: totalReceivables,
      totalPayables: totalPayables,
      received: received,
      totalPaid: totalPaid,
      lowStockItemsCount: _summary!.lowStockItemsCount,
      lowStockItems: _summary!.lowStockItems,
      cashBook: updatedCashBook,
    );

    final selectedId = CacheBox.getSelectedBusinessId();
    if (selectedId != null) {
      try {
        final cached = CacheBox.getCachedBusinessSummaries();
        cached[selectedId] = _summary!.toJson();
        CacheBox.setCachedBusinessSummaries(cached);
      } catch (_) {}
    }

    core.notify();
  }
}
