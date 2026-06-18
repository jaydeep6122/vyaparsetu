import 'package:dio/dio.dart';

class ItemApi {
  final Dio _dio;

  ItemApi(this._dio);

  Future<Map<String, dynamic>> create(String businessId, Map<String, dynamic> data) async {
    final response = await _dio.post('/businesses/$businessId/items', data: data);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> list(
    String businessId, {
    String? search,
  }) async {
    final response = await _dio.get(
      '/businesses/$businessId/items',
      queryParameters: {
        if (search != null) 'search': search,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getById(String businessId, String itemId) async {
    final response = await _dio.get('/businesses/$businessId/items/$itemId');
    return response.data;
  }

  Future<void> update(String businessId, String itemId, Map<String, dynamic> data) async {
    await _dio.put('/businesses/$businessId/items/$itemId', data: data);
  }

  Future<void> delete(String businessId, String itemId) async {
    await _dio.delete('/businesses/$businessId/items/$itemId');
  }

  Future<Map<String, dynamic>> getQuantitySummary(String businessId, String itemId) async {
    final response = await _dio.get(
      '/businesses/$businessId/items/$itemId/quantity-summary',
    );
    return response.data;
  }
}
