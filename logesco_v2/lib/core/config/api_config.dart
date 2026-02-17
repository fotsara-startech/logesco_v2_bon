class ApiConfig {
  // Configuration de base
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Endpoints
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

  // Configuration de développement
  static const bool isDevelopment = true;
  static const bool enableLogging = true;
  static const bool useTestData = false; // Utiliser des données réelles maintenant

  // Configuration de production (à utiliser en production)
  static const String productionBaseUrl = 'https://api.logesco.com/v1';

  /// Retourne l'URL de base selon l'environnement
  static String get currentBaseUrl {
    return isDevelopment ? baseUrl : productionBaseUrl;
  }

  /// Headers par défaut
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'LOGESCO-Mobile/1.0.0',
      };
}
