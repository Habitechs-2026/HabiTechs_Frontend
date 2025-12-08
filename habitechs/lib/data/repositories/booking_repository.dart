import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/services/api_service.dart';

class BookingRepository {
  final Dio _dio;

  BookingRepository(this._dio);

  // ✅ CORRECCIÓN: Ruta ajustada a '/api/Booking' (Singular, coincide con C# Controller)
  Future<List<DateTime>> getBookedDates(String amenity) async {
    try {
      final response = await _dio.get(
        '/api/Booking/dates',
        queryParameters: {'amenity': amenity},
      );

      final data = response.data as List<dynamic>;
      return data.map((e) => DateTime.parse(e.toString())).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createBooking({
    required String amenity,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      await _dio.post(
        '/api/Booking', // ✅ Ruta ajustada a singular
        data: {
          'AmenityName': amenity,
          'BookingDate': date.toIso8601String(),
          'StartTime': startTime,
          'EndTime': endTime,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Manejo robusto de errores del Backend (.NET)
  Exception _handleError(DioException e) {
    String msg = 'Error de conexión';
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;

      // Intentamos extraer el mensaje limpio que manda el backend
      if (data is Map) {
        if (data['message'] != null) {
          msg = data['message'].toString();
        } else if (data['title'] != null) {
          // A veces .NET manda el error en 'title' si es un 400 automático
          msg = data['title'].toString();
        } else if (data['errors'] != null) {
          msg = data['errors'].toString();
        }
      } else {
        msg = data.toString();
      }
    }
    return Exception(msg);
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BookingRepository(dio);
});
