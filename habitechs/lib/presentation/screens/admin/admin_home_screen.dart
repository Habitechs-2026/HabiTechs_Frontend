import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

// Definición local de colores (asumo que se usan aquí)
const Color kOxfordBlue = Color(0xFF002147);
const Color kTeal = Colors.teal;

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Fondo gris suave
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Superaccesos",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kOxfordBlue),
            ),
            const SizedBox(height: 8),
            const Text(
              "Gestiona todos los recursos del condominio desde aquí.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // GRILLA DE OPCIONES
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                // 1. GESTIÓN DE USUARIOS Y ROLES (NO SE TOCA, MANTENEMOS EL PUSH NOMBRADO)
                _AdminCard(
                  title: "Usuarios y Roles",
                  icon: Iconsax.user_tag, // Asumo que actualizaste el ícono
                  color: Colors.blue,
                  onTap: () => context
                      .pushNamed('manage-users'), // Ruta de gestión de usuarios
                ),

                // 2. ✅ VALIDAR PAGOS (CORREGIDO: Nueva ruta de gestión de pagos)
                _AdminCard(
                  title: "Validar Pagos",
                  icon: Iconsax.wallet_check,
                  color: Colors.green,
                  // ✅ NAVEGACIÓN CORREGIDA
                  onTap: () => context.push('/admin/validate-payments'),
                ),
                // 3. ✅ CREAR EXPENSA (CORREGIDO)
                _AdminCard(
                  title: "Crear Expensa",
                  icon: Iconsax.money_add,
                  color: kTeal,
                  // ✅ NAVEGACIÓN CORREGIDA
                  onTap: () => context.push('/admin/create-expense'),
                ),
                // 4. TICKETS SOPORTE
                _AdminCard(
                  title: "Tickets Soporte",
                  icon: Iconsax.ticket,
                  color: Colors.orange,
                  onTap: () => context.push('/admin/manage-tickets'),
                ),
                // 5. PUBLICAR ANUNCIO
                _AdminCard(
                  title: "Publicar Anuncio",
                  icon: Iconsax.notification,
                  color: Colors.purple,
                  onTap: () => context.push('/admin/create-announcement'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
