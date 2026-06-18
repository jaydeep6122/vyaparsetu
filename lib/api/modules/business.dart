import 'package:dio/dio.dart';

class BusinessApi {
  final Dio _dio;

  BusinessApi(this._dio);

  Future<void> create(Map<String, dynamic> data) async {
    await _dio.post('/businesses', data: data);
  }

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _dio.get('/businesses');
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getById(String businessId) async {
    final response = await _dio.get('/businesses/$businessId');
    return response.data;
  }

  Future<void> update(String businessId, Map<String, dynamic> data) async {
    await _dio.put('/businesses/$businessId', data: data);
  }

  Future<void> delete(String businessId) async {
    await _dio.delete('/businesses/$businessId');
  }
}
