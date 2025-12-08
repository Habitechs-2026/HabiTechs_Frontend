import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/user_management_model.dart';
import 'package:habitechs/data/repositories/user_repository.dart';
import 'package:dio/dio.dart';

// Provider de Lista de Usuarios (Auto-recargable)
final usersListProvider =
    FutureProvider.autoDispose<List<UserManagementModel>>((ref) async {
  return ref.watch(userRepoProvider).getAllUsers();
});

// CLAVE: Guarda las credenciales de éxito de creación para activar el diálogo de compartir
final creationSuccessCredentialsProvider =
    StateProvider<Map<String, String>?>((ref) => null);

// Controller para acciones
final userActionProvider =
    StateNotifierProvider<UserActionNotifier, AsyncValue<void>>((ref) {
  return UserActionNotifier(ref);
});

class UserActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  UserActionNotifier(this._ref) : super(const AsyncData(null));

  Future<void> createUser(
      String email, String name, String pass, String role) async {
    state = const AsyncLoading();
    _ref.read(creationSuccessCredentialsProvider.notifier).state = null;

    try {
      final response =
          await _ref.read(userRepoProvider).createUser(email, name, pass, role);

      final password = response.data['password'] as String;
      final newEmail = response.data['email'] as String;

      _ref.invalidate(usersListProvider); // Recarga el FutureProvider
      state = const AsyncData(null);

      _ref.read(creationSuccessCredentialsProvider.notifier).state = {
        'email': newEmail,
        'password': password,
        'name': name
      };
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message'] ?? e.response?.data.toString()
          : e.message;
      state = AsyncError(Exception(msg), StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> toggleRole(String userId, String role, bool enable) async {
    try {
      await _ref.read(userRepoProvider).manageRole(userId, role, enable);
      _ref.invalidate(usersListProvider); // Recarga el FutureProvider
    } catch (e) {
      // Dejamos que la UI maneje el error a través de logs o SnackBar, sin romper el provider de lista.
      throw Exception('Error al gestionar rol: $e');
    }
  }

  Future<void> toggleStatus(String userId, bool isActive) async {
    try {
      await _ref.read(userRepoProvider).toggleStatus(userId, isActive);
      _ref.invalidate(usersListProvider); // Recarga el FutureProvider
    } catch (e) {
      // Dejamos que la UI maneje el error.
      throw Exception('Error al cambiar estado: $e');
    }
  }

  Future<void> resetPassword(String userId, String newPass) async {
    state = const AsyncLoading();
    try {
      await _ref.read(userRepoProvider).resetPassword(userId, newPass);
      state = const AsyncData(null);
    } on DioException catch (e) {
      final msg =
          e.response?.data is Map ? e.response?.data['message'] : e.message;
      state = AsyncError(
          Exception(msg ?? 'Error al resetear contraseña'), StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
