import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/storage/hive/cache.dart';
import 'package:vyaparsetu/types/reports.dart';

class ReportModule extends CoreModule {
  ReportModule(super.core);

  final LoadState<DashboardData> dashboard = LoadState();
  final LoadState<ProfitLoss> profitLoss = LoadState();
  final LoadState<GstSummary> gstSummary = LoadState();
  final LoadState<OutstandingReport> receivables = LoadState();
  final LoadState<OutstandingReport> payables = LoadState();
  final LoadState<DayBook> dayBook = LoadState();
  final LoadState<StockSummary> stockSummary = LoadState();

  LoadState<OutstandingReport> outstanding(OutstandingType type) =>
      type == OutstandingType.receivable ? receivables : payables;

  /// Shows the last dashboard saved on this phone instantly, then refreshes.
  Future<DashboardData?> fetchDashboard({bool refresh = false}) async {
    final businessId = core.businessId;
    if (dashboard.value == null) {
      final cached = CacheBox.getDashboard(businessId);
      if (cached != null) {
        try {
          dashboard
            ..value = DashboardData.fromJson(cached)
            ..stale = true;
        } catch (_) {}
      }
    }

    return loadValue(dashboard, () async {
      final json = await Api.instance.report.dashboard(businessId);
      await CacheBox.setDashboard(businessId, json);
      return DashboardData.fromJson(json);
    }, refresh: refresh);
  }

  Future<ProfitLoss?> fetchProfitLoss({DateTime? from, DateTime? to}) {
    final businessId = core.businessId;
    return loadValue(
      profitLoss,
      () async => ProfitLoss.fromJson(
        await Api.instance.report.profitLoss(
          businessId,
          from: from == null ? null : apiDate(from),
          to: to == null ? null : apiDate(to),
        ),
      ),
      refresh: true,
    );
  }

  Future<GstSummary?> fetchGstSummary({DateTime? from, DateTime? to}) {
    final businessId = core.businessId;
    return loadValue(
      gstSummary,
      () async => GstSummary.fromJson(
        await Api.instance.report.gstSummary(
          businessId,
          from: from == null ? null : apiDate(from),
          to: to == null ? null : apiDate(to),
        ),
      ),
      refresh: true,
    );
  }

  Future<OutstandingReport?> fetchOutstanding(
    OutstandingType type, {
    bool refresh = false,
  }) {
    final businessId = core.businessId;
    return loadValue(
      outstanding(type),
      () async => OutstandingReport.fromJson(
        await Api.instance.report.outstanding(businessId, type: type.value),
      ),
      refresh: refresh,
    );
  }

  /// Open bills, freight charges and expenses of one party, oldest first, to
  /// choose what a payment settles. Empty when offline or not allowed.
  Future<List<OutstandingDocument>> outstandingForParty(
    OutstandingType type,
    String partyId,
  ) async {
    try {
      final json = await Api.instance.report.outstanding(
        core.businessId,
        type: type.value,
        partyId: partyId,
      );
      return OutstandingReport.fromJson(json).documents;
    } catch (_) {
      return [];
    }
  }

  Future<DayBook?> fetchDayBook(DateTime date) {
    final businessId = core.businessId;
    return loadValue(
      dayBook,
      () async => DayBook.fromJson(
        await Api.instance.report.dayBook(businessId, date: apiDate(date)),
      ),
      refresh: true,
    );
  }

  Future<StockSummary?> fetchStockSummary({bool refresh = false}) {
    final businessId = core.businessId;
    return loadValue(
      stockSummary,
      () async => StockSummary.fromJson(
        await Api.instance.report.stockSummary(businessId),
      ),
      refresh: refresh,
    );
  }

  void markStale() {
    for (final state in [
      dashboard,
      profitLoss,
      gstSummary,
      receivables,
      payables,
      dayBook,
      stockSummary,
    ]) {
      state.stale = true;
    }
  }

  void clear() {
    for (final state in [
      dashboard,
      profitLoss,
      gstSummary,
      receivables,
      payables,
      dayBook,
      stockSummary,
    ]) {
      state.reset();
    }
  }
}
