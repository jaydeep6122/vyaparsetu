import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/stockAdjustment.dart';

/// Manual stock corrections.
class StockModule extends CoreModule {
  StockModule(super.core);

  final PagedState<StockAdjustment> list = PagedState();
  final Map<String, LoadState<StockAdjustment>> _details = {};

  LoadState<StockAdjustment> detail(String adjustmentId) =>
      _details.putIfAbsent(adjustmentId, LoadState.new);

  Future<void> fetchAdjustments({bool refresh = false, bool more = false}) {
    final businessId = core.businessId;
    return loadPage(
      list,
      fetch: (offset) => Api.instance.stock.list(
        businessId,
        limit: AppConstants.pageSize,
        offset: offset,
      ),
      parse: StockAdjustment.fromJson,
      refresh: refresh,
      more: more,
    );
  }

  Future<void> loadMore() => fetchAdjustments(more: true);

  Future<StockAdjustment?> getAdjustment(
    String adjustmentId, {
    bool refresh = false,
  }) {
    final businessId = core.businessId;
    return loadValue(
      detail(adjustmentId),
      () async => StockAdjustment.fromJson(
        await Api.instance.stock.get(businessId, adjustmentId),
      ),
      refresh: refresh,
    );
  }

  Future<StockAdjustment?> createAdjustment(Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.stock.create(core.businessId, data),
    );
    return json == null ? null : _saved(StockAdjustment.fromJson(json));
  }

  Future<StockAdjustment?> cancelAdjustment(
    String adjustmentId, {
    String? reason,
  }) async {
    final json = await runSave(
      () => Api.instance.stock.cancel(
        core.businessId,
        adjustmentId,
        reason: reason,
      ),
    );
    return json == null ? null : _saved(StockAdjustment.fromJson(json));
  }

  StockAdjustment _saved(StockAdjustment adjustment) {
    core.markBooksChanged();
    detail(adjustment.id)
      ..value = adjustment
      ..stale = false;
    fetchAdjustments(refresh: true);
    return adjustment;
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
  }
}
