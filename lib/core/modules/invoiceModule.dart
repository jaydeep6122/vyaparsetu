import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/invoice.dart';

/// Filters of the invoice list.
class InvoiceFilter {
  final InvoiceType? type;
  final PaymentStatus? paymentStatus;
  final InvoiceStatus? status;
  final bool overdueOnly;
  final String search;

  const InvoiceFilter({
    this.type,
    this.paymentStatus,
    this.status,
    this.overdueOnly = false,
    this.search = '',
  });

  InvoiceFilter copyWith({
    InvoiceType? type,
    bool clearType = false,
    PaymentStatus? paymentStatus,
    bool clearPaymentStatus = false,
    InvoiceStatus? status,
    bool clearStatus = false,
    bool? overdueOnly,
    String? search,
  }) {
    return InvoiceFilter(
      type: clearType ? null : (type ?? this.type),
      paymentStatus: clearPaymentStatus
          ? null
          : (paymentStatus ?? this.paymentStatus),
      status: clearStatus ? null : (status ?? this.status),
      overdueOnly: overdueOnly ?? this.overdueOnly,
      search: search ?? this.search,
    );
  }

  bool get isActive =>
      type != null || paymentStatus != null || status != null || overdueOnly;
}

class InvoiceModule extends CoreModule {
  InvoiceModule(super.core);

  final PagedState<Invoice> list = PagedState();
  InvoiceFilter _filter = const InvoiceFilter();
  InvoiceFilter get filter => _filter;

  final Map<String, LoadState<Invoice>> _details = {};

  LoadState<Invoice> detail(String invoiceId) =>
      _details.putIfAbsent(invoiceId, LoadState.new);

  Future<void> fetchInvoices({bool refresh = false, bool more = false}) {
    final businessId = core.businessId;
    final filter = _filter;
    return loadPage(
      list,
      fetch: (offset) => Api.instance.invoice.list(
        businessId,
        invoiceType: filter.type?.value,
        paymentStatus: filter.paymentStatus?.value,
        status: filter.status?.value,
        overdue: filter.overdueOnly,
        search: filter.search,
        limit: AppConstants.pageSize,
        offset: offset,
      ),
      parse: Invoice.fromJson,
      refresh: refresh,
      more: more,
    );
  }

  Future<void> loadMore() => fetchInvoices(more: true);

  Future<void> setFilter(InvoiceFilter filter) {
    _filter = filter;
    return fetchInvoices(refresh: true);
  }

  Future<Invoice?> getInvoice(String invoiceId, {bool refresh = false}) {
    final businessId = core.businessId;
    return loadValue(
      detail(invoiceId),
      () async => Invoice.fromJson(
        await Api.instance.invoice.get(businessId, invoiceId),
      ),
      refresh: refresh,
    );
  }

  /// Invoices of one party, e.g. for its detail screen or to pick bills a
  /// payment settles. Newest first.
  Future<List<Invoice>> invoicesForParty(
    String partyId, {
    InvoiceType? type,
    bool unpaidOnly = false,
  }) async {
    final businessId = core.businessId;
    try {
      final pages = await Future.wait([
        if (unpaidOnly) ...[
          Api.instance.invoice.list(
            businessId,
            partyId: partyId,
            invoiceType: type?.value,
            status: InvoiceStatus.finalized.value,
            paymentStatus: PaymentStatus.unpaid.value,
            limit: 100,
          ),
          Api.instance.invoice.list(
            businessId,
            partyId: partyId,
            invoiceType: type?.value,
            status: InvoiceStatus.finalized.value,
            paymentStatus: PaymentStatus.partiallyPaid.value,
            limit: 100,
          ),
        ] else
          Api.instance.invoice.list(
            businessId,
            partyId: partyId,
            invoiceType: type?.value,
            limit: 100,
          ),
      ]);
      final invoices = pages
          .expand((page) => page.items)
          .map(Invoice.fromJson)
          .toList();
      invoices.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
      return invoices;
    } catch (_) {
      return [];
    }
  }

  Future<Invoice?> createInvoice(Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.invoice.create(core.businessId, data),
    );
    return json == null ? null : _saved(Invoice.fromJson(json));
  }

  /// Replaces the whole invoice.
  Future<Invoice?> updateInvoice(
    String invoiceId,
    Map<String, dynamic> data,
  ) async {
    final json = await runSave(
      () => Api.instance.invoice.update(core.businessId, invoiceId, data),
    );
    return json == null ? null : _saved(Invoice.fromJson(json));
  }

  Future<Invoice?> cancelInvoice(String invoiceId, {String? reason}) async {
    final json = await runSave(
      () => Api.instance.invoice.cancel(
        core.businessId,
        invoiceId,
        reason: reason,
      ),
    );
    return json == null ? null : _saved(Invoice.fromJson(json));
  }

  Future<bool> deleteDraft(String invoiceId) async {
    final done = await runSave(
      () => Api.instance.invoice
          .deleteDraft(core.businessId, invoiceId)
          .then((_) => true),
    );
    if (done != true) return false;
    _details.remove(invoiceId);
    fetchInvoices(refresh: true);
    return true;
  }

  Invoice _saved(Invoice invoice) {
    // Balances, stock, cash and reports all move with an invoice.
    core.markBooksChanged();
    detail(invoice.id)
      ..value = invoice
      ..stale = false;
    fetchInvoices(refresh: true);
    return invoice;
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
    _filter = const InvoiceFilter();
  }
}
