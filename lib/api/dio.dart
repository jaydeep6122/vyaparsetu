import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vyaparsetu/storage/secure_storage.dart';
import 'package:vyaparsetu/storage/hive.dart';
import 'package:vyaparsetu/helpers/logger.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';

class DioInstance {
  static final DioInstance _singleton = DioInstance._internal();

  DioInstance._internal();

  factory DioInstance() {
    return _singleton;
  }

  late Dio dio;
  late String baseURL;

  // Callback when session has expired and user needs to be logged out
  static VoidCallback? onSessionExpired;

  static Future<DioInstance> init({required String baseURL}) async {
    _singleton.baseURL = baseURL;

    BaseOptions options = BaseOptions(
      baseUrl: baseURL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    );
    final dio = Dio(options);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          RequestOptions options,
          RequestInterceptorHandler requestHandler,
        ) async {
          if (kDebugMode) {
            logger('DIO Request: ${options.method} ${options.path}');
          }

          options.baseUrl = baseURL;

          // Attach device metadata headers
          options.headers['meta-platform'] =
              Platform.isAndroid ? 'android' : 'ios';
          options.headers['meta-os'] = Platform.operatingSystem;

          if (_checkIfRequiresAccessToken(options.path)) {
            final accessToken = await SecureStorage.getAccessToken();
            if (accessToken != null) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          }

          return requestHandler.next(options);
        },
        onResponse: (
          Response<dynamic> response,
          ResponseInterceptorHandler responseHandler,
        ) {
          if (kDebugMode) {
            logger(
              'DIO Response: ${response.statusCode} for ${response.requestOptions.path}',
            );
          }
          return responseHandler.next(response);
        },
        onError: (
          DioException error,
          ErrorInterceptorHandler errorHandler,
        ) async {
          if (kDebugMode) {
            logger(
              'DIO Error: ${error.requestOptions.path} - ${error.response?.statusCode} - ${error.response?.data}',
            );
          }

          // Show Toast notification on connection error
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            showErrorToast(
              'Network error. Please check your internet connection.',
            );
            return errorHandler.next(error);
          }

          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;

            // Check if we need to refresh token (i.e. not trying to login/signup/refresh itself)
            if (_checkIfRequiresAccessToken(path)) {
              try {
                final refreshToken = await SecureStorage.getRefreshToken();
                if (refreshToken != null) {
                  // Attempt silent refresh
                  final refreshDio = Dio(BaseOptions(baseUrl: baseURL));
                  final refreshResponse = await refreshDio.post(
                    '/auth/refresh',
                    data: {'refresh_token': refreshToken},
                  );

                  if (refreshResponse.statusCode == 200 ||
                      refreshResponse.statusCode == 201) {
                    final data = refreshResponse.data;
                    final newAccessToken = data['accessToken'];
                    final newRefreshToken = data['refreshToken'];

                    if (newAccessToken != null && newRefreshToken != null) {
                      await SecureStorage.setAccessToken(newAccessToken);
                      await SecureStorage.setRefreshToken(newRefreshToken);

                      // Retry the failed request
                      final options = error.requestOptions;
                      options.headers['Authorization'] =
                          'Bearer $newAccessToken';

                      final retryDio = Dio(BaseOptions(baseUrl: baseURL));
                      final retryResponse = await retryDio.request(
                        options.path,
                        data: options.data,
                        queryParameters: options.queryParameters,
                        options: Options(
                          method: options.method,
                          headers: options.headers,
                          contentType: options.contentType,
                        ),
                      );
                      return errorHandler.resolve(retryResponse);
                    }
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  logger('Token refresh failed: $e');
                }
              }

              // If refresh logic falls through or fails, trigger logout
              await SecureStorage.deleteAll();
              await clearBoxes();
              if (onSessionExpired != null) {
                onSessionExpired!();
              }
            }
          }

          return errorHandler.next(error);
        },
      ),
    );

    _singleton.dio = dio;
    return _singleton;
  }
}

bool _checkIfRequiresAccessToken(String path) {
  // Login, signup and refresh do not require access token
  if (path.contains('/auth/login') ||
      path.contains('/auth/signup') ||
      path.contains('/auth/refresh')) {
    return false;
  }
  return true;
}
