import 'package:dio/dio.dart';

class ExpenseApi {
  final Dio _dio;

  ExpenseApi(this._dio);

  Future<Map<String, dynamic>> create(String businessId, Map<String, dynamic> data) async {
    final response = await _dio.post('/businesses/$businessId/expenses', data: data);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> list(
    String businessId, {
    String? expenseCategory,
    String? fromDate,
    String? toDate,
    String? search,
  }) async {
    final response = await _dio.get(
      '/businesses/$businessId/expenses',
      queryParameters: {
        if (expenseCategory != null) 'expense_category': expenseCategory,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (search != null) 'search': search,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getById(String businessId, String expenseId) async {
    final response = await _dio.get('/businesses/$businessId/expenses/$expenseId');
    return response.data;
  }

  Future<void> update(String businessId, String expenseId, Map<String, dynamic> data) async {
    await _dio.put('/businesses/$businessId/expenses/$expenseId', data: data);
  }

  Future<void> delete(String businessId, String expenseId) async {
    await _dio.delete('/businesses/$businessId/expenses/$expenseId');
  }
}
