import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

/// Reports read from the ledgers. Periods default to the current financial
/// year up to today.
class ReportApi {
  final Dio _dio;

  ReportApi(this._dio);

  String _base(String businessId) => '${businessPath(businessId)}/reports';

  Future<Map<String, dynamic>> _get(
    String businessId,
    String report,
    Map<String, Object?> query,
  ) async {
    final response = await _dio.get(
      '${_base(businessId)}/$report',
      queryParameters: queryOf(query),
    );
    return dataOf(response);
  }

  Future<Map<String, dynamic>> dashboard(
    String businessId, {
    String? from,
    String? to,
  }) => _get(businessId, 'dashboard', {'from': from, 'to': to});

  Future<Map<String, dynamic>> profitLoss(
    String businessId, {
    String? from,
    String? to,
  }) => _get(businessId, 'profit-loss', {'from': from, 'to': to});

  Future<Map<String, dynamic>> gstSummary(
    String businessId, {
    String? from,
    String? to,
  }) => _get(businessId, 'gst-summary', {'from': from, 'to': to});

  Future<Map<String, dynamic>> outstanding(
    String businessId, {
    required String type,
    String? partyId,
  }) => _get(businessId, 'outstanding', {'type': type, 'party_id': partyId});

  Future<Map<String, dynamic>> dayBook(String businessId, {String? date}) =>
      _get(businessId, 'day-book', {'date': date});

  /// Available to every role, not just accountants.
  Future<Map<String, dynamic>> stockSummary(
    String businessId, {
    String? search,
    bool lowStock = false,
  }) => _get(businessId, 'stock-summary', {
    'search': search,
    'low_stock': lowStock ? 'true' : null,
  });
}
