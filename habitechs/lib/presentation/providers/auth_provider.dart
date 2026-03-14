import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:habitechs/data/services/api_service.dart';
import 'package:habitechs/data/storage/secure_storage_service.dart';
import 'package:habitechs/data/models/user.dart';

// Provider que mantiene al usuario actualizado en tiempo real
final userProvider = StateProvider<User?>((ref) => null);

enum AuthStatus { unknown, authenticated, unauthenticated }

final authProvider = StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(dio, storage, ref);
});

class AuthNotifier extends StateNotifier<AuthStatus> {
  final Dio _dio;
  final SecureStorageService _storage;
  final Ref _ref;

  AuthNotifier(this._dio, this._storage, this._ref)
      : super(AuthStatus.unknown) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.readToken();
    if (token != null) {
      await _loadUserData();
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _dio.get('/api/Users/me');
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        _ref.read(userProvider.notifier).state = user; // Actualizar usuario
        state = AuthStatus.authenticated;
      }
    } catch (e) {
      await logout();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/Auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'] as String;
        // Guardamos roles también localmente por si acaso
        final roles = (data['roles'] as List).cast<String>();
        print('Roles recibidos: $roles');
        await _storage.saveToken(token);
        await _storage.saveRoles(roles);

        await _loadUserData(); // Cargar perfil completo (con roles)
        state = AuthStatus.authenticated;
        return null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return "Credenciales incorrectas.";
      return "Error de conexión.";
    } catch (e) {
      return "Error desconocido: $e";
    }
    return "Error desconocido";
  }

  Future<void> logout() async {
    await _storage.clear();
    _ref.read(userProvider.notifier).state = null;
    state = AuthStatus.unauthenticated;
  }

  void updateUser(User user) {
    _ref.read(userProvider.notifier).state = user;
  }
}

// Helpers
final currentUserProvider = Provider<User?>((ref) => ref.watch(userProvider));

// ✅ LOGICA DE ADMIN VERIFICADA
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return false;
  // Verifica si tiene rol "Admin" o "Administrador"
  return user.roles.contains('Admin') || user.roles.contains('Administrador');
});
