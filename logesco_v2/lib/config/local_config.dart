import '../core/config/app_config.dart';

class LocalConfig {
  /// Délègue à AppConfig pour l'URL centralisée
  static String get apiBaseUrl => AppConfig.currentBaseUrl;
  static String get apiHealthUrl => '${AppConfig.currentBaseUrl.replaceAll('/api/v1', '')}/api/health';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const bool isLocalDeployment = true;
  static const bool enableOfflineMode = true;

  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static const String localStoragePrefix = 'logesco_local_';

  static const double minWindowWidth = 1024;
  static const double minWindowHeight = 768;
  static const double defaultWindowWidth = 1280;
  static const double defaultWindowHeight = 800;
}
