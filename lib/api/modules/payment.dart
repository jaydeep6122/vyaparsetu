import 'package:dio/dio.dart';

class PaymentApi {
  final Dio _dio;

  PaymentApi(this._dio);

  Future<Map<String, dynamic>> create(String businessId, Map<String, dynamic> data) async {
    final response = await _dio.post('/businesses/$businessId/payments', data: data);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> list(
    String businessId, {
    String? paymentType,
    String? partyId,
    String? fromDate,
    String? toDate,
  }) async {
    final response = await _dio.get(
      '/businesses/$businessId/payments',
      queryParameters: {
        if (paymentType != null) 'payment_type': paymentType,
        if (partyId != null) 'party_id': partyId,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> update(String businessId, String paymentId, Map<String, dynamic> data) async {
    await _dio.put('/businesses/$businessId/payments/$paymentId', data: data);
  }

  Future<void> delete(String businessId, String paymentId) async {
    await _dio.delete('/businesses/$businessId/payments/$paymentId');
  }
}
