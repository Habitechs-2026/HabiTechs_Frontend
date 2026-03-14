import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/services/api_service.dart';

class BookingRepository {
  final Dio _dio;

  BookingRepository(this._dio);

  Future<List<DateTime>> getBookedDates(String amenity) async {
    try {
      final now = DateTime.now();
      final response = await _dio.get(
        '/api/Booking/availability',
        queryParameters: {
          'amenityName': amenity,
          'month': '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
        },
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
        '/api/Booking',
        data: {
          'AmenityName': amenity,
          'BookingDate':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    String msg = 'Error de conexión';
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data['message'] != null) {
          msg = data['message'].toString();
        } else if (data['title'] != null) {
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
