/// Configuration centralisée de l'application LOGESCO
class AppConfig {
  // ============================================================================
  // 1. MODE DE DÉPLOIEMENT
  // ============================================================================

  /// Mode client (true) ou serveur (false)
  // static const bool isClientMode = true;
  static const bool isClientMode = false;

  // ============================================================================
  // 2. CONFIGURATION DU SERVEUR
  // ============================================================================

  static const String _localhostUrl = 'http://localhost:8080/api/v1';
  static const String _productionUrl = 'http://192.168.100.101:8080/api/v1';

  /// URL de base par défaut — décommenter _localhostUrl pour le dev local
  // static const String baseUrl = _productionUrl;
  static const String baseUrl = _localhostUrl;

  /// URL de base dynamique (modifiable au runtime via setBaseUrl)
  // static String _customBaseUrl = _productionUrl;
  static String _customBaseUrl = _localhostUrl;

  /// Retourne l'URL de base actuelle
  static String get currentBaseUrl => _customBaseUrl;

  /// Définit une URL de base personnalisée
  static void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  /// Contrôle des licences activé (true = validation licence requise)
  static const bool enableLicenseControl = true;

  /// Réinitialise l'URL à la valeur par défaut
  static void resetBaseUrl() {
    _customBaseUrl = baseUrl;
  }

  // ============================================================================
  // 3. CONFIGURATION DE DÉVELOPPEMENT
  // ============================================================================

  /// Mode développement
  static const bool isDevelopmentMode = false;

  /// Bypass de l'authentification en mode développement
  static const bool bypassAuth = false;

  /// Utilisation des services simulés
  static const bool useMockServices = false;

  /// Activation des logs
  static const bool enableLogging = true;

  /// Utilisation de données de test
  static const bool useTestData = false;

  // ============================================================================
  // 4. TIMEOUTS
  // ============================================================================

  /// Timeout de connexion
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Timeout de réception
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Timeout général des requêtes
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

  /// Taille de page par défaut
  static const int defaultPageSize = 20;

  /// Taille de page maximale
  static const int maxPageSize = 100;

  // ============================================================================
  // 7. RECHERCHE
  // ============================================================================

  /// Délai de debounce pour la recherche
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);

  // ============================================================================
  // 8. MESSAGES
  // ============================================================================

  /// Message d'erreur par défaut
  static const String defaultErrorMessage = 'Une erreur inattendue s\'est produite';

  /// Message de connexion internet
  static const String noInternetMessage = 'Pas de connexion internet';

  // ============================================================================
  // 9. HEADERS HTTP
  // ============================================================================

  /// Headers par défaut pour les requêtes HTTP
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'LOGESCO-Mobile/1.0.0',
      };

  // ============================================================================
  // 10. LOGGING
  // ============================================================================

  /// Mode développement pour le logging
  static const bool isDevelopment = true;

  // ============================================================================
  // 11. ROUTES
  // ============================================================================

  /// Retourne la route initiale selon la configuration
  static String get initialRoute {
    if (isDevelopmentMode && bypassAuth) {
      return '/dashboard';
    }
    return '/';
  }
}
