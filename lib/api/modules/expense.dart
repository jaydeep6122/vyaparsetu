import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

class ExpenseApi {
  final Dio _dio;

  ExpenseApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/expenses';

  Future<PageJson> list(
    String businessId, {
    String? categoryId,
    String? partyId,
    String? status,
    String? paymentStatus,
    String? from,
    String? to,
    String? search,
    int? limit,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({
        'category_id': categoryId,
        'party_id': partyId,
        'status': status,
        'payment_status': paymentStatus,
        'from': from,
        'to': to,
        'search': search,
        'limit': limit,
        'offset': offset,
      }),
    );
    return PageJson.of(response);
  }

  Future<Map<String, dynamic>> get(String businessId, String expenseId) async {
    return dataOf(await _dio.get('${_base(businessId)}/$expenseId'));
  }

  Future<Map<String, dynamic>> create(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.post(_base(businessId), data: data));
  }

  /// Replaces the whole expense; fields left out are cleared.
  Future<Map<String, dynamic>> update(
    String businessId,
    String expenseId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.put('${_base(businessId)}/$expenseId', data: data));
  }

  Future<Map<String, dynamic>> cancel(
    String businessId,
    String expenseId, {
    String? reason,
  }) async {
    final response = await _dio.post(
      '${_base(businessId)}/$expenseId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return dataOf(response);
  }
}
