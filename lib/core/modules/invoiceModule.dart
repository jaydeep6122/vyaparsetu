import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/invoice.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';
import 'package:vyaparsetu/global/constants.dart';

class InvoiceModule {
  final Core core;
  InvoiceModule(this.core);

  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  final Map<String, List<Invoice>> _partyInvoicesMap = {};
  bool _isLoadingPartyInvoices = false;
  List<Invoice> _partyInvoices = [];

  List<Invoice> get invoices => _invoices;
  List<Invoice> get partyInvoices => _partyInvoices;
  bool get isLoading => _isLoading;
  bool get isLoadingPartyInvoices => _isLoadingPartyInvoices;
  String? get error => _error;

  List<Invoice> getPartyInvoicesFor(String partyId) => _partyInvoicesMap[partyId] ?? [];

  Future<List<Invoice>> fetchInvoices(
    String businessId, {
    String? type,
    String? partyId,
    String? fromDate,
    String? toDate,
    String? search,
    bool forceRefresh = false,
  }) async {
    final isFiltered = type != null || partyId != null || fromDate != null || toDate != null || search != null;

    if (!isFiltered) {
      if (_hasFetched && !forceRefresh) {
        return _invoices;
      }

      _isLoading = true;
      _error = null;
      core.notify();

      try {
        final list = await Api.instance.invoice.list(businessId);
        _invoices = list.map((e) => Invoice.fromJson(e)).toList();
        _hasFetched = true;
      } catch (e) {
        _error = extractErrorMessage(e);
      }

      _isLoading = false;
      core.notify();
      return _invoices;
    } else {
      _isLoading = true;
      _error = null;
      core.notify();

      List<Invoice> results = [];
      try {
        final list = await Api.instance.invoice.list(
          businessId,
          type: type,
          partyId: partyId,
          fromDate: fromDate,
          toDate: toDate,
          search: search,
        );
        results = list.map((e) => Invoice.fromJson(e)).toList();
      } catch (e) {
        _error = extractErrorMessage(e);
      }

      _isLoading = false;
      core.notify();
      return results;
    }
  }

  Future<Invoice?> fetchInvoiceDetail(String businessId, String invoiceId) async {
    // Check if we already have it in the list
    final cached = _invoices.where((i) => i.id == invoiceId).firstOrNull;
    if (cached != null && cached.items != null) {
      return cached;
    }

    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final data = await Api.instance.invoice.getById(businessId, invoiceId);
      final invoice = Invoice.fromJson(data);
      
      // Update in local list if present
      final idx = _invoices.indexWhere((i) => i.id == invoiceId);
      if (idx != -1) {
        _invoices[idx] = invoice;
      }

      _isLoading = false;
      core.notify();
      return invoice;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return null;
  }

  Future<bool> createInvoice(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final response = await Api.instance.invoice.create(businessId, data);
      final newInv = Invoice.fromJson(response);
      _invoices.insert(0, newInv);
      _invoices = List.from(_invoices);

      // Cache under party invoices map if partyId matches
      if (newInv.partyId != null) {
        final partyId = newInv.partyId!;
        if (_partyInvoicesMap.containsKey(partyId)) {
          _partyInvoicesMap[partyId]!.insert(0, newInv);
          _partyInvoicesMap[partyId] = List.from(_partyInvoicesMap[partyId]!);
        } else {
          _partyInvoicesMap[partyId] = [newInv];
        }

        // Adjust party balance locally
        final change = newInv.invoiceType == InvoiceType.sale
            ? (newInv.totalAmount - newInv.paidAmount)
            : -(newInv.totalAmount - newInv.paidAmount);
        core.party.adjustPartyBalance(partyId, change);
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

  Future<bool> updateInvoice(String businessId, String invoiceId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final response = await Api.instance.invoice.update(businessId, invoiceId, data);
      final updatedInv = Invoice.fromJson(response);
      
      final idx = _invoices.indexWhere((i) => i.id == invoiceId);
      double oldPending = 0.0;
      if (idx != -1) {
        final oldInv = _invoices[idx];
        oldPending = oldInv.invoiceType == InvoiceType.sale
            ? (oldInv.totalAmount - oldInv.paidAmount)
            : -(oldInv.totalAmount - oldInv.paidAmount);
        _invoices[idx] = updatedInv;
        _invoices = List.from(_invoices);
      }

      if (updatedInv.partyId != null) {
        // Update in party invoices map
        final list = _partyInvoicesMap[updatedInv.partyId];
        if (list != null) {
          final pIdx = list.indexWhere((i) => i.id == invoiceId);
          if (pIdx != -1) {
            list[pIdx] = updatedInv;
            _partyInvoicesMap[updatedInv.partyId!] = List.from(list);
          }
        }

        // Adjust party balance locally
        final newPending = updatedInv.invoiceType == InvoiceType.sale
            ? (updatedInv.totalAmount - updatedInv.paidAmount)
            : -(updatedInv.totalAmount - updatedInv.paidAmount);
        final change = newPending - oldPending;
        core.party.adjustPartyBalance(updatedInv.partyId!, change);
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

  Future<bool> deleteInvoice(String businessId, String invoiceId) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      // Find old details for balance adjustment
      final idx = _invoices.indexWhere((i) => i.id == invoiceId);
      Invoice? oldInv;
      if (idx != -1) {
        oldInv = _invoices[idx];
      }

      await Api.instance.invoice.delete(businessId, invoiceId);
      _invoices.removeWhere((i) => i.id == invoiceId);
      _invoices = List.from(_invoices);

      if (oldInv != null && oldInv.partyId != null) {
        // Remove from party invoices map
        final list = _partyInvoicesMap[oldInv.partyId];
        if (list != null) {
          list.removeWhere((i) => i.id == invoiceId);
          _partyInvoicesMap[oldInv.partyId!] = List.from(list);
        }

        // Revert party balance adjustment
        final oldPending = oldInv.invoiceType == InvoiceType.sale
            ? (oldInv.totalAmount - oldInv.paidAmount)
            : -(oldInv.totalAmount - oldInv.paidAmount);
        core.party.adjustPartyBalance(oldInv.partyId!, -oldPending);
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

  Future<void> fetchPartyInvoices(String businessId, String partyId, {bool forceRefresh = false}) async {
    // Return cached list if available
    _partyInvoices = _partyInvoicesMap[partyId] ?? [];
    
    if (_partyInvoices.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoadingPartyInvoices = true;
    core.notify();

    try {
      final list = await Api.instance.invoice.list(businessId, partyId: partyId);
      final parsed = list.map((e) => Invoice.fromJson(e)).toList();
      _partyInvoicesMap[partyId] = parsed;
      _partyInvoices = parsed;
    } catch (e) {
      _partyInvoices = [];
    }

    _isLoadingPartyInvoices = false;
    core.notify();
  }

  void clearPartyInvoices() {
    // No-op to preserve cache
  }

  void adjustInvoicePayment(String invoiceId, double amountChange) {
    String? partyId;

    final idx = _invoices.indexWhere((i) => i.id == invoiceId);
    if (idx != -1) {
      final oldInv = _invoices[idx];
      partyId = oldInv.partyId;
      final newPaidAmount = (oldInv.paidAmount + amountChange).clamp(0.0, oldInv.totalAmount);
      PaymentStatus newStatus = PaymentStatus.unpaid;
      if (newPaidAmount >= oldInv.totalAmount) {
        newStatus = PaymentStatus.paid;
      } else if (newPaidAmount > 0) {
        newStatus = PaymentStatus.partially_paid;
      }
      _invoices[idx] = oldInv.copyWith(
        paidAmount: newPaidAmount,
        paymentStatus: newStatus,
      );
      _invoices = List.from(_invoices);
    }

    if (partyId == null) {
      for (final entry in _partyInvoicesMap.entries) {
        final pIdx = entry.value.indexWhere((i) => i.id == invoiceId);
        if (pIdx != -1) {
          partyId = entry.key;
          break;
        }
      }
    }

    if (partyId != null && _partyInvoicesMap.containsKey(partyId)) {
      final list = _partyInvoicesMap[partyId]!;
      final pIdx = list.indexWhere((i) => i.id == invoiceId);
      if (pIdx != -1) {
        final oldInv = list[pIdx];
        final newPaidAmount = (oldInv.paidAmount + amountChange).clamp(0.0, oldInv.totalAmount);
        PaymentStatus newStatus = PaymentStatus.unpaid;
        if (newPaidAmount >= oldInv.totalAmount) {
          newStatus = PaymentStatus.paid;
        } else if (newPaidAmount > 0) {
          newStatus = PaymentStatus.partially_paid;
        }
        list[pIdx] = oldInv.copyWith(
          paidAmount: newPaidAmount,
          paymentStatus: newStatus,
        );
        _partyInvoicesMap[partyId] = List.from(list);
        _partyInvoices = _partyInvoicesMap[partyId]!;
      }
    }

    core.notify();
  }

  void clearAll() {
    _invoices = [];
    _partyInvoices = [];
    _isLoading = false;
    _isLoadingPartyInvoices = false;
    _error = null;
    _partyInvoicesMap.clear();
    _hasFetched = false;
    core.notify();
  }
}
