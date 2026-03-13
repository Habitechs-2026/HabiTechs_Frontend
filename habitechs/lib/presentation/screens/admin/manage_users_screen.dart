import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/models/user_management_model.dart';
import 'package:habitechs/presentation/providers/user_management_provider.dart';
import 'package:habitechs/presentation/widgets/empty_state_widget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';

const Color kOxfordBlue = Color(0xFF002147);
const Color kTeal = Colors.teal;

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  // --- Diálogo de éxito con opción COMPARTIR ---
  void _showCreationSuccessDialog(
      BuildContext context, WidgetRef ref, Map<String, String> creds) {
    // Función para compartir las credenciales por WhatsApp/Email
    void shareCredentials() {
      final message = "¡Bienvenido a HabiTechs, ${creds['name']}!\n\n"
          "Tus credenciales de acceso al condominio son:\n"
          "Email: ${creds['email']}\n"
          "Contraseña: ${creds['password']}\n\n"
          "Por favor, inicia sesión y actualiza tu perfil.";
      Share.share(message, subject: "Credenciales de Acceso a HabiTechs");
      // Reseteamos el estado después de compartir
      ref.read(creationSuccessCredentialsProvider.notifier).state = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title:
            const Text("Usuario Creado", style: TextStyle(color: Colors.green)),
        content: Text(
            "El usuario ${creds['email']} ha sido creado. Contraseña temporal: ${creds['password']}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(creationSuccessCredentialsProvider.notifier).state =
                  null;
            },
            child: const Text("Cerrar"),
          ),
          ElevatedButton.icon(
            onPressed: shareCredentials,
            icon: const Icon(Iconsax.share, color: Colors.white),
            label: const Text("Compartir Credenciales",
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: kTeal),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final creationSuccess = ref.watch(creationSuccessCredentialsProvider);

    // Escuchamos el estado de creación para mostrar el diálogo de compartir
    if (creationSuccess != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreationSuccessDialog(context, ref, creationSuccess);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Gestión de Usuarios"),
        backgroundColor: kOxfordBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kTeal,
        onPressed: () => _showCreateUserDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (users) {
          if (users.isEmpty) {
            return const EmptyStateWidget(
                icon: Iconsax.people, title: "No hay usuarios");
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(usersListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _UserCard(user: users[index]);
              },
            ),
          );
        },
      ),
    );
  }

  // --- Diálogo de Creación de Usuario ---
  void _showCreateUserDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Residente';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Crear Nuevo Usuario"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: "Nombre Completo")),
                const SizedBox(height: 10),
                TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Email")),
                const SizedBox(height: 10),
                TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                        labelText: "Contraseña Temporal")),
                const SizedBox(height: 15),
                DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'Residente', child: Text('Residente')),
                    DropdownMenuItem(value: 'Guardia', child: Text('Guardia')),
                    DropdownMenuItem(
                        value: 'Admin', child: Text('Administrador')),
                  ],
                  onChanged: (v) => setState(() => selectedRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kTeal),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(userActionProvider.notifier).createUser(
                    emailCtrl.text.trim(),
                    nameCtrl.text.trim(),
                    passCtrl.text.trim(),
                    selectedRole);
              },
              child: const Text("Crear", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tarjeta de Usuario y Menú de Opciones ---
class _UserCard extends ConsumerWidget {
  final UserManagementModel user;
  const _UserCard({required this.user});

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Gestionar: ${user.fullName}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            // 1. Roles (Promover/Degradar)
            ListTile(
              leading: Icon(user.roles.contains('Admin')
                  ? Icons.remove_moderator
                  : Icons.add_moderator),
              title: Text(user.roles.contains('Admin')
                  ? "Quitar Admin"
                  : "Promover a Admin"),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(userActionProvider.notifier).toggleRole(
                    user.id, 'Admin', !user.roles.contains('Admin'));
              },
            ),
            ListTile(
              leading: Icon(user.roles.contains('Guardia')
                  ? Iconsax.shield_cross
                  : Iconsax.shield_tick),
              title: Text(user.roles.contains('Guardia')
                  ? "Quitar Guardia"
                  : "Promover a Guardia"),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(userActionProvider.notifier).toggleRole(
                    user.id, 'Guardia', !user.roles.contains('Guardia'));
              },
            ),

            const Divider(),

            // 2. Suspender / Activar
            ListTile(
              leading: Icon(user.isActive ? Icons.block : Icons.check_circle,
                  color: user.isActive ? Colors.red : Colors.green),
              title: Text(user.isActive
                  ? "Suspender Cuenta (Robo)"
                  : "Reactivar Cuenta"),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(userActionProvider.notifier)
                    .toggleStatus(user.id, !user.isActive);
              },
            ),

            // 3. Reset Password
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text("Restablecer Contraseña"),
              onTap: () {
                Navigator.pop(ctx);
                _showResetPasswordDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, WidgetRef ref) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nueva Contraseña"),
        content: TextField(
          controller: passCtrl,
          decoration:
              const InputDecoration(labelText: "Ingresa la nueva contraseña"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(userActionProvider.notifier)
                  .resetPassword(user.id, passCtrl.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Contraseña cambiada")));
            },
            child: const Text("Cambiar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isAdmin = user.roles.contains('Admin');
    final bool isGuard = user.roles.contains('Guardia');
    final bool isSuspended = !user.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isSuspended ? Colors.red.shade100 : kTeal.withOpacity(0.1),
          child: Icon(
            isSuspended ? Iconsax.user_minus : Iconsax.user,
            color: isSuspended ? Colors.red : kTeal,
          ),
        ),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSuspended ? Colors.grey : Colors.black87,
            decoration: isSuspended ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                if (isAdmin)
                  const _RoleBadge(text: "Admin", color: Colors.orange),
                if (isGuard)
                  const _RoleBadge(text: "Guardia", color: Colors.blue),
                if (!isAdmin && !isGuard)
                  const _RoleBadge(text: "Residente", color: Colors.green),
                if (isSuspended)
                  const _RoleBadge(text: "SUSPENDIDO", color: Colors.red),
              ],
            )
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptions(context, ref),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _RoleBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
