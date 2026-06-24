import 'package:dio/dio.dart';

class AppConfigApi {
  final Dio _dio;

  AppConfigApi(this._dio);

  Future<String?> getLatestVersion() async {
    final response = await _dio.get('/app-version');
    return response.data['version'] as String?;
  }
}
