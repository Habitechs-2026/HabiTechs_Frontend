import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/announcement.dart';
import 'package:habitechs/data/repositories/announcement_repository.dart';
import 'package:habitechs/presentation/providers/admin_provider.dart'; // Para borrar
import 'package:habitechs/presentation/providers/auth_provider.dart'; // Para ver si es admin
import 'package:habitechs/presentation/widgets/empty_state_widget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

const Color kOxfordBlue = Color(0xFF002147);
const Color kTeal = Colors.teal;

final announcementsProvider =
    FutureProvider.autoDispose<List<Announcement>>((ref) async {
  final repo = ref.watch(announcementRepoProvider);
  return repo.getAnnouncements();
});

class AnnouncementsBody extends ConsumerWidget {
  const AnnouncementsBody({super.key});

  // --- Lógica para confirmar y borrar ---
  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Anuncio"),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Cerrar diálogo

              // Ejecutar borrado
              await ref
                  .read(deleteAnnouncementActionProvider.notifier)
                  .execute({'id': id});

              // Recargar lista
              ref.invalidate(announcementsProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Anuncio eliminado"),
                      backgroundColor: Colors.red),
                );
              }
            },
            child:
                const Text("Eliminar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    // Verificamos si es admin UNA VEZ aquí
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Sin AppBar (ya lo tiene el Home)
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $err', textAlign: TextAlign.center),
        )),
        data: (announcements) {
          if (announcements.isEmpty) {
            return const EmptyStateWidget(
              icon: Iconsax.notification,
              title: 'No hay anuncios publicados',
              subtitle: 'Mantente atento a las novedades de la comunidad.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(announcementsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              // ✅ CORRECCIÓN AQUÍ: itemBuilder solo recibe (context, index)
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                // Pasamos el 'ref' y 'isAdmin' que obtuvimos arriba
                return _buildAnnouncementCard(
                    context, ref, announcement, isAdmin);
              },
            ),
          );
        },
      ),
    );
  }

  // Tarjeta
  Widget _buildAnnouncementCard(BuildContext context, WidgetRef ref,
      Announcement announcement, bool isAdmin) {
    // Hora Boliviana (UTC-4)
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(
        announcement.createdAt.toUtc().subtract(const Duration(hours: 4)));

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen (si existe)
          if (announcement.imageUrl != null &&
              announcement.imageUrl!.isNotEmpty)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.network(
                announcement.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey)),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kOxfordBlue,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Columna de Fecha y Botón Borrar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Iconsax.clock,
                                size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),

                        // ✅ BOTÓN DE ELIMINAR (Solo visible si isAdmin es true)
                        if (isAdmin)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: InkWell(
                              onTap: () =>
                                  _confirmDelete(context, ref, announcement.id),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.3))),
                                child: const Row(
                                  children: [
                                    Icon(Iconsax.trash,
                                        size: 14, color: Colors.red),
                                    SizedBox(width: 4),
                                    Text("Borrar",
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Contenido
                Text(
                  announcement.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey[200]),

                // Autor
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: kTeal.withOpacity(0.1),
                      child: const Icon(Iconsax.user, size: 12, color: kTeal),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Publicado por: ${announcement.authorEmail}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
