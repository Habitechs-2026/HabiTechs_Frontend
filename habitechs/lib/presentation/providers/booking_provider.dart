// lib/presentation/providers/booking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/repositories/booking_repository.dart';

/// Área común seleccionada
final selectedAmenityProvider = StateProvider.autoDispose<String>((ref) {
  return 'Parrillero A';
});

/// Día seleccionado en el calendario
final selectedDayProvider = StateProvider.autoDispose<DateTime?>((ref) {
  return null;
});

/// Día enfocado en el calendario
final focusedDayProvider = StateProvider.autoDispose<DateTime>((ref) {
  return DateTime.now();
});

/// Fechas reservadas por área (para pintar puntos en el calendario)
final bookedDatesProvider = FutureProvider.family
    .autoDispose<List<DateTime>, String>((ref, amenity) async {
  final repo = ref.read(bookingRepositoryProvider);
  // ✅ CORRECCIÓN: La llamada al repo ahora solo requiere el amenity
  return repo.getBookedDates(amenity);
});

/// Acción de crear reserva
final bookingActionProvider =
    StateNotifierProvider.autoDispose<BookingActionNotifier, AsyncValue<void>>(
        (ref) {
  return BookingActionNotifier(ref);
});

class BookingActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  BookingActionNotifier(this._ref) : super(const AsyncData(null));

  /// [startTime] y [endTime] vienen en formato "HH:mm"
  Future<void> createBooking(String startTime, String endTime) async {
    final amenity = _ref.read(selectedAmenityProvider.notifier).state;
    final date = _ref.read(selectedDayProvider.notifier).state;

    if (date == null) {
      return;
    }

    state = const AsyncLoading();

    try {
      final repo = _ref.read(bookingRepositoryProvider);

      await repo.createBooking(
        amenity: amenity,
        date: date,
        startTime: startTime,
        endTime: endTime,
      );

      // ✅ ÉXITO: Invalidar el provider de fechas reservadas para forzar la actualización del calendario
      _ref.invalidate(bookedDatesProvider(amenity));

      // Revertir al estado inicial de éxito
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
