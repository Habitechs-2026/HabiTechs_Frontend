import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    if (kReleaseMode) {
      return 'https://habitechs-production-f343.up.railway.app';
    }
    if (kIsWeb) {
      return 'http://localhost:5100';
    }
    return 'http://10.0.2.2:5100';
  }
}
