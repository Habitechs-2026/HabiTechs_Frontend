import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    // ---------------------------------------------------------
    // 1. MODO PRODUCCIÓN (Cuando subas a Netlify o generes APK final)
    // ---------------------------------------------------------
    if (kReleaseMode) {
      return 'https://app-251208142957.azurewebsites.net';
    }

    // ---------------------------------------------------------
    // 2. MODO DESARROLLO (Cuando ejecutas con F5 en tu PC)
    // ---------------------------------------------------------

    // Si estás probando en Chrome localmente
    if (kIsWeb) {
      return 'http://localhost:5100';
    }

    // Si estás probando en Emulador Android
    return 'http://10.0.2.2:5100';
  }
}
