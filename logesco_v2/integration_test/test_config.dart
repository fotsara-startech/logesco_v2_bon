/// Configuration pour les tests d'intégration LOGESCO v2
class TestConfig {
  // Configuration du serveur backend
  static const String backendUrl = 'http://localhost:3002';
  static const String apiVersion = 'v1';
  static const String baseApiUrl = '$backendUrl/api/$apiVersion';

  // Timeouts pour les tests
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration animationTimeout = Duration(milliseconds: 500);

  // Configuration des données de test
  static const bool useRealData = true;
  static const bool cleanupAfterTests = false; // Garder les données pour inspection

  // Endpoints API
  static const Map<String, String> endpoints = {
    'auth': '/auth',
    'login': '/auth/login',
    'register': '/auth/register',
    'products': '/products',
    'customers': '/customers',
    'suppliers': '/suppliers',
    'inventory': '/inventory',
    'accounts': '/accounts',
  };

  // Données de test par défaut
  static const Map<String, dynamic> defaultTestUser = {
    'nom': 'Test',
    'prenom': 'Integration',
    'email': 'integration.test@logesco.local',
    'motDePasse': 'TestPassword123!',
    'role': 'ADMIN',
    'telephone': '+33 6 00 00 00 00',
    'adresse': 'Adresse de test, 75000 Paris'
  };

  // Configuration des tests de performance
  static const Map<String, int> performanceThresholds = {
    'maxLoadTimeMs': 3000,
    'maxApiResponseMs': 2000,
    'maxNavigationMs': 1000,
  };

  // Messages d'erreur personnalisés
  static const Map<String, String> errorMessages = {
    'networkError': 'Erreur de connexion au serveur backend',
    'timeoutError': 'Timeout lors de l\'exécution du test',
    'authError': 'Erreur d\'authentification',
    'dataError': 'Erreur dans les données de test',
  };

  /// Vérifie si le backend est accessible
  static Future<bool> isBackendAvailable() async {
    try {
      // Cette méthode sera implémentée avec http
      // pour vérifier la connectivité au backend
      return true; // Placeholder
    } catch (e) {
      return false;
    }
  }

  /// Retourne l'URL complète pour un endpoint
  static String getEndpointUrl(String endpoint) {
    final path = endpoints[endpoint] ?? endpoint;
    return '$baseApiUrl$path';
  }
}
