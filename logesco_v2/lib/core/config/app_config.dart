/// Configuration centralisée de l'application LOGESCO
/// Les paramètres de déploiement sont injectés via --dart-define au moment du build.
/// Utiliser le script build.ps1 pour construire l'application.
class AppConfig {
  // ============================================================================
  // 1. MODE DE DÉPLOIEMENT
  // ============================================================================

  /// Mode client (true) ou serveur local (false)
  /// Injecté via --dart-define=IS_CLIENT_MODE=true
  static const bool isClientMode = bool.fromEnvironment('IS_CLIENT_MODE', defaultValue: false);

  // ============================================================================
  // 2. CONFIGURATION DU SERVEUR
  // ============================================================================

  static const String _localhostUrl = 'http://localhost:8080/api/v1';

  /// URL de base injectée via --dart-define=BASE_URL=http://192.168.x.x:8080/api/v1
  static const String _definedBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: _localhostUrl);

  /// Alias statique pour compatibilité avec les services existants
  static String get baseUrl => _customBaseUrl;

  /// URL de base dynamique (modifiable au runtime via setBaseUrl)
  static String _customBaseUrl = _definedBaseUrl;

  /// Retourne l'URL de base actuelle
  static String get currentBaseUrl => _customBaseUrl;

  /// Définit une URL de base personnalisée
  static void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  /// Réinitialise l'URL à la valeur définie au build
  static void resetBaseUrl() {
    _customBaseUrl = _definedBaseUrl;
  }

  /// Contrôle des licences activé
  /// Injecté via --dart-define=ENABLE_LICENSE_CONTROL=true
  static const bool enableLicenseControl = bool.fromEnvironment('ENABLE_LICENSE_CONTROL', defaultValue: true);

  // ============================================================================
  // 3. CONFIGURATION DE DÉVELOPPEMENT
  // ============================================================================

  static const bool isDevelopmentMode = bool.fromEnvironment('DEV_MODE', defaultValue: false);
  static const bool bypassAuth = bool.fromEnvironment('BYPASS_AUTH', defaultValue: false);
  static const bool useMockServices = false;
  static const bool enableLogging = true;
  static const bool useTestData = false;

  // ============================================================================
  // 4. TIMEOUTS
  // ============================================================================

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration requestTimeout = Duration(seconds: 30);

  // ============================================================================
  // 5. ENDPOINTS API
  // ============================================================================

  static const String authEndpoint = '/auth';
  static const String productsEndpoint = '/products';
  static const String inventoryEndpoint = '/inventory';
  static const String customersEndpoint = '/customers';
  static const String suppliersEndpoint = '/suppliers';
  static const String salesEndpoint = '/sales';
  static const String procurementEndpoint = '/procurement';
  static const String accountsEndpoint = '/accounts';
  static const String companyEndpoint = '/company';
  static const String financialMovementsEndpoint = '/financial-movements';
  static const String movementCategoriesEndpoint = '/movement-categories';
  static const String proformaEndpoint = '/proformas';

  // ============================================================================
  // 6. PAGINATION
  // ============================================================================

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============================================================================
  // 7. RECHERCHE
  // ============================================================================

  static const Duration searchDebounceDelay = Duration(milliseconds: 500);

  // ============================================================================
  // 8. MESSAGES
  // ============================================================================

  static const String defaultErrorMessage = 'Une erreur inattendue s\'est produite';
  static const String noInternetMessage = 'Pas de connexion internet';

  // ============================================================================
  // 9. HEADERS HTTP
  // ============================================================================

  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'LOGESCO-Mobile/1.0.0',
      };

  // ============================================================================
  // 10. LOGGING
  // ============================================================================

  static const bool isDevelopment = bool.fromEnvironment('DEV_MODE', defaultValue: false);

  // ============================================================================
  // 11. ROUTES
  // ============================================================================

  static String get initialRoute {
    if (isDevelopmentMode && bypassAuth) {
      return '/dashboard';
    }
    return '/';
  }
}
