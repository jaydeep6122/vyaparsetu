import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

/// Manual stock corrections (damage, physical count, opening).
class StockApi {
  final Dio _dio;

  StockApi(this._dio);

  String _base(String businessId) =>
      '${businessPath(businessId)}/stock-adjustments';

  Future<PageJson> list(
    String businessId, {
    String? status,
    String? from,
    String? to,
    int? limit,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({
        'status': status,
        'from': from,
        'to': to,
        'limit': limit,
        'offset': offset,
      }),
    );
    return PageJson.of(response);
  }

  Future<Map<String, dynamic>> get(
    String businessId,
    String adjustmentId,
  ) async {
    return dataOf(await _dio.get('${_base(businessId)}/$adjustmentId'));
  }

  Future<Map<String, dynamic>> create(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.post(_base(businessId), data: data));
  }

  Future<Map<String, dynamic>> cancel(
    String businessId,
    String adjustmentId, {
    String? reason,
  }) async {
    final response = await _dio.post(
      '${_base(businessId)}/$adjustmentId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return dataOf(response);
  }
}
