import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/pending_approval.dart';
import 'package:habitechs/presentation/providers/admin_provider.dart';
import 'package:habitechs/presentation/widgets/empty_state_widget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

const Color kTeal = Colors.teal;
const Color kRed = Colors.red;
const Color kOxfordBlue = Color(0xFF002147);

class ValidatePaymentsScreen extends ConsumerWidget {
  const ValidatePaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingApprovalsProvider);

    // Observamos las acciones de aprobar/rechazar para recargar la lista
    ref.listen<AsyncValue<void>>(approvePaymentActionProvider, (prev, next) {
      if (next.hasValue) {
        ref.invalidate(pendingApprovalsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pago APROBADO y deuda saldada.',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green));
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error al aprobar: ${next.error.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: kRed));
      }
    });

    ref.listen<AsyncValue<void>>(rejectPaymentActionProvider, (prev, next) {
      if (next.hasValue) {
        ref.invalidate(pendingApprovalsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Pago RECHAZADO. El residente debe subir un nuevo comprobante.',
                style: TextStyle(color: Colors.white)),
            backgroundColor: kRed));
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error al rechazar: ${next.error.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: kRed));
      }
    });

    return Scaffold(
      // ❌ REMOVER 'const' del PreferredSize
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        // ❌ REMOVER 'const' del AppBar (Línea 42 del error)
        child: AppBar(
          title: const Text("Validar Pagos Pendientes",
              style: TextStyle(color: Colors.white)),
          backgroundColor: kOxfordBlue,
          foregroundColor: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(pendingApprovalsProvider.future),
        child: pendingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error al cargar validaciones: $err')),
          data: (approvals) {
            if (approvals.isEmpty) {
              return const EmptyStateWidget(
                icon: Iconsax.wallet_check,
                title: 'Todo al día',
                subtitle: 'No hay comprobantes pendientes de validación.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: approvals.length,
              itemBuilder: (context, index) {
                return _ApprovalCard(approval: approvals[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

// --- Tarjeta de Aprobación Pendiente ---
class _ApprovalCard extends ConsumerWidget {
  final PendingApproval approval;
  const _ApprovalCard({required this.approval});

  void _showProofImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        title: const Text("Comprobante de Pago"),
        content: approval.proofImageUrl.isNotEmpty
            ? Image.network(approval.proofImageUrl, fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: Center(
                        child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null)));
              })
            : const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Error: No se encontró la imagen de comprobante.'),
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = approval.expense.amount.toStringAsFixed(2);
    final paymentDate =
        DateFormat('dd MMM, hh:mm a').format(approval.paymentDate);

    final isProcessing = ref.watch(approvePaymentActionProvider).isLoading ||
        ref.watch(rejectPaymentActionProvider).isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pago de ${approval.residentEmail}",
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: kOxfordBlue)),
            const SizedBox(height: 5),
            Text("Expensa: ${approval.expense.title}",
                style: const TextStyle(fontSize: 14)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monto Reportado:',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('$amount Bs',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTeal)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Fecha Reporte:',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(paymentDate, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Botón para ver el comprobante
                TextButton.icon(
                  onPressed:
                      isProcessing ? null : () => _showProofImage(context),
                  icon: const Icon(Iconsax.eye),
                  label: const Text('Ver Comprobante'),
                ),

                // Botón APROBAR
                ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () {
                          ref
                              .read(approvePaymentActionProvider.notifier)
                              .execute({'paymentId': approval.paymentId});
                        },
                  icon:
                      const Icon(Iconsax.check, color: Colors.white, size: 20),
                  label: Text(isProcessing ? 'Procesando...' : 'Aprobar',
                      style: const TextStyle(color: Colors.white)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),

                // Botón RECHAZAR
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () {
                          ref
                              .read(rejectPaymentActionProvider.notifier)
                              .execute({'paymentId': approval.paymentId});
                        },
                  child: Text('Rechazar', style: TextStyle(color: kRed)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
