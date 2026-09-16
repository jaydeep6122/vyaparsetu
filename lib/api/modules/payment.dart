import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

class PaymentApi {
  final Dio _dio;

  PaymentApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/payments';

  Future<PageJson> list(
    String businessId, {
    String? paymentType,
    String? partyId,
    String? accountId,
    String? mode,
    String? status,
    String? from,
    String? to,
    String? search,
    int? limit,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({
        'payment_type': paymentType,
        'party_id': partyId,
        'account_id': accountId,
        'mode': mode,
        'status': status,
        'from': from,
        'to': to,
        'search': search,
        'limit': limit,
        'offset': offset,
      }),
    );
    return PageJson.of(response);
  }

  /// Payment with the bills it settles.
  Future<Map<String, dynamic>> get(String businessId, String paymentId) async {
    return dataOf(await _dio.get('${_base(businessId)}/$paymentId'));
  }

  Future<Map<String, dynamic>> create(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.post(_base(businessId), data: data));
  }

  /// Replaces the payment and its allocations.
  Future<Map<String, dynamic>> update(
    String businessId,
    String paymentId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.put('${_base(businessId)}/$paymentId', data: data));
  }

  Future<Map<String, dynamic>> cancel(
    String businessId,
    String paymentId, {
    String? reason,
  }) async {
    final response = await _dio.post(
      '${_base(businessId)}/$paymentId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return dataOf(response);
  }
}
