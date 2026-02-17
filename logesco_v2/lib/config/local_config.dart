class LocalConfig {
  static const String apiBaseUrl = 'http://localhost:8080/api/v1';
  static const String apiHealthUrl = 'http://localhost:8080/api/health';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Configuration pour déploiement local
  static const bool isLocalDeployment = true;
  static const bool enableOfflineMode = true;

  // Paramètres de reconnexion automatique
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Configuration de stockage local
  static const String localStoragePrefix = 'logesco_local_';

  // Paramètres d'interface pour desktop
  static const double minWindowWidth = 1024;
  static const double minWindowHeight = 768;
  static const double defaultWindowWidth = 1280;
  static const double defaultWindowHeight = 800;
}
