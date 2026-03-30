import 'package:flutter/foundation.dart';
import 'app_config.dart';

/// Configuration d'environnement — délègue à AppConfig pour l'URL
class EnvironmentConfig {
  static bool get isWeb => kIsWeb;

  /// URL de base de l'API — utilise toujours AppConfig.currentBaseUrl
  static String get apiBaseUrl => AppConfig.currentBaseUrl;

  /// Nom de l'application
  static String get appName => 'LOGESCO v2';

  /// Version de l'application
  static String get appVersion => '2.0.0';

  /// Timeout par défaut pour les requêtes API (en secondes)
  static int get apiTimeout => 30;

  /// Durée de session par défaut (en minutes)
  static int get sessionDuration => 30;
}
