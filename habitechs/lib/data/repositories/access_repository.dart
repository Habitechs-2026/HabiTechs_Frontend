import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/services/api_service.dart';

class AccessRepository {
  final Dio _dio;
  AccessRepository(this._dio);

  // --- Residente: Generar QR ---
  Future<String> generateQrCode(String visitorName, String identityCard,
      DateTime scheduledAt, DateTime scheduledExit) async {
    try {
      final response = await _dio.post(
        '/api/access/visit/generate-qr',
        data: {
          'visitorName': visitorName,
          'identityCard': identityCard,
          'scheduledAt': scheduledAt.toIso8601String(),
          'scheduledExit': scheduledExit.toIso8601String(),
        },
      );
      if (response.statusCode == 200) {
        return response.data['qrCode'] as String;
      }
      throw Exception('Error al generar QR');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error de red');
    }
  }

  // --- Guardia: Check-In Simple ---
  Future<String> checkInVisit(String qrToken) async {
    try {
      final response = await _dio.post(
        '/api/access/visit/check-in',
        data: {'qrCode': qrToken},
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error de red');
    }
  }

  // --- Guardia: Registrar Paquete ---
  Future<void> registerParcel(String residentEmail, String description) async {
    try {
      await _dio.post(
        '/api/parcel/register',
        data: {
          'residentEmail': residentEmail,
          'description': description,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error de red');
    }
  }

  // --- ¡MÉTODO QUE FALTABA! ---
  Future<String> processVisitAccess({
    required Map<String, dynamic> qrDataMap,
    required bool isApproved,
  }) async {
    try {
      final response = await _dio.post(
        '/api/access/visit/process-access',
        data: {
          'qrData': qrDataMap,
          'isApproved': isApproved,
        },
      );
      return response.data['message'] as String;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Error al procesar acceso');
    }
  }
}

final accessRepoProvider = Provider<AccessRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AccessRepository(dio);
});
