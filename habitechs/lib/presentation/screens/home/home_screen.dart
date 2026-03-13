import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Ocultamos para evitar conflictos
import 'package:habitechs/presentation/providers/auth_provider.dart';
import 'package:habitechs/presentation/widgets/floating_menu.dart';
import 'package:habitechs/presentation/widgets/tutorial_overlay.dart'; // Widget Overlay
import 'package:habitechs/core/utils/tutorial_keys.dart'; // Keys Globales
import 'package:shared_preferences/shared_preferences.dart'; // Para guardar estado "visto"
// Importar AuthService

// Pantallas
import 'package:habitechs/presentation/screens/community/announcements_screen.dart';
import 'package:habitechs/presentation/screens/finance/debt_screen.dart';
import 'package:habitechs/presentation/screens/bookings/bookings_screen.dart';
import 'package:habitechs/presentation/screens/community/tickets_screen.dart'
    hide kTeal, kOxfordBlue; // CORRECCIÓN: Ocultar colores exportados
import 'package:habitechs/presentation/screens/access/qr_screen.dart';
import 'package:habitechs/presentation/screens/admin/admin_home_screen.dart';
// CORRECCIÓN: Ocultar colores exportados
import 'package:iconsax/iconsax.dart';

// Definición local de colores
const Color kTeal = Colors.teal;
const Color kOxfordBlue = Color(0xFF002147);

final selectedTabProvider = StateProvider<int>((ref) => 0);
final floatingMenuProvider = StateProvider<bool>((ref) => false);
// Trigger para iniciar tutorial manualmente (Tutorial Largo)
final tutorialTriggerProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusAnimController;
  OverlayEntry? _overlayEntry;

  int _currentStepIndex = 0;
  List<TutorialStep> _currentSteps = []; // Lista actual de pasos a ejecutar
  bool _isTutorialActive = false;

  // Definición de pasos
  late List<TutorialStep> _shortTutorialSteps;
  late List<TutorialStep> _fullTutorialSteps;

  // Definimos los títulos aquí para que estén disponibles en el build
  static const List<String> _widgetTitles = <String>[
    'HabiTex', // 0
    'Anuncios', // 1
    'Mis Finanzas', // 2
    'Reservas', // 3
    'Mis Tickets', // 4
    'Mi QR', // 5
    'Administración', // 6
  ];

  @override
  void initState() {
    super.initState();
    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initTutorialSteps();

    // Verificar si es la primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTime();
    });
  }

  void _initTutorialSteps() {
    // 1. Tutorial Corto (Automático - Primera Vez)
    _shortTutorialSteps = [
      TutorialStep(
          key: TutorialKeys.appBarTitle,
          title: '¡Bienvenido a HabiTex!',
          description: 'Tu comunidad digital, ahora más fácil y moderna.'),
      TutorialStep(
          key: TutorialKeys.bottomNav,
          title: 'Navegación Principal',
          description:
              'Accede rápidamente a Inicio, Anuncios, Finanzas y más desde aquí.'),
      TutorialStep(
          key: TutorialKeys.logoutBtn,
          title: 'Cerrar Sesión',
          description:
              'Usa este botón para salir de tu cuenta de forma segura.'),
      TutorialStep(
          key: TutorialKeys.menuBtn,
          title: 'Menú Extendido',
          description:
              'Encuentra tu perfil, contactos y configuraciones adicionales aquí.'),
    ];

    // 2. Tutorial Largo (Asistido - Manual)
    _fullTutorialSteps = [
      // --- Barra de Navegación ---
      TutorialStep(
          key: TutorialKeys.navInicio,
          title: 'Inicio',
          description:
              'Tu panel de control principal. Vuelve aquí siempre que lo necesites.',
          customPadding: 24),
      TutorialStep(
          key: TutorialKeys.navAnuncios,
          title: 'Anuncios',
          description:
              'Mantente al día con las noticias y comunicados oficiales.',
          customPadding: 24),
      TutorialStep(
          key: TutorialKeys.navFinanzas,
          title: 'Finanzas',
          description:
              'Consulta tu estado de cuenta, expensas pendientes y registra tus pagos.',
          customPadding: 24),
      TutorialStep(
          key: TutorialKeys.navReservas,
          title: 'Reservas',
          description:
              'Agenda fácilmente el uso de áreas comunes como parrilleros o salones.',
          customPadding: 24),
      TutorialStep(
          key: TutorialKeys.navTickets,
          title: 'Tickets',
          description:
              '¿Algo no funciona? Reporta problemas de mantenimiento o seguridad aquí.',
          customPadding: 24),

      // --- AppBar ---
      TutorialStep(
          key: TutorialKeys.logoutBtn,
          title: 'Cerrar Sesión',
          description:
              'Finaliza tu sesión actual de forma segura para cambiar de usuario.'),
      TutorialStep(
          key: TutorialKeys.menuBtn,
          title: 'Menú Extendido',
          description:
              'Accede a tu perfil, chats directos y configuraciones adicionales.'),

      // --- Pasos DENTRO del menú ---
      TutorialStep(
          key: TutorialKeys.menuPerfil,
          title: 'Tu Perfil',
          description:
              'Toca aquí para actualizar tu foto, teléfono y datos personales.',
          insideMenu: true),
      TutorialStep(
          key: TutorialKeys.menuContactos,
          title: 'Directorio',
          description: 'Lista completa de contactos útiles y de emergencia.',
          insideMenu: true),
      TutorialStep(
          key: TutorialKeys.menuChatAdmin,
          title: 'Chat con Administrador',
          description:
              'Inicia un chat directo con la administración para consultas generales.',
          insideMenu: true),
      TutorialStep(
          key: TutorialKeys.menuChatSeguridad,
          title: 'Chat con Seguridad',
          description:
              'Comunicación directa con la portería o guardia de turno.',
          insideMenu: true),
      TutorialStep(
          key: TutorialKeys.menuSalir,
          title: 'Salir',
          description: 'Salir de la aplicación.',
          insideMenu: true),
    ];
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenTutorial = prefs.getBool('has_seen_tutorial_v3') ?? false;

    if (!hasSeenTutorial) {
      _startTutorial(_shortTutorialSteps);
      await prefs.setBool('has_seen_tutorial_v3', true);
    }
  }

  @override
  void dispose() {
    _focusAnimController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _startTutorial(List<TutorialStep> steps) {
    if (_isTutorialActive) return;

    setState(() {
      _isTutorialActive = true;
      _currentSteps = steps;
      _currentStepIndex = 0;
    });

    _removeOverlay();

    ref.read(selectedTabProvider.notifier).state = 0;
    ref.read(floatingMenuProvider.notifier).state = false;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showStep(0);
    });
  }

  void _showStep(int index) {
    if (index >= _currentSteps.length) {
      _endTutorial();
      return;
    }

    _currentStepIndex = index;
    _removeOverlay();

    final step = _currentSteps[index];
    final isMenuOpen = ref.read(floatingMenuProvider);

    if (step.insideMenu && !isMenuOpen) {
      ref.read(floatingMenuProvider.notifier).state = true;
      Future.delayed(
          const Duration(milliseconds: 150), () => _renderOverlay(step));
      return;
    }

    if (!step.insideMenu && isMenuOpen) {
      ref.read(floatingMenuProvider.notifier).state = false;
      Future.delayed(
          const Duration(milliseconds: 150), () => _renderOverlay(step));
      return;
    }

    _renderOverlay(step);
  }

  void _renderOverlay(TutorialStep step) {
    final RenderBox? renderBox =
        step.key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      debugPrint("Tutorial: No se encontró widget para ${step.title}");
      _showStep(_currentStepIndex + 1);
      return;
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        targetPosition: offset,
        targetSize: size,
        step: step,
        stepIndex: _currentStepIndex + 1,
        totalSteps: _currentSteps.length,
        onNext: () => _showStep(_currentStepIndex + 1),
        onSkip: _endTutorial,
        animController: _focusAnimController,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _endTutorial() {
    setState(() => _isTutorialActive = false);
    _removeOverlay();
    if (ref.read(floatingMenuProvider)) {
      ref.read(floatingMenuProvider.notifier).state = false;
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tutorialTriggerProvider, (prev, next) {
      if (next > 0) _startTutorial(_fullTutorialSteps);
    });

    final selectedIndex = ref.watch(selectedTabProvider);
    final isMenuOpen = ref.watch(floatingMenuProvider);
    final isAdmin = ref.watch(isAdminProvider);

    final List<Widget> widgetOptions = [
      const InicioBodyPremium(), // 0
      const AnnouncementsBody(), // 1
      const DebtBody(), // 2
      const BookingsScreen(), // 3
      const TicketsScreen(), // 4
      const QrScreen(), // 5
      if (isAdmin) const AdminHomeScreen(), // 6
    ];

    final List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
          icon: Container(
              key: TutorialKeys.navInicio, child: const Icon(Iconsax.home)),
          label: 'Inicio'),
      BottomNavigationBarItem(
          icon: Container(
              key: TutorialKeys.navAnuncios,
              child: const Icon(Iconsax.notification)),
          label: 'Anuncios'),
      BottomNavigationBarItem(
          icon: Container(
              key: TutorialKeys.navFinanzas,
              child: const Icon(Iconsax.wallet_money)),
          label: 'Finanzas'),
      BottomNavigationBarItem(
          icon: Container(
              key: TutorialKeys.navReservas,
              child: const Icon(Iconsax.calendar_1)),
          label: 'Reservas'),
      BottomNavigationBarItem(
          icon: Container(
              key: TutorialKeys.navTickets,
              child: const Icon(Iconsax.message_question)),
          label: 'Tickets'),
      if (isAdmin)
        const BottomNavigationBarItem(
            icon: Icon(Iconsax.slider_horizontal), label: 'Admin'),
    ];

    // ✅ LÓGICA DEFENSIVA CORREGIDA (Evita el crash al cambiar de rol)
    int bottomNavIndex = 0;

    if (selectedIndex == 5) {
      bottomNavIndex = 0; // QR (índice 5) resalta Inicio (0)
    } else if (isAdmin && selectedIndex == 6) {
      bottomNavIndex = 5; // AdminHome (índice 6) resalta Admin tab (5)
    } else {
      bottomNavIndex = selectedIndex;
    }

    // Seguridad final: Si el índice calculado supera la cantidad de botones, forzar 0
    if (bottomNavIndex >= navItems.length) {
      bottomNavIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001E35),
        elevation: 0,
        leading: IconButton(
          key: TutorialKeys.menuBtn,
          icon: const Icon(Iconsax.menu_1, color: Colors.white),
          onPressed: () => ref.read(floatingMenuProvider.notifier).state = true,
        ),
        title: Text(
          key: TutorialKeys.appBarTitle,
          _widgetTitles.length > selectedIndex
              ? _widgetTitles[selectedIndex]
              : 'HabiTex',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            key: TutorialKeys.logoutBtn,
            icon: const Icon(Iconsax.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context, ref),
          )
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: widgetOptions,
          ),
          if (isMenuOpen)
            GestureDetector(
              onTap: () =>
                  ref.read(floatingMenuProvider.notifier).state = false,
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          if (isMenuOpen) const FloatingMenu(), // Mantenemos FloatingMenu aquí
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        key: TutorialKeys.bottomNav,
        items: navItems,
        currentIndex: bottomNavIndex, // ✅ Usamos el índice seguro
        onTap: (index) {
          int realIndex = (isAdmin && index == 5) ? 6 : index;
          ref.read(selectedTabProvider.notifier).state = realIndex;
        },
        selectedItemColor: kTeal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Deseas salir de la aplicación?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);

              // ✅ CORRECCIÓN 2: Resetear estados antes de salir para evitar conflictos futuros
              ref.read(selectedTabProvider.notifier).state = 0;
              ref.read(floatingMenuProvider.notifier).state = false;

              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text("Salir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 1. INICIO BODY PREMIUM
// =========================================================
class InicioBodyPremium extends ConsumerWidget {
  const InicioBodyPremium({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verificamos si es Admin para saber si mostramos el botón de "Superaccesos"
    final isAdmin = ref.watch(isAdminProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ NUEVO: BOTÓN DE SUPERACCESOS (ADMIN)
          if (isAdmin)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: "SUPERACCESOS"),
                const SizedBox(height: 12),
                _PremiumCard(
                  key: TutorialKeys
                      .ticketsCard, // Usamos ticketsCard como genérico
                  title: "Gestión Administrativa",
                  subtitle: "Usuarios, Pagos, Anuncios (Todos los módulos)",
                  icon: Iconsax.slider_horizontal,
                  // Imagen: Oficina/Gestión (Updated)
                  imageUrl:
                      "https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=800&auto=format&fit=crop",
                  height: 160,
                  isWide: true,
                  // Navegamos directamente al panel de Admin (índice 6)
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 6,
                ),
                const SizedBox(height: 24),
              ],
            ),

          // --- FILA SUPERIOR ---
          Row(
            children: [
              Expanded(
                child: _PremiumCard(
                  key: TutorialKeys.qrCard,
                  title: "Visitas",
                  icon: Iconsax.scan,
                  // Imagen: Tecnología/QR/Escaneo (Updated)
                  imageUrl:
                      "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?q=80&w=600&auto=format&fit=crop",
                  height: 140,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 5,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PremiumCard(
                  key: TutorialKeys.finanzasCard,
                  title: "Finanzas",
                  icon: Iconsax.wallet_money,
                  // Imagen: Finanzas/Hogar/Ahorro (Updated)
                  imageUrl:
                      "https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?q=80&w=400&auto=format&fit=crop",
                  height: 140,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- COMUNIDAD ---
          const _SectionHeader(title: "COMUNIDAD"),
          const SizedBox(height: 12),

          _PremiumCard(
            key: TutorialKeys.anunciosCard,
            title: "Anuncios",
            subtitle: "Novedades del condominio",
            icon: Iconsax.notification,
            // Imagen: Personas/Comunidad feliz (Updated)
            imageUrl:
                "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=800&auto=format&fit=crop",
            height: 160,
            isWide: true,
            onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _PremiumCard(
                  title: "Reservas",
                  icon: Iconsax.calendar_edit,
                  // Imagen: Piscina/Amenidades (Updated)
                  imageUrl:
                      "https://images.unsplash.com/photo-1560624052-449f5ddf0c31?q=80&w=400&auto=format&fit=crop",
                  height: 130,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PremiumCard(
                  title: "Tickets",
                  icon: Iconsax.ticket,
                  // Imagen: Herramientas/Mantenimiento (Updated)
                  imageUrl:
                      "https://images.unsplash.com/photo-1581244277943-fe4a9c777189?q=80&w=600&auto=format&fit=crop",
                  height: 130,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- OTROS ---
          const _SectionHeader(title: "OTROS"),
          const SizedBox(height: 12),

          _PremiumCard(
            title: "Contactos",
            subtitle: "Directorio oficial",
            icon: Iconsax.call,
            // Imagen: Recepción/Teléfono (Updated)
            imageUrl:
                "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=800&auto=format&fit=crop",
            height: 130,
            isWide: true,
            onTap: () => context.push('/contacts'),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// --- SECTION HEADER ---
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

// --- PREMIUM CARD ---
class _PremiumCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String imageUrl;
  final double height;
  final bool isWide;
  final VoidCallback onTap;

  const _PremiumCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.imageUrl,
    required this.height,
    this.isWide = false,
    required this.onTap,
  });

  @override
  State<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<_PremiumCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        height: widget.height,
        transform: Matrix4.identity()..scale(_isPressed ? 1.05 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: _isPressed ? Border.all(color: kTeal, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
