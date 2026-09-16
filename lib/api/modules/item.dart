import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

class ItemApi {
  final Dio _dio;

  ItemApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/items';

  Future<PageJson> list(
    String businessId, {
    String? search,
    String? categoryId,
    bool lowStock = false,
    bool includeArchived = false,
    int? limit,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({
        'search': search,
        'category_id': categoryId,
        'low_stock': lowStock ? 'true' : null,
        'include_archived': includeArchived ? 'true' : null,
        'limit': limit,
        'offset': offset,
      }),
    );
    return PageJson.of(response);
  }

  Future<Map<String, dynamic>> get(String businessId, String itemId) async {
    return dataOf(await _dio.get('${_base(businessId)}/$itemId'));
  }

  Future<Map<String, dynamic>> create(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.post(_base(businessId), data: data));
  }

  /// Only the fields sent are changed; null clears a field.
  Future<Map<String, dynamic>> update(
    String businessId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.patch('${_base(businessId)}/$itemId', data: data));
  }

  Future<Map<String, dynamic>> setArchived(
    String businessId,
    String itemId, {
    required bool archived,
  }) async {
    final action = archived ? 'archive' : 'restore';
    return dataOf(await _dio.post('${_base(businessId)}/$itemId/$action'));
  }
}
