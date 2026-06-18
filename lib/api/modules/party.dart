import 'package:dio/dio.dart';

class PartyApi {
  final Dio _dio;

  PartyApi(this._dio);

  Future<Map<String, dynamic>> create(String businessId, Map<String, dynamic> data) async {
    final response = await _dio.post('/businesses/$businessId/parties', data: data);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> list(
    String businessId, {
    String? partyType,
    String? search,
  }) async {
    final response = await _dio.get(
      '/businesses/$businessId/parties',
      queryParameters: {
        if (partyType != null) 'party_type': partyType,
        if (search != null) 'search': search,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getById(String businessId, String partyId) async {
    final response = await _dio.get('/businesses/$businessId/parties/$partyId');
    return response.data;
  }

  Future<void> update(String businessId, String partyId, Map<String, dynamic> data) async {
    await _dio.put('/businesses/$businessId/parties/$partyId', data: data);
  }

  Future<void> delete(String businessId, String partyId) async {
    await _dio.delete('/businesses/$businessId/parties/$partyId');
  }

  Future<Map<String, dynamic>> getPartyLedger(String businessId, String partyId) async {
    final response = await _dio.get(
      '/businesses/$businessId/dashboard/reports/party-ledger/$partyId',
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getPartyQuantitySummary(String businessId, String partyId) async {
    final response = await _dio.get(
      '/businesses/$businessId/parties/$partyId/quantity-summary',
    );
    return response.data;
  }
}
