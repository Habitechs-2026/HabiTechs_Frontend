import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:habitechs/core/config/app_config.dart';

// Modelo de Usuario interno del servicio
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final List<String> roles; // <--- AGREGADO

  final String? residentCode;
  final String? identityCard;
  final String? occupation;
  final String? phoneNumber;
  final String? secondaryPhoneNumber;
  final String? personalEmail;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
    required this.roles, // <--- AGREGADO
    this.residentCode,
    this.identityCard,
    this.occupation,
    this.phoneNumber,
    this.secondaryPhoneNumber,
    this.personalEmail,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      // ✅ RECUPERAR ROLES DEL BACKEND
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],

      residentCode: json['residentCode'],
      identityCard: json['identityCard'],
      occupation: json['occupation'],
      phoneNumber: json['phoneNumber'],
      secondaryPhoneNumber: json['secondaryPhone'],
      personalEmail: json['personalEmail'],
    );
  }
}

class AuthService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = AppConfig.apiBaseUrl;

  Future<UserModel> getMe() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await _dio.get(
        '$_baseUrl/api/Users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  Future<void> updateProfile({
    required String fullName,
    File? photo,
    String? residentCode,
    String? identityCard,
    String? occupation,
    String? phoneNumber,
    String? secondaryPhoneNumber,
    String? personalEmail,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');

      final Map<String, dynamic> dataMap = {
        'FullName': fullName,
        'ResidentCode': residentCode, // <--- ENVIAR AL BACKEND
        'IdentityCard': identityCard,
        'Occupation': occupation,
        'PhoneNumber': phoneNumber,
        'SecondaryPhone': secondaryPhoneNumber,
        'PersonalEmail': personalEmail,
      };

      final formData = FormData.fromMap(dataMap);

      if (photo != null) {
        String fileName = photo.path.split('/').last;
        formData.files.add(MapEntry(
          'Photo',
          await MultipartFile.fromFile(photo.path, filename: fileName),
        ));
      }

      await _dio.put(
        '$_baseUrl/api/Users/me',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Error al actualizar');
      }
      throw Exception('Error de conexión: $e');
    }
  }
}
