import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/api_response.dart';
import '../../../core/utils/retry_policy.dart';
import '../models/financial_movement.dart';
import '../models/movement_category.dart';
import '../utils/financial_error_handler.dart';
import 'financial_movement_cache_service.dart';

/// Service pour la gestion des mouvements financiers via API
class FinancialMovementService {
  final AuthService _authService;
  final FinancialMovementCacheService _cacheService;
  static const String _endpoint = '/financial-movements';

  // Politiques de retry pour différents types d'opérations
  static final _readRetryPolicy = RetryPolicies.financialOperations;
  static final _writeRetryPolicy = RetryPolicies.financialWriteOperations;
  static final _criticalRetryPolicy = RetryPolicies.financialCriticalOperations;

  FinancialMovementService(this._authService, this._cacheService);

  /// Récupère la liste des mouvements financiers avec filtres
  Future<ApiResponse<List<FinancialMovement>>> getMovements({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    String? search,
    double? minAmount,
    double? maxAmount,
    bool forceRefresh = false,
  }) async {
    return await _readRetryPolicy
        .execute(
          () => _getMovementsInternal(
            page: page,
            limit: limit,
            startDate: startDate,
            endDate: endDate,
            categoryId: categoryId,
            search: search,
            minAmount: minAmount,
            maxAmount: maxAmount,
            forceRefresh: forceRefresh,
          ),
          operationName: 'Récupération des mouvements financiers',
        )
        .catchFinancialError(operation: 'getMovements');
  }

  /// Implémentation interne de la récupération des mouvements
  Future<ApiResponse<List<FinancialMovement>>> _getMovementsInternal({
    required int page,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    String? search,
    double? minAmount,
    double? maxAmount,
    required bool forceRefresh,
  }) async {
    // Génère une clé de cache basée sur les filtres
    final cacheKey = _cacheService.generateCacheKey(
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      search: search,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );

    // Vérifie le cache si pas de rafraîchissement forcé
    if (!forceRefresh) {
      final cachedMovements = _cacheService.getCachedMovements(cacheKey: cacheKey);
      if (cachedMovements != null) {
        print('📦 Mouvements récupérés depuis le cache');
        return ApiResponse.success(cachedMovements);
      }
    }

    final token = await _authService.getToken();
    if (token == null) {
      throw FinancialMovementException(
        message: 'Session expirée. Veuillez vous reconnecter.',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
        errorType: FinancialErrorType.authenticationError,
      );
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (minAmount != null) {
      queryParams['minAmount'] = minAmount.toString();
    }
    if (maxAmount != null) {
      queryParams['maxAmount'] = maxAmount.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint').replace(queryParameters: queryParams);

    print('🔄 Récupération des mouvements financiers depuis: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API mouvements financiers: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📦 Données JSON mouvements financiers reçues');

        final movements = <FinancialMovement>[];
        final dataList = jsonData['data'] as List;

        for (final item in dataList) {
          try {
            final movement = FinancialMovement.fromJson(item as Map<String, dynamic>);
            movements.add(movement);
          } catch (e) {
            print('⚠️ Erreur parsing mouvement financier, ignoré: $e');
          }
        }

        // Met en cache les résultats
        await _cacheService.cacheMovements(movements, cacheKey: cacheKey);

        print('✅ ${movements.length} mouvements financiers récupérés avec succès');
        return ApiResponse.success(
          movements,
          pagination: jsonData['pagination'] != null ? Pagination.fromJson(jsonData['pagination']) : null,
        );
      } else {
        throw _createApiExceptionFromResponse(response);
      }
    } on TimeoutException {
      throw FinancialMovementException.timeout(operation: 'Récupération des mouvements');
    } on SocketException catch (e) {
      // En cas d'erreur réseau, essaie de récupérer depuis le cache
      if (!forceRefresh) {
        final cachedMovements = _cacheService.getCachedMovements(cacheKey: cacheKey);
        if (cachedMovements != null) {
          print('📦 Récupération depuis le cache en mode dégradé');
          return ApiResponse.success(cachedMovements);
        }
      }
      throw FinancialMovementException.networkError(details: e.message);
    }
  }

  /// Récupère un mouvement financier par son ID
  Future<FinancialMovement?> getMovementById(int id, {bool forceRefresh = false}) async {
    return await _readRetryPolicy
        .execute(
          () => _getMovementByIdInternal(id, forceRefresh: forceRefresh),
          operationName: 'Récupération du mouvement $id',
        )
        .catchFinancialError(operation: 'getMovementById');
  }

  /// Implémentation interne de la récupération d'un mouvement par ID
  Future<FinancialMovement?> _getMovementByIdInternal(int id, {required bool forceRefresh}) async {
    // Vérifie le cache si pas de rafraîchissement forcé
    if (!forceRefresh) {
      final cachedMovement = _cacheService.getCachedMovementDetail(id);
      if (cachedMovement != null) {
        print('📦 Mouvement $id récupéré depuis le cache');
        return cachedMovement;
      }
    }

    final token = await _authService.getToken();
    if (token == null) {
      throw FinancialMovementException(
        message: 'Session expirée. Veuillez vous reconnecter.',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
        errorType: FinancialErrorType.authenticationError,
      );
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API mouvement financier $id: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final movement = FinancialMovement.fromJson(jsonData['data']);

        // Met en cache le mouvement
        await _cacheService.cacheMovementDetail(movement);

        return movement;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw _createApiExceptionFromResponse(response);
      }
    } on TimeoutException {
      // En cas de timeout, essaie de récupérer depuis le cache
      if (!forceRefresh) {
        final cachedMovement = _cacheService.getCachedMovementDetail(id);
        if (cachedMovement != null) {
          print('📦 Récupération du mouvement $id depuis le cache après timeout');
          return cachedMovement;
        }
      }
      throw FinancialMovementException.timeout(operation: 'Récupération du mouvement $id');
    } on SocketException catch (e) {
      // En cas d'erreur réseau, essaie de récupérer depuis le cache
      if (!forceRefresh) {
        final cachedMovement = _cacheService.getCachedMovementDetail(id);
        if (cachedMovement != null) {
          print('📦 Récupération du mouvement $id depuis le cache en mode dégradé');
          return cachedMovement;
        }
      }
      throw FinancialMovementException.networkError(details: e.message);
    }
  }

  /// Crée un nouveau mouvement financier
  Future<FinancialMovement> createMovement(FinancialMovementForm form) async {
    return await _writeRetryPolicy
        .execute(
          () => _createMovementInternal(form),
          operationName: 'Création du mouvement financier',
        )
        .catchFinancialError(operation: 'createMovement');
  }

  /// Implémentation interne de la création d'un mouvement
  Future<FinancialMovement> _createMovementInternal(FinancialMovementForm form) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw FinancialMovementException(
        message: 'Session expirée. Veuillez vous reconnecter.',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
        errorType: FinancialErrorType.authenticationError,
      );
    }

    // Validation côté client
    final errors = form.validate();
    if (errors.isNotEmpty) {
      throw FinancialMovementException.validation(
        message: 'Données invalides: ${errors.join(', ')}',
        fieldErrors: Map.fromEntries(
          errors.map((error) => MapEntry(error, error)),
        ),
      );
    }

    print('🔄 Création d\'un mouvement financier: ${form.description}');

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$_endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(form.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Réponse création mouvement financier: ${response.statusCode}');

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final movement = FinancialMovement.fromJson(jsonData['data']);

        // Invalide le cache des mouvements car un nouveau a été créé
        await _cacheService.invalidateMovementsCache();
        await _cacheService.invalidateStatisticsCache();

        print('✅ Mouvement financier créé avec succès: ${movement.reference}');
        return movement;
      } else {
        throw _createApiExceptionFromResponse(response);
      }
    } on TimeoutException {
      throw FinancialMovementException.timeout(operation: 'Création du mouvement financier');
    } on SocketException catch (e) {
      throw FinancialMovementException.networkError(details: e.message);
    }
  }

  /// Met à jour un mouvement financier existant
  Future<FinancialMovement> updateMovement(int id, FinancialMovementForm form) async {
    return await _writeRetryPolicy
        .execute(
          () => _updateMovementInternal(id, form),
          operationName: 'Mise à jour du mouvement $id',
        )
        .catchFinancialError(operation: 'updateMovement');
  }

  /// Implémentation interne de la mise à jour d'un mouvement
  Future<FinancialMovement> _updateMovementInternal(int id, FinancialMovementForm form) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw FinancialMovementException(
        message: 'Session expirée. Veuillez vous reconnecter.',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
        errorType: FinancialErrorType.authenticationError,
      );
    }

    // Validation côté client
    final errors = form.validate();
    if (errors.isNotEmpty) {
      throw FinancialMovementException.validation(
        message: 'Données invalides: ${errors.join(', ')}',
        fieldErrors: Map.fromEntries(
          errors.map((error) => MapEntry(error, error)),
        ),
      );
    }

    print('🔄 Mise à jour du mouvement financier $id');

    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(form.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Réponse mise à jour mouvement financier: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final movement = FinancialMovement.fromJson(jsonData['data']);

        // Invalide le cache pour ce mouvement et les listes
        await _cacheService.invalidateMovementCache(id);
        await _cacheService.invalidateMovementsCache();
        await _cacheService.invalidateStatisticsCache();

        print('✅ Mouvement financier mis à jour avec succès: ${movement.reference}');
        return movement;
      } else {
        throw _createApiExceptionFromResponse(response);
      }
    } on TimeoutException {
      throw FinancialMovementException.timeout(operation: 'Mise à jour du mouvement $id');
    } on SocketException catch (e) {
      throw FinancialMovementException.networkError(details: e.message);
    }
  }

  /// Supprime un mouvement financier
  Future<void> deleteMovement(int id) async {
    return await _criticalRetryPolicy
        .execute(
          () => _deleteMovementInternal(id),
          operationName: 'Suppression du mouvement $id',
        )
        .catchFinancialError(operation: 'deleteMovement');
  }

  /// Implémentation interne de la suppression d'un mouvement
  Future<void> _deleteMovementInternal(int id) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw FinancialMovementException(
        message: 'Session expirée. Veuillez vous reconnecter.',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
        errorType: FinancialErrorType.authenticationError,
      );
    }

    print('🔄 Suppression du mouvement financier $id');

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse suppression mouvement financier: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Invalide le cache pour ce mouvement et les listes
        await _cacheService.invalidateMovementCache(id);
        await _cacheService.invalidateMovementsCache();
        await _cacheService.invalidateStatisticsCache();

        print('✅ Mouvement financier supprimé avec succès');
      } else {
        throw _createApiExceptionFromResponse(response);
      }
    } on TimeoutException {
      throw FinancialMovementException.timeout(operation: 'Suppression du mouvement $id');
    } on SocketException catch (e) {
      throw FinancialMovementException.networkError(details: e.message);
    }
  }

  /// Récupère les catégories de mouvements
  Future<List<MovementCategory>> getCategories({bool forceRefresh = false}) async {
    return await _readRetryPolicy
        .execute(
          () => _getCategoriesInternal(forceRefresh: forceRefresh),
          operationName: 'Récupération des catégories',
        )
        .catchFinancialError(operation: 'getCategories');
  }

  /// Implémentation interne de la récupération des catégories
  Future<List<MovementCategory>> _getCategoriesInternal({required bool forceRefresh}) async {
    // Vérifie le cache si pas de rafraîchissement forcé
    if (!forceRefresh) {
      final cachedCategories = _cacheService.getCachedCategories();
      if (cachedCategories != null) {
        print('📦 Catégories récupérées depuis le cache');
        return cachedCategories;
      }
    }

    final token = await _authService.getToken();
    if (token == null) {
      throw FinancialMovementException(
        message: 'Session expirée. Veuillez vous reconnecter.',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
        errorType: FinancialErrorType.authenticationError,
      );
    }

    print('🔄 Récupération des catégories de mouvements');

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/movement-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API catégories: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final categories = <MovementCategory>[];
        final dataList = jsonData['data'] as List;

        for (final item in dataList) {
          try {
            final category = MovementCategory.fromJson(item as Map<String, dynamic>);
            categories.add(category);
          } catch (e) {
            print('⚠️ Erreur parsing catégorie, ignorée: $e');
          }
        }

        // Met en cache les catégories
        await _cacheService.cacheCategories(categories);

        print('✅ ${categories.length} catégories récupérées avec succès');
        return categories;
      } else {
        throw _createApiExceptionFromResponse(response);
      }
    } on TimeoutException {
      // En cas de timeout, essaie de récupérer depuis le cache
      if (!forceRefresh) {
        final cachedCategories = _cacheService.getCachedCategories();
        if (cachedCategories != null) {
          print('📦 Récupération des catégories depuis le cache après timeout');
          return cachedCategories;
        }
      }

      // En dernier recours, retourner les catégories par défaut
      print('📦 Utilisation des catégories par défaut après timeout');
      return MovementCategory.defaultCategories;
    } on SocketException {
      // En cas d'erreur réseau, essaie de récupérer depuis le cache
      if (!forceRefresh) {
        final cachedCategories = _cacheService.getCachedCategories();
        if (cachedCategories != null) {
          print('📦 Récupération des catégories depuis le cache en mode dégradé');
          return cachedCategories;
        }
      }

      // En dernier recours, retourner les catégories par défaut
      print('📦 Utilisation des catégories par défaut après erreur réseau');
      return MovementCategory.defaultCategories;
    }
  }

  /// Récupère les statistiques des mouvements financiers
  Future<MovementStatistics> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    return await _readRetryPolicy
        .execute(
          () => _getStatisticsInternal(
            startDate: startDate,
            endDate: endDate,
            forceRefresh: forceRefresh,
          ),
          operationName: 'Récupération des statistiques',
        )
        .catchFinancialError(operation: 'getStatistics');
  }

  /// Implémentation interne de la récupération des statistiques
  Future<MovementStatistics> _getStatisticsInternal({
    DateTime? startDate,
    DateTime? endDate,
    required bool forceRefresh,
  }) async {
    // Génère une clé de cache basée sur la période
    String? period;
    if (startDate != null && endDate != null) {
      period = '${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';
    }

    // Vérifie le cache si pas de rafraîchissement forcé
    if (!forceRefresh) {
      final cachedStats = _cacheService.getCachedStatistics(period: period);
      if (cachedStats != null) {
        print('📦 Statistiques récupérées depuis le cache');
        return MovementStatistics.fromJson(cachedStats);
      }
    }

    final token = await _authService.getToken();
    if (token == null) {
      throw FinancialMovementException(
        message: 'Session expirée. Veuillez vous reconnecter.',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
        errorType: FinancialErrorType.authenticationError,
      );
    }

    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/statistics').replace(queryParameters: queryParams);

    print('🔄 Récupération des statistiques depuis: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API statistiques: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final statistics = MovementStatistics.fromJson(jsonData['data']);

        // Met en cache les statistiques
        await _cacheService.cacheStatistics(jsonData['data'], period: period);

        print('✅ Statistiques récupérées avec succès');
        return statistics;
      } else {
        throw _createApiExceptionFromResponse(response);
      }
    } on TimeoutException {
      // En cas de timeout, essaie de récupérer depuis le cache
      if (!forceRefresh) {
        final cachedStats = _cacheService.getCachedStatistics(period: period);
        if (cachedStats != null) {
          print('📦 Récupération des statistiques depuis le cache après timeout');
          return MovementStatistics.fromJson(cachedStats);
        }
      }
      throw FinancialMovementException.timeout(operation: 'Récupération des statistiques');
    } on SocketException catch (e) {
      // En cas d'erreur réseau, essaie de récupérer depuis le cache
      if (!forceRefresh) {
        final cachedStats = _cacheService.getCachedStatistics(period: period);
        if (cachedStats != null) {
          print('📦 Récupération des statistiques depuis le cache en mode dégradé');
          return MovementStatistics.fromJson(cachedStats);
        }
      }
      throw FinancialMovementException.networkError(details: e.message);
    }
  }

  /// Initialise le service de cache
  Future<void> initCache() async {
    await _cacheService.init();
  }

  /// Force le rafraîchissement du cache
  Future<void> refreshCache() async {
    await _cacheService.invalidateMovementsCache();
    await _cacheService.invalidateCategoriesCache();
    await _cacheService.invalidateStatisticsCache();
  }

  /// Nettoie tout le cache
  Future<void> clearCache() async {
    await _cacheService.clearAllCache();
  }

  /// Obtient des informations sur le cache
  Map<String, dynamic> getCacheInfo() {
    return _cacheService.getCacheInfo();
  }

  /// Obtient la taille du cache
  int getCacheSize() {
    return _cacheService.getCacheSize();
  }

  /// Teste la connectivité du service
  Future<bool> testConnectivity() async {
    try {
      await _readRetryPolicy.execute(
        () => _testConnectivityInternal(),
        operationName: 'Test de connectivité',
      );
      return true;
    } catch (e) {
      print('❌ Test de connectivité échoué: $e');
      return false;
    }
  }

  /// Test de connectivité interne
  Future<void> _testConnectivityInternal() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw FinancialMovementException(
        message: 'Token d\'authentification manquant',
        code: 'AUTH_TOKEN_MISSING',
        statusCode: 401,
        errorType: FinancialErrorType.authenticationError,
      );
    }

    final response = await http.head(
      Uri.parse('${ApiConfig.baseUrl}/health'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw FinancialMovementException(
        message: 'Service indisponible',
        code: 'SERVICE_UNAVAILABLE',
        statusCode: response.statusCode,
        errorType: FinancialErrorType.serverError,
      );
    }
  }

  /// Récupère les informations de santé du service
  Future<Map<String, dynamic>> getServiceHealth() async {
    final isConnected = await testConnectivity();
    final circuitBreakerStates = RetryPolicies.getCircuitBreakerStates();
    final cacheInfo = getCacheInfo();

    return {
      'isConnected': isConnected,
      'circuitBreakers': circuitBreakerStates,
      'cache': cacheInfo,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Force la récupération du service en cas de problème
  Future<void> forceRecovery() async {
    print('🔄 Tentative de récupération forcée du service...');

    // Réinitialise les circuit breakers
    RetryPolicies.resetCircuitBreakers();

    // Vide le cache pour forcer le rafraîchissement
    await clearCache();

    // Teste la connectivité
    final isHealthy = await testConnectivity();

    if (isHealthy) {
      print('✅ Service récupéré avec succès');
    } else {
      print('❌ Échec de la récupération du service');
      throw FinancialMovementException(
        message: 'Impossible de récupérer le service',
        code: 'RECOVERY_FAILED',
        statusCode: 503,
        errorType: FinancialErrorType.serverError,
      );
    }
  }

  /// Crée une exception API à partir d'une réponse HTTP
  FinancialMovementException _createApiExceptionFromResponse(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      final message = errorData['message'] ?? 'Erreur lors de l\'opération';
      final code = errorData['code'] ?? 'API_ERROR';

      return FinancialMovementException(
        message: message,
        code: code,
        statusCode: response.statusCode,
        errorType: _getErrorTypeFromStatusCode(response.statusCode),
        details: errorData is Map<String, dynamic> ? errorData : null,
      );
    } catch (e) {
      return FinancialMovementException(
        message: 'Erreur de communication avec le serveur (${response.statusCode})',
        code: 'COMMUNICATION_ERROR',
        statusCode: response.statusCode,
        errorType: _getErrorTypeFromStatusCode(response.statusCode),
      );
    }
  }

  /// Détermine le type d'erreur basé sur le code de statut HTTP
  FinancialErrorType _getErrorTypeFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return FinancialErrorType.validationError;
      case 401:
        return FinancialErrorType.authenticationError;
      case 403:
        return FinancialErrorType.permissionError;
      case 404:
        return FinancialErrorType.notFoundError;
      case 408:
        return FinancialErrorType.timeoutError;
      case 500:
      case 502:
      case 503:
      case 504:
        return FinancialErrorType.serverError;
      default:
        return FinancialErrorType.unknownError;
    }
  }
}

/// Modèle pour les statistiques des mouvements financiers
class MovementStatistics {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final List<CategoryStatistic> categoryBreakdown;
  final List<DailyStatistic> dailyBreakdown;

  MovementStatistics({
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
    required this.categoryBreakdown,
    required this.dailyBreakdown,
  });

  factory MovementStatistics.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    return MovementStatistics(
      totalAmount: parseDouble(json['totalAmount']),
      totalCount: parseInt(json['totalCount']),
      averageAmount: parseDouble(json['averageAmount']),
      categoryBreakdown: ((json['categoryBreakdown'] ?? []) as List).map((item) => CategoryStatistic.fromJson((item ?? {}) as Map<String, dynamic>)).toList(),
      dailyBreakdown: ((json['dailyBreakdown'] ?? []) as List).map((item) => DailyStatistic.fromJson((item ?? {}) as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'totalCount': totalCount,
      'averageAmount': averageAmount,
      'categoryBreakdown': categoryBreakdown.map((item) => item.toJson()).toList(),
      'dailyBreakdown': dailyBreakdown.map((item) => item.toJson()).toList(),
    };
  }
}

/// Statistique par catégorie
class CategoryStatistic {
  final int categoryId;
  final String categoryName;
  final double amount;
  final int count;
  final double percentage;

  CategoryStatistic({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  factory CategoryStatistic.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    return CategoryStatistic(
      categoryId: parseInt(json['categoryId']),
      categoryName: json['categoryName']?.toString() ?? '',
      amount: parseDouble(json['amount']),
      count: parseInt(json['count']),
      percentage: parseDouble(json['percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'count': count,
      'percentage': percentage,
    };
  }
}

/// Statistique quotidienne
class DailyStatistic {
  final DateTime date;
  final double amount;
  final int count;

  DailyStatistic({
    required this.date,
    required this.amount,
    required this.count,
  });

  factory DailyStatistic.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    DateTime parseDate(dynamic value, {DateTime? defaultValue}) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue ?? DateTime.now();
        }
      }
      return defaultValue ?? DateTime.now();
    }

    return DailyStatistic(
      date: parseDate(json['date']),
      amount: parseDouble(json['amount']),
      count: parseInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'count': count,
    };
  }
}
