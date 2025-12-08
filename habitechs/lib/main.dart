import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitechs/core/navigation/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

// --- DEFINIMOS LA PALETA "CONFIANZA MODERNA" ---
const Color kOxfordBlue = Color(0xFF002147);
const Color kTeal = Color(0xFF20B2AA);
const Color kLightGray = Color(0xFFF0F4F8);
const Color kWhite = Color(0xFFFFFFFF);
// ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final baseTextTheme = Theme.of(context).textTheme;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: 'HabiTechs',

      // ✅ MEJORA VISUAL PARA WEB/PC
      // Esto centra la app y evita que se estire en pantallas anchas
      builder: (context, child) {
        return Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 600), // Ancho máximo tipo Móvil
            decoration: const BoxDecoration(boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, 10),
                spreadRadius: 5,
              )
            ]),
            // ClipRect asegura que nada se salga del borde en web
            child: ClipRect(child: child),
          ),
        );
      },

      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: kOxfordBlue,
          secondary: kTeal,
          surface: kWhite,
          onPrimary: kWhite,
          onSecondary: kWhite,
          onSurface: kOxfordBlue,
          error: Colors.red.shade700,
        ),
        textTheme: GoogleFonts.interTextTheme(baseTextTheme),
        scaffoldBackgroundColor: kLightGray,
        appBarTheme: AppBarTheme(
          backgroundColor: kOxfordBlue,
          foregroundColor: kWhite,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w600, color: kWhite),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: kOxfordBlue,
          selectedItemColor: kTeal,
          unselectedItemColor: Colors.white.withOpacity(0.7),
          type: BottomNavigationBarType.fixed,
          elevation: 10,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kTeal,
            foregroundColor: kWhite,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
