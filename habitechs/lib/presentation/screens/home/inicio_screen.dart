import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Importamos el provider para saber si es Admin
import 'package:habitechs/presentation/providers/auth_provider.dart';
// Importamos la nueva pantalla de gestión de usuarios
// Asumo que selectedTabProvider está en home_screen.dart y lo importamos
import 'package:habitechs/presentation/screens/home/home_screen.dart'
    hide kTeal, kOxfordBlue;
import 'package:iconsax/iconsax.dart';

// Definición local de colores
const Color kTeal = Colors.teal;
const Color kOxfordBlue = Color(0xFF002147); // Añadimos color para Admin

// Esta es la Pestaña 0: El Dashboard Principal
class InicioBody extends ConsumerWidget {
  const InicioBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goToTab(int tabIndex) {
      ref.read(selectedTabProvider.notifier).state = tabIndex;
    }

    // ✅ CLAVE: Verificamos si el usuario es Admin
    final isAdmin = ref.watch(isAdminProvider);

    // Lista dinámica de elementos de menú (solo los que van a GridView)
    final List<Map<String, dynamic>> residentMenuItems = [
      {
        'icon': Iconsax.notification,
        'title': 'Anuncios',
        'subtitle': 'Avisos de la comunidad',
        'onTap': () => goToTab(1)
      },
      {
        'icon': Iconsax.scan_barcode,
        'title': 'Mi QR',
        'subtitle': 'Código de acceso',
        'onTap': () => goToTab(5)
      },
      {
        'icon': Iconsax.message_question,
        'title': 'Tickets',
        'subtitle': 'Reportes y solicitudes',
        'onTap': () => goToTab(4)
      },
      {
        'icon': Iconsax.calendar_1,
        'title': 'Reservas',
        'subtitle': 'Áreas comunes',
        'onTap': () => goToTab(3)
      },
      {
        'icon': Iconsax.wallet_money,
        'title': 'Finanzas',
        'subtitle': 'Pagos y estados',
        'onTap': () => goToTab(2)
      },
      {
        'icon': Iconsax.call,
        'title': 'Contactos',
        'subtitle': 'Directorio',
        'onTap': () => context.push('/contacts')
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =======================================================
          // ✅ BLOQUE DE SUPERACCESOS (ADMIN)
          // =======================================================
          if (isAdmin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: "SUPERACCESOS"),
                const SizedBox(height: 12),

                // Botón Único de Gestión de Usuarios
                _buildMenuCard(
                  context: context,
                  icon: Iconsax.user_octagon,
                  title: 'Gestión de Usuarios',
                  subtitle: 'Crear, promover, suspender cuentas',
                  color: kOxfordBlue,
                  // ✅ NAVEGACIÓN A RUTA NOMBRADA: manage-users
                  onTap: () => context.pushNamed('manage-users'),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
              ],
            ),
          // =======================================================

          // Gridview de elementos para Residentes
          const _SectionHeader(title: "SERVICIOS RESIDENTE"),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: residentMenuItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final item = residentMenuItems[index];
              return _buildMenuCard(
                context: context,
                icon: item['icon'] as IconData,
                title: item['title'] as String,
                subtitle: item['subtitle'] as String,
                onTap: item['onTap'] as VoidCallback,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = kTeal, // Nuevo parámetro de color
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase auxiliar para el título de sección
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF0F766E), width: 4)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
