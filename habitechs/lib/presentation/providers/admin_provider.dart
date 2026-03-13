import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/ticket.dart';
import 'package:habitechs/data/models/expense.dart';
import 'package:habitechs/data/models/pending_approval.dart';
import 'package:habitechs/data/repositories/ticket_repository.dart';
import 'package:habitechs/data/repositories/finance_repository.dart';
import 'package:habitechs/data/repositories/announcement_repository.dart';
import 'package:habitechs/data/repositories/identity_repository.dart';

// --- Providers de LECTURA (GET) ---

final allTicketsProvider =
    FutureProvider.autoDispose<List<Ticket>>((ref) async {
  return ref.watch(ticketRepoProvider).getMyTickets();
});

final allExpensesProvider =
    FutureProvider.autoDispose<List<Expense>>((ref) async {
  return ref.watch(financeRepoProvider).getAllExpenses();
});

final pendingApprovalsProvider =
    FutureProvider.autoDispose<List<PendingApproval>>((ref) async {
  return ref.watch(financeRepoProvider).getPendingApprovals();
});

// --- Providers de ACCIÓN (POST/PUT/DELETE) ---

final announcementActionProvider =
    StateNotifierProvider.autoDispose<AdminActionNotifier, AsyncValue<void>>(
        (ref) {
  return AdminActionNotifier((data) {
    return ref.read(announcementRepoProvider).createAnnouncement(
          data['title'],
          data['content'],
          data['image'],
        );
  });
});

final closeTicketActionProvider =
    StateNotifierProvider.autoDispose<AdminActionNotifier, AsyncValue<void>>(
        (ref) {
  return AdminActionNotifier((data) {
    return ref.read(ticketRepoProvider).closeTicket(
          data['id'],
          data['comment'],
          data['evidenceImage'],
        );
  });
});

// 5. Provider para la ACCIÓN de cargar expensa
final expenseActionProvider =
    StateNotifierProvider.autoDispose<AdminActionNotifier, AsyncValue<void>>(
        (ref) {
  return AdminActionNotifier((data) => ref
      .read(financeRepoProvider)
      .createExpense(
          data['email'], data['title'], data['amount'], data['date']));
});

final assignRoleActionProvider =
    StateNotifierProvider.autoDispose<AdminActionNotifier, AsyncValue<void>>(
        (ref) {
  return AdminActionNotifier(
      (data) => ref.read(identityRepoProvider).assignGuardRole(data['email']));
});

// 7. Provider para la ACCIÓN de marcar como pagado
final markAsPaidActionProvider =
    StateNotifierProvider.autoDispose<AdminActionNotifier, AsyncValue<void>>(
        (ref) {
  return AdminActionNotifier(
      (data) => ref.read(financeRepoProvider).markExpenseAsPaid(data['id']));
});

final deleteAnnouncementActionProvider =
    StateNotifierProvider.autoDispose<AdminActionNotifier, AsyncValue<void>>(
        (ref) {
  return AdminActionNotifier((data) =>
      ref.read(announcementRepoProvider).deleteAnnouncement(data['id']));
});

final approvePaymentActionProvider =
    StateNotifierProvider.autoDispose<AdminActionNotifier, AsyncValue<void>>(
        (ref) {
  return AdminActionNotifier((data) =>
      ref.read(financeRepoProvider).approvePayment(data['paymentId']));
});

final rejectPaymentActionProvider =
    StateNotifierProvider.autoDispose<AdminActionNotifier, AsyncValue<void>>(
        (ref) {
  return AdminActionNotifier(
      (data) => ref.read(financeRepoProvider).rejectPayment(data['paymentId']));
});

// --- Notificador GENÉRICO (SIMPLIFICADO PARA EVITAR CONFLICTOS DE TIPO) ---
typedef AdminActionCallback = Future<void> Function(Map<String, dynamic> data);

class AdminActionNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminActionCallback _actionCallback;

  AdminActionNotifier(this._actionCallback) : super(const AsyncData(null));

  Future<void> execute(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await _actionCallback(data);
      state = const AsyncData(null);
    } catch (e, stack) {
      // ✅ CORRECCIÓN FINAL: Simplemente enviamos la excepción 'e' tal como viene.
      // El repositorio ya se encargó de envolver la respuesta de Dio como Exception(String).
      state = AsyncError(e, stack);
    }
  }
}
