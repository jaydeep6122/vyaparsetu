import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/payment.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';
import 'package:vyaparsetu/global/constants.dart';

class PaymentModule {
  final Core core;
  PaymentModule(this.core);

  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<Payment>> fetchPayments(
    String businessId, {
    String? paymentType,
    String? partyId,
    String? fromDate,
    String? toDate,
    bool forceRefresh = false,
  }) async {
    final isFiltered = paymentType != null || partyId != null || fromDate != null || toDate != null;

    if (!isFiltered) {
      if (_hasFetched && !forceRefresh) {
        return _payments;
      }

      _isLoading = true;
      _error = null;
      core.notify();

      try {
        final list = await Api.instance.payment.list(businessId);
        _payments = list.map((e) => Payment.fromJson(e)).toList();
        _hasFetched = true;
      } catch (e) {
        _error = extractErrorMessage(e);
      }

      _isLoading = false;
      core.notify();
      return _payments;
    } else {
      _isLoading = true;
      _error = null;
      core.notify();

      List<Payment> results = [];
      try {
        final list = await Api.instance.payment.list(
          businessId,
          paymentType: paymentType,
          partyId: partyId,
          fromDate: fromDate,
          toDate: toDate,
        );
        results = list.map((e) => Payment.fromJson(e)).toList();
      } catch (e) {
        _error = extractErrorMessage(e);
      }

      _isLoading = false;
      core.notify();
      return results;
    }
  }

  Future<bool> createPayment(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final response = await Api.instance.payment.create(businessId, data);
      final newPayment = Payment.fromJson(response);
      _payments.insert(0, newPayment);

      // Adjust party balance locally
      final change = newPayment.paymentType == PaymentType.payment_in
          ? -newPayment.amount
          : newPayment.amount;
      core.party.adjustPartyBalance(newPayment.partyId, change);

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

  Future<bool> updatePayment(String businessId, String paymentId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.payment.update(businessId, paymentId, data);
      
      final idx = _payments.indexWhere((p) => p.id == paymentId);
      if (idx != -1) {
        final oldPayment = _payments[idx];
        final oldChange = oldPayment.paymentType == PaymentType.payment_in
            ? -oldPayment.amount
            : oldPayment.amount;

        final existingMap = oldPayment.toJson();
        data.forEach((key, value) {
          existingMap[key] = value;
        });
        final updatedPayment = Payment.fromJson(existingMap);
        _payments[idx] = updatedPayment;

        final newChange = updatedPayment.paymentType == PaymentType.payment_in
            ? -updatedPayment.amount
            : updatedPayment.amount;
        final change = newChange - oldChange;
        core.party.adjustPartyBalance(updatedPayment.partyId, change);
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

  Future<bool> deletePayment(String businessId, String paymentId) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final idx = _payments.indexWhere((p) => p.id == paymentId);
      if (idx != -1) {
        final oldPayment = _payments[idx];
        final change = oldPayment.paymentType == PaymentType.payment_in
            ? oldPayment.amount
            : -oldPayment.amount;
        core.party.adjustPartyBalance(oldPayment.partyId, change);
      }

      await Api.instance.payment.delete(businessId, paymentId);
      _payments.removeWhere((p) => p.id == paymentId);

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

  void clearAll() {
    _payments = [];
    _isLoading = false;
    _error = null;
    _hasFetched = false;
    core.notify();
  }
}
