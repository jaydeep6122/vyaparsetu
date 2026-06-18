import 'package:dio/dio.dart';

class InvoiceApi {
  final Dio _dio;

  InvoiceApi(this._dio);

  Future<Map<String, dynamic>> create(String businessId, Map<String, dynamic> data) async {
    final response = await _dio.post('/businesses/$businessId/invoices', data: data);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> list(
    String businessId, {
    String? type,
    String? partyId,
    String? fromDate,
    String? toDate,
    String? search,
  }) async {
    final response = await _dio.get(
      '/businesses/$businessId/invoices',
      queryParameters: {
        if (type != null) 'invoice_type': type,
        if (partyId != null) 'party_id': partyId,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (search != null) 'search': search,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getById(String businessId, String invoiceId) async {
    final response = await _dio.get('/businesses/$businessId/invoices/$invoiceId');
    return response.data;
  }

  Future<Map<String, dynamic>> update(String businessId, String invoiceId, Map<String, dynamic> data) async {
    final response = await _dio.put('/businesses/$businessId/invoices/$invoiceId', data: data);
    return response.data;
  }

  Future<void> delete(String businessId, String invoiceId) async {
    await _dio.delete('/businesses/$businessId/invoices/$invoiceId');
  }
}
