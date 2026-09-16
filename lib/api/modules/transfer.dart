import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

/// Money moved between the business's own cash and bank accounts.
class TransferApi {
  final Dio _dio;

  TransferApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/transfers';

  Future<PageJson> list(
    String businessId, {
    String? accountId,
    String? status,
    String? from,
    String? to,
    int? limit,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({
        'account_id': accountId,
        'status': status,
        'from': from,
        'to': to,
        'limit': limit,
        'offset': offset,
      }),
    );
    return PageJson.of(response);
  }

  Future<Map<String, dynamic>> create(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.post(_base(businessId), data: data));
  }

  Future<Map<String, dynamic>> cancel(
    String businessId,
    String transferId, {
    String? reason,
  }) async {
    final response = await _dio.post(
      '${_base(businessId)}/$transferId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return dataOf(response);
  }
}
