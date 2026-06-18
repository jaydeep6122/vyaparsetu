import 'package:dio/dio.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? deviceInfo,
  }) async {
    final response = await _dio.post(
      '/auth/signup',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceInfo,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> refreshSession({
    required String refreshToken,
    String? deviceInfo,
  }) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {
        'refresh_token': refreshToken,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> logout({
    required String refreshToken,
    required bool allDevices,
  }) async {
    final response = await _dio.post(
      '/auth/logout',
      data: {'refreshToken': refreshToken, 'allDevices': allDevices},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }
}
