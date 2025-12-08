import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/data/storage/secure_storage_service.dart';
import 'package:habitechs/presentation/providers/auth_provider.dart';

// Pantallas
import 'package:habitechs/presentation/screens/auth/edit_profile_screen.dart';
import 'package:habitechs/presentation/screens/auth/login_screen.dart';
import 'package:habitechs/presentation/screens/splash/splash_screen.dart';
import 'package:habitechs/presentation/screens/home/home_screen.dart';
import 'package:habitechs/presentation/screens/guard/guard_home_screen.dart';
import 'package:habitechs/presentation/screens/guard/scan_qr_screen.dart';
import 'package:habitechs/presentation/screens/guard/register_parcel_screen.dart';
// Admin
import 'package:habitechs/presentation/screens/admin/admin_home_screen.dart';
import 'package:habitechs/presentation/screens/admin/manage_tickets_screen.dart';
import 'package:habitechs/presentation/screens/admin/create_announcement_screen.dart';
import 'package:habitechs/presentation/screens/admin/create_expense_screen.dart';
import 'package:habitechs/presentation/screens/admin/manage_users_screen.dart';
import 'package:habitechs/presentation/screens/admin/manage_expenses_screen.dart';
import 'package:habitechs/presentation/screens/admin/validate_payments_screen.dart';
// Comunes
import 'package:habitechs/presentation/screens/contacts/contacts_screen.dart';
import 'package:habitechs/presentation/screens/community/chat_screen.dart';
// Chatbot
import 'package:habitechs/presentation/screens/community/chatbot_screen.dart'; // Importación correcta

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final storage = ref.read(secureStorageProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) async {
      final location = state.matchedLocation;

      if (authState == AuthStatus.unknown) return '/splash';

      // --- ZONA PÚBLICA (Sin Login) ---
      if (authState == AuthStatus.unauthenticated) {
        if (location == '/login' || location == '/chatbot') {
          return null;
        }
        return '/login';
      }

      // --- ZONA PRIVADA (Con Login) ---
      if (authState == AuthStatus.authenticated) {
        if (location == '/login' ||
            location == '/splash' ||
            location == '/chatbot') {
          final role = await storage.readRole();
          if (role == 'Guardia') return '/guard/home';
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // ✅ CORRECCIÓN AQUÍ: Quitamos el 'Text' y ponemos la pantalla real
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const HabiTexChatbot(),
      ),

      // Home Compartido
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen()),

      // Rutas Guardia
      GoRoute(
          path: '/guard/home',
          builder: (context, state) => const GuardHomeScreen()),
      GoRoute(
          path: '/guard/scan-qr',
          builder: (context, state) => const ScanQrScreen()),
      GoRoute(
          path: '/guard/register-parcel',
          builder: (context, state) => const RegisterParcelScreen()),

      // Rutas Admin
      GoRoute(
          path: '/admin/home',
          builder: (context, state) => const AdminHomeScreen()),
      GoRoute(
          path: '/admin/manage-tickets',
          builder: (context, state) => const ManageTicketsScreen()),
      GoRoute(
          path: '/admin/create-announcement',
          builder: (context, state) => const CreateAnnouncementScreen()),

      // Rutas Finanzas
      GoRoute(
          path: '/admin/create-expense',
          builder: (context, state) => const CreateExpenseScreen()),

      GoRoute(
          path: '/admin/validate-payments',
          name: 'validate-payments',
          builder: (context, state) => const ValidatePaymentsScreen()),

      GoRoute(
          path: '/admin/manage-users',
          name: 'manage-users',
          builder: (context, state) => const ManageUsersScreen()),

      GoRoute(
          path: '/admin/manage-expenses',
          builder: (context, state) => const ManageExpensesScreen()),

      // Comunes
      GoRoute(
        path: '/contacts',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ContactsScreen(roleFilter: extra?['roleFilter'] as String?);
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return ChatScreen(
            otherUserId: extra['userId'] ?? '',
            otherUserName: extra['userName'] ?? 'Usuario',
          );
        },
      ),
    ],
  );
});
