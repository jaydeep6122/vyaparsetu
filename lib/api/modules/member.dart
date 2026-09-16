import 'package:dio/dio.dart';
import 'package:vyaparsetu/api/response.dart';

/// Team members and invites of a business.
class MemberApi {
  final Dio _dio;

  MemberApi(this._dio);

  Future<List<Map<String, dynamic>>> list(String businessId) async {
    return listOf(await _dio.get('${businessPath(businessId)}/members'));
  }

  Future<Map<String, dynamic>> changeRole(
    String businessId,
    String userId,
    String role,
  ) async {
    final response = await _dio.patch(
      '${businessPath(businessId)}/members/$userId',
      data: {'role': role},
    );
    return dataOf(response);
  }

  /// Removes a member, or leaves the business when [userId] is yourself.
  Future<void> remove(String businessId, String userId) async {
    await _dio.delete('${businessPath(businessId)}/members/$userId');
  }

  Future<List<Map<String, dynamic>>> invites(String businessId) async {
    return listOf(await _dio.get('${businessPath(businessId)}/invites'));
  }

  /// The response carries `invite_token`, shown only once.
  Future<Map<String, dynamic>> createInvite(
    String businessId, {
    required String email,
    required String role,
  }) async {
    final response = await _dio.post(
      '${businessPath(businessId)}/invites',
      data: {'email': email, 'role': role},
    );
    return dataOf(response);
  }

  Future<void> revokeInvite(String businessId, String inviteId) async {
    await _dio.delete('${businessPath(businessId)}/invites/$inviteId');
  }

  /// Returns the joined business with your role.
  Future<Map<String, dynamic>> acceptInvite(String token) async {
    return dataOf(await _dio.post('/invites/accept', data: {'token': token}));
  }
}
