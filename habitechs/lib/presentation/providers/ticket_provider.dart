import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/ticket.dart';
import 'package:habitechs/data/repositories/ticket_repository.dart';

// Lista de Tickets (Se actualiza sola)
final myTicketsProvider = FutureProvider.autoDispose<List<Ticket>>((ref) async {
  final repo = ref.watch(ticketRepoProvider);
  return repo.getMyTickets();
});

// Notificador de Acciones (Crear y Cerrar)
final ticketActionProvider =
    StateNotifierProvider.autoDispose<TicketActionNotifier, AsyncValue<void>>(
        (ref) {
  return TicketActionNotifier(ref);
});

class TicketActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  TicketActionNotifier(this._ref) : super(const AsyncData(null));

  // Crear
  Future<void> createTicket(
      String title, String description, File? image) async {
    state = const AsyncLoading();
    try {
      await _ref
          .read(ticketRepoProvider)
          .createTicket(title, description, image);
      state = const AsyncData(null);
      _ref.invalidate(myTicketsProvider); // Refrescar lista
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  // Cerrar (Nuevo Método)
  Future<void> closeTicket(
      String id, String comment, File? evidenceImage) async {
    state = const AsyncLoading();
    try {
      await _ref
          .read(ticketRepoProvider)
          .closeTicket(id, comment, evidenceImage);
      state = const AsyncData(null);
      _ref.invalidate(myTicketsProvider); // Refrescar lista
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
