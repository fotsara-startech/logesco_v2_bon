/// Configuration de l'application
class AppConfig {
  // Mode de développement/test
  static const bool isDevelopmentMode = true;

  // Bypass de l'authentification en mode développement
  static const bool bypassAuth = false;

  // Utilisation des services simulés
  static const bool useMockServices = false;

  // Configuration API
  static const String apiBaseUrl = isDevelopmentMode ? 'http://localhost:8080/api/v1' : 'http://localhost:8080/api/v1'; //'https://api.logesco.com';

  // Timeout des requêtes
  static const Duration requestTimeout = Duration(seconds: 30);

  // Configuration de pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configuration de recherche
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);

  // Messages par défaut
  static const String defaultErrorMessage = 'Une erreur inattendue s\'est produite';
  static const String noInternetMessage = 'Pas de connexion internet';

  /// Retourne la route initiale selon la configuration
  static String get initialRoute {
    if (isDevelopmentMode && bypassAuth) {
      return '/dashboard'; // Aller directement au dashboard en mode test
    }
    return '/'; // Route normale (splash/login)
  }
}
