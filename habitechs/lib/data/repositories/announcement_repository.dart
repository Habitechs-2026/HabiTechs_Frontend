import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/announcement.dart';
import 'package:habitechs/data/services/api_service.dart';

class AnnouncementRepository {
  final Dio _dio;

  AnnouncementRepository(this._dio);

  // Obtener Anuncios
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await _dio.get('/api/Announcements');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Announcement.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar anuncios');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  // Crear Anuncio
  Future<void> createAnnouncement(
      String title, String content, File? image) async {
    try {
      final formData = FormData.fromMap({
        'Title': title,
        'Content': content,
      });

      if (image != null) {
        String fileName = image.path.split('/').last;
        formData.files.add(MapEntry(
          'Image',
          await MultipartFile.fromFile(image.path, filename: fileName),
        ));
      }

      final response = await _dio.post('/api/Announcements', data: formData);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Error al crear anuncio. Código: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message']
          : 'Error de red al crear anuncio';
      throw Exception(msg);
    }
  }

  // --- ✅ NUEVO: ELIMINAR ANUNCIO ---
  Future<void> deleteAnnouncement(String id) async {
    try {
      final response = await _dio.delete('/api/Announcements/$id');

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar anuncio');
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Error de red al eliminar');
    }
  }
}

final announcementRepoProvider = Provider<AnnouncementRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AnnouncementRepository(dio);
});
