import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/payment.dart';

class PaymentModule extends CoreModule {
  PaymentModule(super.core);

  final PagedState<Payment> list = PagedState();
  PaymentDirection? _direction;
  String _search = '';

  PaymentDirection? get direction => _direction;
  String get search => _search;

  final Map<String, LoadState<Payment>> _details = {};

  LoadState<Payment> detail(String paymentId) =>
      _details.putIfAbsent(paymentId, LoadState.new);

  Future<void> fetchPayments({bool refresh = false, bool more = false}) {
    final businessId = core.businessId;
    return loadPage(
      list,
      fetch: (offset) => Api.instance.payment.list(
        businessId,
        paymentType: _direction?.value,
        search: _search,
        limit: AppConstants.pageSize,
        offset: offset,
      ),
      parse: Payment.fromJson,
      refresh: refresh,
      more: more,
    );
  }

  Future<void> loadMore() => fetchPayments(more: true);

  Future<void> setFilters({
    PaymentDirection? direction,
    bool clearDirection = false,
    String? search,
  }) {
    _direction = clearDirection ? null : (direction ?? _direction);
    _search = search ?? _search;
    return fetchPayments(refresh: true);
  }

  Future<Payment?> getPayment(String paymentId, {bool refresh = false}) {
    final businessId = core.businessId;
    return loadValue(
      detail(paymentId),
      () async => Payment.fromJson(
        await Api.instance.payment.get(businessId, paymentId),
      ),
      refresh: refresh,
    );
  }

  Future<Payment?> createPayment(Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.payment.create(core.businessId, data),
    );
    return json == null ? null : _saved(Payment.fromJson(json));
  }

  /// Replaces the payment and the bills it settles.
  Future<Payment?> updatePayment(
    String paymentId,
    Map<String, dynamic> data,
  ) async {
    final json = await runSave(
      () => Api.instance.payment.update(core.businessId, paymentId, data),
    );
    return json == null ? null : _saved(Payment.fromJson(json));
  }

  Future<Payment?> cancelPayment(String paymentId, {String? reason}) async {
    final json = await runSave(
      () => Api.instance.payment.cancel(
        core.businessId,
        paymentId,
        reason: reason,
      ),
    );
    return json == null ? null : _saved(Payment.fromJson(json));
  }

  Payment _saved(Payment payment) {
    core.markBooksChanged();
    detail(payment.id)
      ..value = payment
      ..stale = false;
    fetchPayments(refresh: true);
    return payment;
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
    _direction = null;
    _search = '';
  }
}
