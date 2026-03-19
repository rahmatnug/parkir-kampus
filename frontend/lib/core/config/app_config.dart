import 'package:flutter/foundation.dart' show kIsWeb;

/// App-wide configuration constants
class AppConfig {
  AppConfig._();

  /// Returns the backend baseUrl based on the current platform at runtime.
  /// - Web/Desktop → localhost:8080
  /// - Android/iOS emulator → 10.0.2.2:8080 (host machine)
  /// Override at build time: flutter run --dart-define=BASE_URL=http://192.168.x.x:8080
  static String get baseUrl {
    const envUrl = String.fromEnvironment('BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }

  static String get loginEndpoint    => '$baseUrl/api/login';
  static String get registerEndpoint => '$baseUrl/api/register';
}

