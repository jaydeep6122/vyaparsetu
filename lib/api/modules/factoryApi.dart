import 'package:dio/dio.dart';

class FactoryApi {
  final Dio _dio;

  FactoryApi(this._dio);

  // --- Factories ---
  Future<List<Map<String, dynamic>>> listFactories({
    String? status,
    String? search,
  }) async {
    final response = await _dio.get(
      '/factories',
      queryParameters: {
        if (status != null) 'status': status,
        if (search != null) 'search': search,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getFactory(String factoryId) async {
    final response = await _dio.get('/factories/$factoryId');
    return response.data;
  }

  Future<Map<String, dynamic>> createFactory(Map<String, dynamic> data) async {
    final response = await _dio.post('/factories', data: data);
    return response.data;
  }

  Future<void> updateFactory(String factoryId, Map<String, dynamic> data) async {
    await _dio.put('/factories/$factoryId', data: data);
  }

  // --- Workers ---
  Future<List<Map<String, dynamic>>> listWorkers(
    String factoryId, {
    String? type,
    String? search,
    String? status,
  }) async {
    final response = await _dio.get(
      '/factories/$factoryId/workers',
      queryParameters: {
        if (type != null) 'type': type,
        if (search != null) 'search': search,
        if (status != null) 'status': status,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getWorker(String factoryId, String workerId) async {
    final response = await _dio.get('/factories/$factoryId/workers/$workerId');
    return response.data;
  }

  Future<Map<String, dynamic>> createWorker(
    String factoryId, Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/factories/$factoryId/workers', data: data);
    return response.data;
  }

  Future<void> updateWorker(
    String factoryId, String workerId, Map<String, dynamic> data,
  ) async {
    await _dio.put('/factories/$factoryId/workers/$workerId', data: data);
  }

  Future<void> deleteWorker(String factoryId, String workerId) async {
    await _dio.delete('/factories/$factoryId/workers/$workerId');
  }

  // --- Transactions ---
  Future<List<Map<String, dynamic>>> listTransactions(
    String factoryId, {
    String? type,
    String? workerId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dio.get(
      '/factories/$factoryId/transactions',
      queryParameters: {
        if (type != null) 'type': type,
        if (workerId != null) 'worker_id': workerId,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getTransaction(
    String factoryId, String transactionId,
  ) async {
    final response = await _dio.get(
      '/factories/$factoryId/transactions/$transactionId',
    );
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getWorkerTransactions(
    String factoryId, String workerId, {
    String? type,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _dio.get(
      '/factories/$factoryId/workers/$workerId/transactions',
      queryParameters: {
        if (type != null) 'type': type,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
      },
    );
    final List<dynamic> list = response.data;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> createHandoff(
    String factoryId, Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/factories/$factoryId/transactions/handoff', data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createDirect(
    String factoryId, Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/factories/$factoryId/transactions/direct', data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createTruckDistribution(
    String factoryId, Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/factories/$factoryId/transactions/truck-distribution', data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createMoneyGiven(
    String factoryId, Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/factories/$factoryId/transactions/money-given', data: data,
    );
    return response.data;
  }

  // --- Summaries ---
  Future<Map<String, dynamic>> getWorkerSummary(
    String factoryId, String workerId,
  ) async {
    final response = await _dio.get(
      '/factories/$factoryId/workers/$workerId/summary',
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getFactorySummary(String factoryId) async {
    final response = await _dio.get('/factories/$factoryId/summary');
    return response.data;
  }
}
