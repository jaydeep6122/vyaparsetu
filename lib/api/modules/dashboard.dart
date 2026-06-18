import 'package:dio/dio.dart';

class DashboardApi {
  final Dio _dio;

  DashboardApi(this._dio);

  Future<Map<String, dynamic>> getSummary(String businessId) async {
    final response = await _dio.get('/businesses/$businessId/dashboard/summary');
    return response.data;
  }

  Future<Map<String, dynamic>> getProfitLoss(
    String businessId, {
    String? fromDate,
    String? toDate,
  }) async {
    final response = await _dio.get(
      '/businesses/$businessId/dashboard/reports/profit-loss',
      queryParameters: {
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      },
    );
    return response.data;
  }

  // Future<Map<String, dynamic>> getPartyLedger(String businessId, String partyId) async {
  //   final response = await _dio.get('/businesses/$businessId/dashboard/reports/party-ledger/$partyId');
  //   return response.data;
  // }
}
