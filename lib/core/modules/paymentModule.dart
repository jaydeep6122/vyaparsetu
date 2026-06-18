import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/payment.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';

class PaymentModule {
  final Core core;
  PaymentModule(this.core);

  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _error;

  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPayments(
    String businessId, {
    String? paymentType,
    String? partyId,
    String? fromDate,
    String? toDate,
  }) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final list = await Api.instance.payment.list(
        businessId,
        paymentType: paymentType,
        partyId: partyId,
        fromDate: fromDate,
        toDate: toDate,
      );
      _payments = list.map((e) => Payment.fromJson(e)).toList();
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
  }

  Future<bool> createPayment(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.payment.create(businessId, data);
      await fetchPayments(businessId);
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
      await fetchPayments(businessId);
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
      await Api.instance.payment.delete(businessId, paymentId);
      await fetchPayments(businessId);
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
    core.notify();
  }
}
