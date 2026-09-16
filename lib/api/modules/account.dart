import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

/// Cash and bank accounts.
class AccountApi {
  final Dio _dio;

  AccountApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/accounts';

  Future<List<Map<String, dynamic>>> list(
    String businessId, {
    bool includeArchived = false,
  }) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({
        'include_archived': includeArchived ? 'true' : null,
      }),
    );
    return listOf(response);
  }

  Future<Map<String, dynamic>> get(String businessId, String accountId) async {
    return dataOf(await _dio.get('${_base(businessId)}/$accountId'));
  }

  /// Admin only.
  Future<Map<String, dynamic>> create(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.post(_base(businessId), data: data));
  }

  /// Admin only. Only the fields sent are changed.
  Future<Map<String, dynamic>> update(
    String businessId,
    String accountId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(
      await _dio.patch('${_base(businessId)}/$accountId', data: data),
    );
  }

  Future<Map<String, dynamic>> setArchived(
    String businessId,
    String accountId, {
    required bool archived,
  }) async {
    final action = archived ? 'archive' : 'restore';
    return dataOf(await _dio.post('${_base(businessId)}/$accountId/$action'));
  }

  /// Entries with a running balance for the period.
  Future<Map<String, dynamic>> book(
    String businessId,
    String accountId, {
    String? from,
    String? to,
  }) async {
    final response = await _dio.get(
      '${_base(businessId)}/$accountId/book',
      queryParameters: queryOf({'from': from, 'to': to}),
    );
    return dataOf(response);
  }
}
