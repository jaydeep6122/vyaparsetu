import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vyaparsetu/helpers/toastNotifications.dart';
import 'package:vyaparsetu/helpers/userFriendlyErrors.dart';

/// A message fit to show the user for any error from an API call.
String extractErrorMessage(Object? error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return userFriendlyError(
        data['message'] as String,
        constraint: data['constraint'] as String?,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'error_timeout'.tr();
      case DioExceptionType.connectionError:
        return 'error_no_internet'.tr();
      case DioExceptionType.cancel:
        return 'error_cancelled'.tr();
      default:
        final status = error.response?.statusCode ?? 0;
        if (status >= 500) return 'error_server'.tr();
    }
  }
  return 'error_generic'.tr();
}

/// Shows an API error as a toast.
void apiErrorHandler(Object? error, [StackTrace? stackTrace]) {
  showErrorToast(extractErrorMessage(error));
}
