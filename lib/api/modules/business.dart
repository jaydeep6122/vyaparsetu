import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

class BusinessApi {
  final Dio _dio;

  BusinessApi(this._dio);

  Future<List<Map<String, dynamic>>> list() async {
    return listOf(await _dio.get('/businesses'));
  }

  Future<Map<String, dynamic>> get(String businessId) async {
    return dataOf(await _dio.get(businessPath(businessId)));
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    return dataOf(await _dio.post('/businesses', data: data));
  }

  /// Only the fields sent are changed; null clears a field.
  Future<Map<String, dynamic>> update(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.patch(businessPath(businessId), data: data));
  }

  /// Owner only. The business and its books are kept, just hidden.
  Future<void> archive(String businessId) async {
    await _dio.delete(businessPath(businessId));
  }

  Future<List<Map<String, dynamic>>> documentSeries(String businessId) async {
    return listOf(await _dio.get('${businessPath(businessId)}/document-series'));
  }

  Future<Map<String, dynamic>> updateDocumentSeries(
    String businessId,
    String seriesId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '${businessPath(businessId)}/document-series/$seriesId',
      data: data,
    );
    return dataOf(response);
  }
}
