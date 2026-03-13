import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/presentation/providers/booking_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // --- MÉTODOS HELPER (Sin cambios, funcionan perfecto) ---

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        if (_endTime != null) {
          final startMin = _startTime!.hour * 60 + _startTime!.minute;
          final endMin = _endTime!.hour * 60 + _endTime!.minute;
          if (endMin <= startMin) {
            _endTime = null;
          }
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _isTimeRangeValid {
    if (_startTime == null || _endTime == null) return false;
    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;
    return endMin > startMin;
  }

  // --- FIN MÉTODOS HELPER ---

  @override
  Widget build(BuildContext context) {
    final selectedAmenity = ref.watch(selectedAmenityProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    // Provider que trae las fechas ocupadas (puntos rojos)
    final bookedDatesAsync = ref.watch(bookedDatesProvider(selectedAmenity));
    final bookingActionState = ref.watch(bookingActionProvider);

    // ✅ LISTENER INTELIGENTE: Escucha cambios en el estado de la reserva
    ref.listen<AsyncValue<void>>(bookingActionProvider, (previous, next) {
      // 1. Si hubo error (ej: Conflicto de horario)
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // 2. Si fue exitoso (Data y no Loading)
      else if (!next.isLoading && !next.hasError && next.hasValue) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Reserva realizada con éxito!'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refrescamos los puntos rojos para que aparezca la nueva reserva
        ref.invalidate(bookedDatesProvider(selectedAmenity));

        // Opcional: Limpiar selección de horas
        setState(() {
          _startTime = null;
          _endTime = null;
        });
      }
    });

    final amenities = ['Parrillero A', 'Salón de Fiestas', 'Piscina'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- 1. Selector de Área (Amenity) ---
          DropdownButtonFormField<String>(
            initialValue: selectedAmenity,
            decoration: const InputDecoration(
              labelText: 'Área Común',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Iconsax.building_3),
            ),
            items: amenities.map((String amenity) {
              return DropdownMenuItem<String>(
                value: amenity,
                child: Text(amenity),
              );
            }).toList(),
            onChanged: (String? newValue) {
              ref.read(selectedAmenityProvider.notifier).state = newValue!;
              ref.read(selectedDayProvider.notifier).state = null;
              ref.read(focusedDayProvider.notifier).state = DateTime.now();
              setState(() {
                _startTime = null;
                _endTime = null;
              });
            },
          ),
          const SizedBox(height: 20),

          // --- 2. El Calendario ---
          Card(
            elevation: 2,
            child: TableCalendar(
              locale: 'es_ES',
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              onDaySelected: (newSelectedDay, newFocusedDay) {
                if (newSelectedDay.isBefore(
                    DateTime.now().subtract(const Duration(hours: 1)))) {
                  return;
                }

                ref.read(selectedDayProvider.notifier).state = newSelectedDay;
                ref.read(focusedDayProvider.notifier).state = newFocusedDay;
                setState(() {
                  _startTime = null;
                  _endTime = null;
                });
              },
              onPageChanged: (newFocusedDay) {
                ref.read(focusedDayProvider.notifier).state = newFocusedDay;
              },
              // ✅ Lógica de los puntos rojos
              eventLoader: (day) {
                return bookedDatesAsync.when(
                  data: (bookedDates) {
                    for (var bookedDate in bookedDates) {
                      if (isSameDay(bookedDate, day)) {
                        return [const SizedBox()]; // Retorna un marcador dummy
                      }
                    }
                    return [];
                  },
                  loading: () => [],
                  error: (e, s) => [],
                );
              },
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.red[700], // Color del punto rojo
                  shape: BoxShape.circle,
                ),
                disabledTextStyle:
                    TextStyle(color: Colors.grey.withOpacity(0.5)),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 3. Selector de Hora DESDE / HASTA ---
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Horario de reserva',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selectedDay == null ? null : _pickStartTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _startTime == null ? 'Desde' : _startTime!.format(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (selectedDay == null || _startTime == null)
                      ? null
                      : _pickEndTime,
                  icon: const Icon(Icons.access_time_filled),
                  label: Text(
                    _endTime == null ? 'Hasta' : _endTime!.format(context),
                  ),
                ),
              ),
            ],
          ),
          if (_startTime != null && _endTime != null && !_isTimeRangeValid)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'La hora de fin debe ser mayor que la de inicio.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),

          // --- 4. Botón de Reservar ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: (selectedDay == null ||
                    _startTime == null ||
                    _endTime == null ||
                    !_isTimeRangeValid ||
                    bookingActionState.isLoading)
                ? null
                : () {
                    final startStr = _formatTime(_startTime!);
                    final endStr = _formatTime(_endTime!);

                    // Llamamos a la acción (el Listener arriba manejará el resultado)
                    ref
                        .read(bookingActionProvider.notifier)
                        .createBooking(startStr, endStr);
                  },
            child: bookingActionState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    selectedDay == null
                        ? 'Selecciona un día'
                        : (!_isTimeRangeValid ||
                                _startTime == null ||
                                _endTime == null)
                            ? 'Selecciona horario'
                            : 'Reservar ${DateFormat('dd/MM').format(selectedDay)} '
                                '(${_formatTime(_startTime!)} - ${_formatTime(_endTime!)})',
                  ),
          ),
        ],
      ),
    );
  }
}
