import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/ticket.dart'; // Importar modelo Ticket
import 'package:habitechs/presentation/providers/admin_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';

class ManageTicketsScreen extends ConsumerWidget {
  const ManageTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(allTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Tickets'),
      ),
      body: ticketsAsync.when(
        loading: () => Center(
            child: Lottie.asset('assets/animations/loading.json', width: 150)),
        error: (e, s) => Center(child: Text('Error: ${e.toString()}')),
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(child: Text('No hay tickets reportados.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allTicketsProvider),
            child: ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final bool isOpen = ticket.status == 'Open';

                return Card(
                  color: isOpen ? Colors.white : Colors.green.shade50,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(ticket.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'Reportado por: ${ticket.requesterEmail}\n${ticket.description}'),
                    isThreeLine: true,
                    trailing: isOpen
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF20B2AA),
                                foregroundColor: Colors.white),
                            child: const Text('Cerrar'),
                            onPressed: () {
                              // ABRIR DIÁLOGO DE CIERRE
                              _showCloseDialog(context, ref, ticket);
                            },
                          )
                        : const Icon(Iconsax.tick_circle, color: Colors.green),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // --- DIÁLOGO PARA PEDIR COMENTARIO OBLIGATORIO ---
  void _showCloseDialog(BuildContext context, WidgetRef ref, Ticket ticket) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Ticket"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Ingresa la solución o motivo de cierre para finalizar:"),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: "Comentario de resolución",
                hintText: "Ej. Se reparó la baranda...",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validación simple
              if (commentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("El comentario es obligatorio"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Cerrar el diálogo primero
              Navigator.pop(ctx);

              // Ejecutar la acción
              await ref.read(closeTicketActionProvider.notifier).execute({
                'id': ticket.id,
                'comment': commentController.text.trim(),
                'evidenceImage': null // Opcional por ahora
              });

              // Refrescar la lista para ver el cambio a verde
              ref.invalidate(allTicketsProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ticket cerrado correctamente"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }
}
