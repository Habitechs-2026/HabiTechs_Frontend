import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// Ocultamos para usar definiciones locales
import 'package:habitechs/data/models/ticket.dart';
import 'package:habitechs/data/repositories/ticket_repository.dart';
import 'package:habitechs/presentation/widgets/top_toast.dart'; // Asegúrate de tener este widget o usar SnackBar normal
import 'package:habitechs/presentation/widgets/empty_state_widget.dart'; // Widget de vacío
import 'package:iconsax/iconsax.dart';

// Definición local de colores
const Color kTeal = Colors.teal;
const Color kOxfordBlue = Color(0xFF002147);

// Provider para recargar la lista de tickets
final myTicketsProvider = FutureProvider.autoDispose<List<Ticket>>((ref) async {
  final repo = ref.watch(ticketRepoProvider);
  return repo.getMyTickets();
});

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Botón flotante para CREAR ticket
      floatingActionButton: FloatingActionButton(
        backgroundColor: kOxfordBlue,
        onPressed: () => _showCreateTicketDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $err', textAlign: TextAlign.center),
        )),
        data: (tickets) {
          if (tickets.isEmpty) {
            return const EmptyStateWidget(
              icon: Iconsax.ticket,
              title: 'No hay tickets registrados',
              subtitle: 'Usa el botón (+) para reportar un problema.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myTicketsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _buildTicketCard(ticket);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    Color statusColor = Colors.grey;
    String statusText = "Desconocido";
    IconData statusIcon = Iconsax.clock;

    if (ticket.status == 'Open') {
      statusColor = Colors.orange;
      statusText = "Abierto";
      statusIcon = Iconsax.clock;
    } else if (ticket.status == 'Closed') {
      statusColor = Colors.green;
      statusText = "Cerrado";
      statusIcon = Iconsax.tick_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ticket.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.description,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.user, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ticket.requesterEmail,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(ticket.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showCreateTicketDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateTicketDialog(ref: ref),
    );
  }
}

// --- DIÁLOGO DE CREACIÓN ---
class _CreateTicketDialog extends StatefulWidget {
  final WidgetRef ref;
  const _CreateTicketDialog({required this.ref});

  @override
  State<_CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<_CreateTicketDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Título y descripción son obligatorios")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = widget.ref.read(ticketRepoProvider);

      await repo.createTicket(
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedImage,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo

        // Intentar usar TopToast si existe, si no, SnackBar
        try {
          showTopToast(context,
              title: "¡Ticket Creado!",
              body: "Tu reporte ha sido enviado correctamente.");
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Ticket creado exitosamente"),
                backgroundColor: Colors.green),
          );
        }

        // Recargar la lista
        widget.ref.invalidate(myTicketsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Nuevo Ticket", textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Asunto (ej. Foco pasillo)",
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Descripción del problema",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey, size: 30),
                          SizedBox(height: 8),
                          Text("Adjuntar foto (Opcional)",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kTeal,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text("Enviar", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
