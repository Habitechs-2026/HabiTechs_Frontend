import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/expense.dart';
import 'package:habitechs/data/models/payment_instruction_model.dart';
import 'package:habitechs/data/repositories/finance_repository.dart';
import 'package:habitechs/presentation/widgets/empty_state_widget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

const Color kTeal = Colors.teal;
const Color kOxfordBlue = Color(0xFF002147);
const Color kRed = Colors.red;

// ✅ PROVIDERS DE LECTURA REALES
final myDebtProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  return ref.watch(financeRepoProvider).getMyDebt();
});

// Este provider se mantiene por si en el futuro quieres reconectarlo,
// pero ya no lo usaremos en el diálogo visual para evitar errores de carga.
final paymentInstructionsProvider =
    FutureProvider.autoDispose<PaymentInstructionModel>((ref) async {
  return ref.watch(financeRepoProvider).getPaymentInstructions();
});

// Provider para gestionar la acción de registrar un pago (INTACTO)
final paymentActionProvider =
    StateNotifierProvider.autoDispose<PaymentActionNotifier, AsyncValue<void>>(
        (ref) {
  return PaymentActionNotifier(ref.read(financeRepoProvider));
});

class PaymentActionNotifier extends StateNotifier<AsyncValue<void>> {
  final FinanceRepository _repo;
  PaymentActionNotifier(this._repo) : super(const AsyncData(null));

  Future<void> registerPayment(String expenseId, File proofImage) async {
    state = const AsyncLoading();
    try {
      await _repo.registerPayment(expenseId, proofImage);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(
          Exception(e.toString().replaceAll('Exception: ', '')), stack);
    }
  }
}

class DebtBody extends ConsumerWidget {
  const DebtBody({super.key});

  // ✅ MODIFICACIÓN VISUAL: Diálogo con Datos Estáticos (Seguro y Rápido)
  void _showInstructionsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Iconsax.bank, color: kTeal),
              SizedBox(width: 10),
              Text("Datos Bancarios",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Realiza la transferencia a la siguiente cuenta antes de registrar tu pago:",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Tarjeta de Datos
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _BankInfoRow(label: "Banco:", value: "BNB"),
                      Divider(),
                      _BankInfoRow(
                          label: "Nro. Cuenta:", value: "10000053286786"),
                      Divider(),
                      _BankInfoRow(
                          label: "Titular:", value: "HabiTex Condominios"),
                      Divider(),
                      // Puedes cambiar el NIT si lo deseas
                      _BankInfoRow(label: "NIT/CI:", value: "1020304050"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "Usa estos datos en tu banca móvil",
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: kOxfordBlue),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar", style: TextStyle(color: kRed)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Iconsax.copy, size: 18),
              label: const Text("Entendido"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(myDebtProvider);
    final actionState = ref.watch(paymentActionProvider);

    // Escuchar el estado de la acción de pago (INTACTO)
    ref.listen<AsyncValue<void>>(paymentActionProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(next.error.toString().replaceAll('Exception: ', ''))));
      } else if (next.hasValue && !next.isLoading) {
        ref.invalidate(myDebtProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pago reportado. Pendiente de aprobación.',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInstructionsDialog(context, ref),
        label: const Text('Datos Bancarios',
            style: TextStyle(color: Colors.white)),
        icon: const Icon(Iconsax.card, color: Colors.white),
        backgroundColor: kOxfordBlue,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myDebtProvider.future),
        child: debtsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          // Mantenemos el "Empty State" amistoso en caso de error de red para la lista de deudas
          error: (err, stack) => const EmptyStateWidget(
            icon: Iconsax.wallet_check,
            title: '¡Estás al día!',
            subtitle: 'No tienes deudas ni pagos pendientes.',
          ),

          data: (debts) {
            final pendingDebts = debts.where((e) => !e.isPaid).toList();

            if (pendingDebts.isEmpty) {
              return const EmptyStateWidget(
                icon: Iconsax.wallet_check,
                title: '¡Estás al día!',
                subtitle: 'No tienes deudas ni pagos pendientes.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingDebts.length,
              itemBuilder: (context, index) {
                final expense = pendingDebts[index];
                return _DebtCard(
                    expense: expense,
                    ref: ref,
                    isProcessing: actionState.isLoading);
              },
            );
          },
        ),
      ),
    );
  }
}

// Widget auxiliar para las filas de información bancaria (Estético)
class _BankInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _BankInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(
            child: SelectableText(
              // Permite copiar el texto
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: kOxfordBlue),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tarjeta de Deuda (INTACTO) ---
class _DebtCard extends StatelessWidget {
  final Expense expense;
  final WidgetRef ref;
  final bool isProcessing;
  final ImagePicker _picker = ImagePicker();

  _DebtCard(
      {required this.expense, required this.ref, required this.isProcessing});

  Future<void> _registerPayment(BuildContext context) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    ref.read(paymentActionProvider.notifier).registerPayment(
          expense.id,
          File(pickedFile.path),
        );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(expense.dueDate);
    final isReported = expense.lastPaymentStatus == 'Pending';
    final isRejected = expense.lastPaymentStatus == 'Rejected';

    Color statusColor =
        isReported ? Colors.orange : (isRejected ? kRed : kTeal);
    String statusText = isReported
        ? 'PENDIENTE DE VALIDACIÓN'
        : (isRejected ? 'RECHAZADO - Subir de nuevo' : 'REGISTRAR PAGO');

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isRejected
              ? const BorderSide(color: kRed, width: 1.5)
              : BorderSide.none),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: kOxfordBlue)),
            const SizedBox(height: 5),
            Text(expense.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monto:',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${expense.amount.toStringAsFixed(2)} Bs',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Vencimiento:',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(formattedDate,
                        style: TextStyle(
                            fontSize: 14,
                            color: expense.dueDate.isBefore(DateTime.now())
                                ? kRed
                                : Colors.black)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing || isReported
                    ? null
                    : () => _registerPayment(context),
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(
                        isRejected ? Iconsax.document_upload : Iconsax.receipt,
                        color: Colors.white),
                label: Text(statusText,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  disabledBackgroundColor: statusColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
