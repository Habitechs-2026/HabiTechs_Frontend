import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/ticket.dart';
import 'package:habitechs/data/services/api_service.dart';

class TicketRepository {
  final Dio _dio;
  TicketRepository(this._dio);

  // --- Obtener Tickets ---
  // (Si eres Admin/Guardia el backend te devolverá TODOS, si eres Residente solo los TUYOS)
  Future<List<Ticket>> getMyTickets() async {
    try {
      final response = await _dio.get('/api/Tickets');
      final List<dynamic> data = response.data;
      return data.map((json) => Ticket.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al cargar tickets');
    }
  }

  // --- Crear Ticket (Soporta [FromForm] del Backend) ---
  Future<void> createTicket(
      String title, String description, File? image) async {
    try {
      // Usamos FormData para cumplir con el [FromForm] del backend
      final formData = FormData.fromMap({
        'Title': title,
        'Description': description,
      });

      if (image != null) {
        String fileName = image.path.split('/').last;
        formData.files.add(MapEntry(
          'Image', // Debe coincidir con la propiedad IFormFile del C#
          await MultipartFile.fromFile(image.path, filename: fileName),
        ));
      }

      await _dio.post('/api/Tickets', data: formData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al crear ticket');
    }
  }

  // --- Cerrar Ticket (Con Comentario Obligatorio) ---
  Future<void> closeTicket(
      String id, String comment, File? evidenceImage) async {
    try {
      final formData = FormData.fromMap({
        'Comment': comment,
      });

      if (evidenceImage != null) {
        String fileName = evidenceImage.path.split('/').last;
        formData.files.add(MapEntry(
          'EvidenceImage',
          await MultipartFile.fromFile(evidenceImage.path, filename: fileName),
        ));
      }

      // Validamos el status 200 manualmente para evitar pausas en VS Code
      final response = await _dio.put('/api/Tickets/$id/close', data: formData);

      if (response.statusCode != 200) {
        throw Exception('Error: El servidor respondió ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al cerrar ticket');
    }
  }
}

final ticketRepoProvider = Provider<TicketRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TicketRepository(dio);
});
