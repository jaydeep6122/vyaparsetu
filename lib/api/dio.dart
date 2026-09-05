import 'dart:async';
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

  /// Guards token refresh so that N concurrent 401s trigger exactly one
  /// `/auth/refresh` call. The backend rotates refresh tokens, so parallel
  /// refreshes would invalidate each other and log the user out spuriously.
  static Completer<bool>? _refreshCompleter;

  /// Marker placed on a request that has already been replayed once, so a
  /// second 401 on the replay cannot start another refresh cycle.
  static const String _retriedFlag = '__vs_retried';

  /// Single-flight token refresh. Returns true when a fresh access token is
  /// available; false when the session is genuinely no longer valid.
  static Future<bool> _refreshTokens(String baseURL) {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    () async {
      var success = false;
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken != null) {
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
              success = true;
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          logger('Token refresh failed: $e');
        }
      }

      _refreshCompleter = null;
      completer.complete(success);
    }();

    return completer.future;
  }

  /// Tear down the session. Only called when the refresh itself fails, never
  /// on an arbitrary 401 — an authorization failure on one endpoint should not
  /// destroy a valid session.
  static Future<void> _endSession() async {
    await SecureStorage.deleteAll();
    await clearBoxes();
    onSessionExpired?.call();
  }

  static Future<DioInstance> init({required String baseURL}) async {
    _singleton.baseURL = baseURL;

    BaseOptions options = BaseOptions(
      baseUrl: baseURL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      // Without this an upload (business logo, signature) can hang forever.
      sendTimeout: const Duration(seconds: 60),
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
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            showErrorToast(
              'Network error. Please check your internet connection.',
            );
            return errorHandler.next(error);
          }

          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            final options = error.requestOptions;
            final alreadyRetried = options.extra[_retriedFlag] == true;

            // Only attempt a refresh for authenticated endpoints, and never
            // for a request we have already replayed once.
            if (_checkIfRequiresAccessToken(options.path) && !alreadyRetried) {
              final refreshed = await _refreshTokens(baseURL);

              if (!refreshed) {
                // The refresh itself failed — the session really is over.
                await _endSession();
                return errorHandler.next(error);
              }

              final newAccessToken = await SecureStorage.getAccessToken();
              if (newAccessToken == null) {
                await _endSession();
                return errorHandler.next(error);
              }

              options.headers['Authorization'] = 'Bearer $newAccessToken';
              options.extra[_retriedFlag] = true;

              try {
                final retryDio = Dio(BaseOptions(baseUrl: baseURL));
                final retryResponse = await retryDio.request(
                  options.path,
                  data: options.data,
                  queryParameters: options.queryParameters,
                  cancelToken: options.cancelToken,
                  onSendProgress: options.onSendProgress,
                  onReceiveProgress: options.onReceiveProgress,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                    contentType: options.contentType,
                    responseType: options.responseType,
                    followRedirects: options.followRedirects,
                    receiveDataWhenStatusError:
                        options.receiveDataWhenStatusError,
                    extra: options.extra,
                  ),
                );
                return errorHandler.resolve(retryResponse);
              } on DioException catch (retryError) {
                // A 401 on the replay means the fresh token is not accepted.
                if (retryError.response?.statusCode == 401) {
                  await _endSession();
                }
                return errorHandler.next(retryError);
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
  // Login, signup and refresh do not require an access token.
  //
  // `/app-version` is public too, and is called from the splash screen before
  // the user is authenticated. Leaving it in the authenticated set meant a 401
  // there would tear down a perfectly valid session at startup.
  if (path.contains('/auth/login') ||
      path.contains('/auth/signup') ||
      path.contains('/auth/refresh') ||
      path.contains('/app-version')) {
    return false;
  }
  return true;
}
