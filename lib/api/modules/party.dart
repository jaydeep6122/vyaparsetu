import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

class PartyApi {
  final Dio _dio;

  PartyApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/parties';

  Future<PageJson> list(
    String businessId, {
    String? search,
    String? partyType,
    bool includeArchived = false,
    int? limit,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      _base(businessId),
      queryParameters: queryOf({
        'search': search,
        'party_type': partyType,
        'include_archived': includeArchived ? 'true' : null,
        'limit': limit,
        'offset': offset,
      }),
    );
    return PageJson.of(response);
  }

  Future<Map<String, dynamic>> get(String businessId, String partyId) async {
    return dataOf(await _dio.get('${_base(businessId)}/$partyId'));
  }

  Future<Map<String, dynamic>> create(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.post(_base(businessId), data: data));
  }

  /// Only the fields sent are changed; null clears a field.
  Future<Map<String, dynamic>> update(
    String businessId,
    String partyId,
    Map<String, dynamic> data,
  ) async {
    return dataOf(await _dio.patch('${_base(businessId)}/$partyId', data: data));
  }

  Future<Map<String, dynamic>> setArchived(
    String businessId,
    String partyId, {
    required bool archived,
  }) async {
    final action = archived ? 'archive' : 'restore';
    return dataOf(await _dio.post('${_base(businessId)}/$partyId/$action'));
  }

  Future<Map<String, dynamic>> ledger(
    String businessId,
    String partyId, {
    String? from,
    String? to,
  }) async {
    final response = await _dio.get(
      '${_base(businessId)}/$partyId/ledger',
      queryParameters: queryOf({'from': from, 'to': to}),
    );
    return dataOf(response);
  }
}
