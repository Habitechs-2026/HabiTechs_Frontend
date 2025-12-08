import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role';

  // ===== TOKEN =====

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
  }

  // ===== ROLES =====

  /// Guarda el rol principal del usuario
  Future<void> saveRoles(List<String> roles) async {
    if (roles.isNotEmpty) {
      // Guardamos el primer rol como principal para que el Router decida a dónde ir
      // (ej. si es ["Admin", "Residente"], guarda "Admin")
      await _storage.write(key: _roleKey, value: roles[0]);
    }
  }

  Future<String?> readRole() async {
    return await _storage.read(key: _roleKey);
  }

  // ===== LIMPIEZA =====

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
