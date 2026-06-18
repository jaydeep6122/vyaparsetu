import 'package:dio/dio.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/userFriendlyErrors.dart';

String extractErrorMessage(dynamic e) {
  try {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data.containsKey('message') && data['message'] is String) {
        return userFriendlyError(data['message'] as String);
      }
    }
  } catch (_) {}
  if (e is DioException) {
    return 'Server error (${e.response?.statusCode})';
  }
  return 'Something went wrong. Please try again.';
}

void apiErrorHandler(dynamic e, [StackTrace? stackTrace]) {
  String errorMessage = 'Something went wrong. Please try again.';

  if (e is DioException) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'] as String;
      } else if (data is Map && data.containsKey('error')) {
        errorMessage = data['error'] as String;
      } else {
        errorMessage = 'Server error (${e.response?.statusCode})';
      }
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Connection timed out. Please try again.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'No internet connection. Please check your network.';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled.';
          break;
        default:
          errorMessage = 'Network error. Please try again.';
      }
    }
  } else if (e is String) {
    errorMessage = e;
  } else if (e != null) {
    errorMessage = e.toString();
  }

  showErrorToast(errorMessage);
}
