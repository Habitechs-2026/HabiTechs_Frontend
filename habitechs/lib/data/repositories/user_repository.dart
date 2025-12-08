import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/user_management_model.dart';
import 'package:habitechs/data/services/api_service.dart';

class UserRepository {
  final Dio _dio;
  UserRepository(this._dio);

  Future<List<UserManagementModel>> getAllUsers() async {
    try {
      final response = await _dio.get('/api/Users/all');
      return (response.data as List)
          .map((e) => UserManagementModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Error al cargar usuarios');
    }
  }

  Future<Response> createUser(
      String email, String name, String password, String role) async {
    return await _dio.post('/api/Users/create', data: {
      'Email': email,
      'FullName': name,
      'Password': password,
      'Role': role
    });
  }

  Future<void> manageRole(String userId, String role, bool enable) async {
    await _dio.post('/api/Users/manage-role',
        data: {'UserId': userId, 'RoleName': role, 'Enable': enable});
  }

  Future<void> toggleStatus(String userId, bool isActive) async {
    await _dio.post('/api/Users/toggle-status',
        data: {'UserId': userId, 'IsActive': isActive});
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    // Usamos el nuevo endpoint AdminResetPasswordById
    await _dio.post('/api/Users/admin-reset-password-id',
        data: {'UserId': userId, 'NewPassword': newPassword});
  }
}

final userRepoProvider =
    Provider((ref) => UserRepository(ref.watch(dioProvider)));
