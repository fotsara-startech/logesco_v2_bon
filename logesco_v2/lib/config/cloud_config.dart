class CloudConfig {
  // API Configuration - will be set by environment
  static String get apiBaseUrl {
    // In production, this should be set via environment variables
    // or build-time configuration
    const String? apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl != null && apiUrl.isNotEmpty) {
      return '$apiUrl/api/v1';
    }

    // Default for development
    return 'http://localhost:3000/api/v1';
  }

  static String get apiHealthUrl {
    const String? apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl != null && apiUrl.isNotEmpty) {
      return '$apiUrl/api/health';
    }

    return 'http://localhost:3000/api/health';
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Configuration pour déploiement cloud
  static const bool isCloudDeployment = true;
  static const bool enableOfflineMode = false;

  // Paramètres de reconnexion automatique
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Configuration de stockage cloud
  static const String cloudStoragePrefix = 'logesco_cloud_';

  // Paramètres d'interface pour web
  static const double minViewportWidth = 768;
  static const double minViewportHeight = 600;

  // Configuration de sécurité
  static const bool enableCSRFProtection = true;
  static const bool enableSecureStorage = true;

  // Configuration de performance
  static const bool enableCaching = true;
  static const Duration cacheTimeout = Duration(minutes: 5);

  // Configuration de monitoring
  static const bool enableAnalytics = true;
  static const bool enableErrorReporting = true;
}
