import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';
import 'package:vyaparsetu/global/constants.dart';

/// GST tax rates and item/expense categories.
class MasterApi {
  final Dio _dio;

  MasterApi(this._dio);

  Future<List<Map<String, dynamic>>> taxRates(String businessId) async {
    return listOf(await _dio.get('${businessPath(businessId)}/tax-rates'));
  }

  /// Admin only.
  Future<Map<String, dynamic>> createTaxRate(
    String businessId, {
    required String rate,
    String? cessRate,
    String? name,
  }) async {
    final response = await _dio.post(
      '${businessPath(businessId)}/tax-rates',
      data: {
        'rate': rate,
        if (cessRate != null) 'cess_rate': cessRate,
        if (name != null) 'name': name,
      },
    );
    return dataOf(response);
  }

  /// Admin only. The rate itself cannot change; deactivate it instead.
  Future<Map<String, dynamic>> updateTaxRate(
    String businessId,
    String taxRateId, {
    String? name,
    bool? isActive,
  }) async {
    final response = await _dio.patch(
      '${businessPath(businessId)}/tax-rates/$taxRateId',
      data: {
        if (name != null) 'name': name,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return dataOf(response);
  }

  Future<List<Map<String, dynamic>>> categories(
    String businessId,
    CategoryKind kind, {
    bool includeArchived = false,
  }) async {
    final response = await _dio.get(
      '${businessPath(businessId)}/${kind.path}',
      queryParameters: queryOf({
        'include_archived': includeArchived ? 'true' : null,
      }),
    );
    return listOf(response);
  }

  Future<Map<String, dynamic>> createCategory(
    String businessId,
    CategoryKind kind,
    String name,
  ) async {
    final response = await _dio.post(
      '${businessPath(businessId)}/${kind.path}',
      data: {'name': name},
    );
    return dataOf(response);
  }

  Future<Map<String, dynamic>> renameCategory(
    String businessId,
    CategoryKind kind,
    String categoryId,
    String name,
  ) async {
    final response = await _dio.patch(
      '${businessPath(businessId)}/${kind.path}/$categoryId',
      data: {'name': name},
    );
    return dataOf(response);
  }

  Future<Map<String, dynamic>> setCategoryArchived(
    String businessId,
    CategoryKind kind,
    String categoryId, {
    required bool archived,
  }) async {
    final action = archived ? 'archive' : 'restore';
    final response = await _dio.post(
      '${businessPath(businessId)}/${kind.path}/$categoryId/$action',
    );
    return dataOf(response);
  }
}
