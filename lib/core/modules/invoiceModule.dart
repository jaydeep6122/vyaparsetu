import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';

class InvoiceModule {
  final Core core;
  InvoiceModule(this.core);

  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<Invoice> _partyInvoices = [];
  bool _isLoadingPartyInvoices = false;

  List<Invoice> get invoices => _invoices;
  List<Invoice> get partyInvoices => _partyInvoices;
  bool get isLoading => _isLoading;
  bool get isLoadingPartyInvoices => _isLoadingPartyInvoices;
  String? get error => _error;

  Future<void> fetchInvoices(
    String businessId, {
    String? type,
    String? partyId,
    String? fromDate,
    String? toDate,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      final list = await Api.instance.invoice.list(
        businessId,
        type: type,
        partyId: partyId,
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
      _invoices = list.map((e) => Invoice.fromJson(e)).toList();
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
  }

  Future<Invoice?> fetchInvoiceDetail(String businessId, String invoiceId) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      final data = await Api.instance.invoice.getById(businessId, invoiceId);
      final invoice = Invoice.fromJson(data);
      _isLoading = false;
      core.notifyListeners();
      return invoice;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
    return null;
  }

  Future<bool> createInvoice(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.invoice.create(businessId, data);
      await fetchInvoices(businessId);
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

  Future<bool> updateInvoice(String businessId, String invoiceId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.invoice.update(businessId, invoiceId, data);
      await fetchInvoices(businessId);
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

  Future<bool> deleteInvoice(String businessId, String invoiceId) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.invoice.delete(businessId, invoiceId);
      await fetchInvoices(businessId);
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

  Future<void> fetchPartyInvoices(String businessId, String partyId) async {
    _isLoadingPartyInvoices = true;
    core.notifyListeners();

    try {
      final list = await Api.instance.invoice.list(businessId, partyId: partyId);
      _partyInvoices = list.map((e) => Invoice.fromJson(e)).toList();
    } catch (e) {
      _partyInvoices = [];
    }

    _isLoadingPartyInvoices = false;
    core.notifyListeners();
  }

  void clearPartyInvoices() {
    _partyInvoices = [];
    core.notifyListeners();
  }

  void clearAll() {
    _invoices = [];
    _partyInvoices = [];
    _isLoading = false;
    _isLoadingPartyInvoices = false;
    _error = null;
    core.notifyListeners();
  }
}
