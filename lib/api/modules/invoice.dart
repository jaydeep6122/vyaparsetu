import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

class InvoiceApi {
  final Dio _dio;

  InvoiceApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/invoices';

  Future<PageJson> list(
    String businessId, {
    String? invoiceType,
    String? taxMode,
    String? status,
    String? paymentStatus,
    String? partyId,
    String? from,
    String? to,
    bool overdue = false,
    String? search,
    int? limit,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({
        'invoice_type': invoiceType,
        'tax_mode': taxMode,
        'status': status,
        'payment_status': paymentStatus,
        'party_id': partyId,
        'from': from,
        'to': to,
        'overdue': overdue ? 'true' : null,
        'search': search,
        'limit': limit,
        'offset': offset,
      }),
    );
    return PageJson.of(response);
  }

  /// Full invoice with lines, charges and payments.
  Future<Map<String, dynamic>> get(String businessId, String invoiceId) async {
    return dataOf(await _dio.get('${_base(businessId)}/$invoiceId'));
  }

  Future<Map<String, dynamic>> create(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.post(_base(businessId), data: data));
  }

  /// Replaces the whole invoice; fields left out are cleared.
  Future<Map<String, dynamic>> update(
    String businessId,
    String invoiceId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.put('${_base(businessId)}/$invoiceId', data: data));
  }

  /// Only possible once its payments are cancelled.
  Future<Map<String, dynamic>> cancel(
    String businessId,
    String invoiceId, {
    String? reason,
  }) async {
    final response = await _dio.post(
      '${_base(businessId)}/$invoiceId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return dataOf(response);
  }

  /// Drafts only.
  Future<void> deleteDraft(String businessId, String invoiceId) async {
    await _dio.delete('${_base(businessId)}/$invoiceId');
  }
}
