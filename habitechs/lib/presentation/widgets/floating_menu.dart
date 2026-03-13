import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitechs/presentation/providers/auth_provider.dart';
import 'package:habitechs/presentation/screens/home/home_screen.dart'
    hide kTeal, kOxfordBlue;
import 'package:habitechs/presentation/screens/about/about_screen.dart';
import 'package:habitechs/presentation/screens/privacy/privacy_policy_screen.dart';
import 'package:habitechs/presentation/screens/location/share_location_screen.dart';
// ✅ Nueva pantalla para navegar
import 'package:iconsax/iconsax.dart';

const Color kTeal = Colors.teal;
const Color kOxfordBlue = Color(0xFF002147);

final adminMenuExpandedProvider = StateProvider<bool>((ref) =>
    false); // Mantenemos el provider aquí por si las otras pantallas lo necesitan.

class FloatingMenu extends ConsumerWidget {
  const FloatingMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    final currentUser = ref.watch(currentUserProvider);
    final isAdmin =
        currentUser?.roles.contains('Admin') ?? false; // Verificación de rol

    final userName = currentUser?.fullName ?? 'Usuario';
    final userEmail = currentUser?.email ?? '';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final photoUrl = currentUser?.photoUrl;

    return Positioned(
      top: topPadding + 8, // Ajuste para que se vea mejor
      left: 8,
      child: Material(
        color: Colors.transparent,
        elevation: 20,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 290,
          constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kTeal.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              _buildHeader(
                  context, ref, userName, userEmail, userInitial, photoUrl),

              // OPCIONES
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _item(context, ref, Iconsax.home, 'Inicio',
                          () => context.go('/home')),
                      const Divider(),

                      // ✅ Enlace opcional a la gestión de usuarios (si lo necesitas más tarde)
                      if (isAdmin)
                        _item(
                            context,
                            ref,
                            Iconsax.user_octagon,
                            'Gestión de Usuarios',
                            // Navegamos a la ruta de la nueva pantalla
                            () => context.pushNamed('manage-users'),
                            color: kOxfordBlue),

                      // El resto de tus ítems comunes
                      _item(context, ref, Iconsax.call, 'Contactos',
                          () => context.push('/contacts')),
                      _item(
                          context,
                          ref,
                          Iconsax.message_text,
                          'Chat con Administrador',
                          // Corrección de navegación para chat usando contactos
                          () => context.push('/contacts',
                              extra: {'roleFilter': 'Administrador'})),
                      _item(
                          context,
                          ref,
                          Iconsax.shield_tick,
                          'Chat con Seguridad',
                          // Corrección de navegación para chat usando contactos
                          () => context.push('/contacts',
                              extra: {'roleFilter': 'Guardia'})),
                      _item(
                          context,
                          ref,
                          Iconsax.location,
                          'Compartir Ubicación',
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ShareLocationScreen()))),
                      _item(context, ref, Iconsax.book_1, 'Tutorial Asistido',
                          () {
                        ref.read(floatingMenuProvider.notifier).state = false;
                        ref.read(tutorialTriggerProvider.notifier).state++;
                      }),
                      const Divider(),
                      _item(
                          context,
                          ref,
                          Iconsax.info_circle,
                          'Sobre HabiTex',
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AboutScreen()))),
                      _item(
                          context,
                          ref,
                          Iconsax.shield_search,
                          'Política de Privacidad',
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PrivacyPolicyScreen()))),
                      const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Divider()),
                      _item(context, ref, Iconsax.logout, 'Cerrar Sesión', () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      }, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String name,
      String email, String initial, String? photo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 10, 20),
      decoration: const BoxDecoration(
        color: kOxfordBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Align(
              alignment: Alignment.topRight,
              child: InkWell(
                  onTap: () =>
                      ref.read(floatingMenuProvider.notifier).state = false,
                  child: const Icon(Icons.close, color: Colors.white))),
          GestureDetector(
            onTap: () {
              ref.read(floatingMenuProvider.notifier).state = false;
              context.push('/edit-profile');
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: kTeal,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null
                      ? Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                          overflow: TextOverflow.ellipsis),
                      Text(email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Iconsax.edit_2, color: kTeal, size: 18)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, WidgetRef ref, IconData icon, String title,
      VoidCallback onTap,
      {Color color = Colors.black87, bool isBold = false, Color? bgColor}) {
    return Material(
      color: bgColor ?? Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(floatingMenuProvider.notifier).state = false;
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios,
                  color: color.withOpacity(0.3), size: 12)
            ],
          ),
        ),
      ),
    );
  }
}
