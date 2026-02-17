import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'exceptions.dart';

/// État du circuit breaker
enum CircuitBreakerState {
  closed, // Fonctionnement normal
  open, // Circuit ouvert, pas d'appels
  halfOpen, // Test de récupération
}

/// Circuit breaker pour éviter les appels répétés en cas de panne
class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 60),
    this.resetTimeout = const Duration(seconds: 30),
  });

  /// Exécute une opération avec protection du circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
        print('🔄 Circuit breaker: tentative de récupération (half-open)');
      } else {
        throw Exception('Circuit breaker ouvert - service temporairement indisponible');
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  bool _shouldAttemptReset() {
    return _lastFailureTime != null && DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    if (_lastFailureTime != null) {
      print('✅ Circuit breaker: service récupéré (closed)');
      _lastFailureTime = null;
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      print('🚨 Circuit breaker: ouverture du circuit après $_failureCount échecs');
    }
  }

  /// Obtient l'état actuel du circuit breaker
  CircuitBreakerState get state => _state;

  /// Obtient le nombre d'échecs actuels
  int get failureCount => _failureCount;

  /// Réinitialise manuellement le circuit breaker
  void reset() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    _lastFailureTime = null;
    print('🔄 Circuit breaker: réinitialisation manuelle');
  }
}

/// Configuration pour la politique de retry
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final List<int> retryableStatusCodes;
  final List<Type> retryableExceptions;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.retryableExceptions = const [SocketException, TimeoutException, HttpException],
  });

  /// Configuration par défaut pour les opérations de lecture
  static const RetryConfig defaultRead = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 10),
  );

  /// Configuration par défaut pour les opérations d'écriture
  static const RetryConfig defaultWrite = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 5),
    retryableStatusCodes: [408, 429, 500, 502, 503, 504],
  );

  /// Configuration pour les opérations critiques (pas de retry)
  static const RetryConfig noCritical = RetryConfig(
    maxAttempts: 1,
    initialDelay: Duration.zero,
  );
}

/// Politique de retry avec backoff exponentiel et circuit breaker
class RetryPolicy {
  final RetryConfig config;
  final CircuitBreaker? _circuitBreaker;

  const RetryPolicy(this.config, [this._circuitBreaker]);

  /// Exécute une fonction avec retry automatique et circuit breaker
  Future<T> execute<T>(Future<T> Function() operation, {String? operationName}) async {
    // Si un circuit breaker est configuré, l'utilise
    if (_circuitBreaker != null) {
      return await _circuitBreaker.execute(() => _executeWithRetry(operation, operationName: operationName));
    }

    return await _executeWithRetry(operation, operationName: operationName);
  }

  /// Exécute une fonction avec retry automatique (logique interne)
  Future<T> _executeWithRetry<T>(Future<T> Function() operation, {String? operationName}) async {
    Exception? lastException;
    final startTime = DateTime.now();

    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        final result = await operation();

        // Log du succès après retry
        if (attempt > 1) {
          final duration = DateTime.now().difference(startTime);
          print('✅ ${operationName ?? 'Opération'} réussie après $attempt tentatives (${duration.inMilliseconds}ms)');
        }

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Log de l'erreur avec plus de détails
        final duration = DateTime.now().difference(startTime);
        print('⚠️ ${operationName ?? 'Opération'} échouée (tentative $attempt/${config.maxAttempts}, ${duration.inMilliseconds}ms): ${_getErrorSummary(e)}');

        // Vérifie si l'erreur est retryable
        if (!_isRetryable(e) || attempt >= config.maxAttempts) {
          print('❌ ${operationName ?? 'Opération'} échouée définitivement après $attempt tentatives');
          rethrow;
        }

        // Calcule le délai avant le prochain essai
        final delay = _calculateDelay(attempt);
        print('🔄 Nouvelle tentative dans ${delay.inMilliseconds}ms...');

        await Future.delayed(delay);
      }
    }

    // Ne devrait jamais arriver, mais au cas où
    throw lastException ?? Exception('Échec après ${config.maxAttempts} tentatives');
  }

  /// Obtient un résumé de l'erreur pour les logs
  String _getErrorSummary(dynamic error) {
    if (error is SocketException) {
      return 'Erreur réseau: ${error.message}';
    }
    if (error is TimeoutException) {
      return 'Timeout: ${error.message ?? 'Délai dépassé'}';
    }
    if (error is HttpException) {
      return 'Erreur HTTP: ${error.message}';
    }

    final errorStr = error.toString();
    // Limite la longueur du message d'erreur pour les logs
    return errorStr.length > 100 ? '${errorStr.substring(0, 100)}...' : errorStr;
  }

  /// Vérifie si une erreur est retryable
  bool _isRetryable(dynamic error) {
    // Vérifie les types d'exceptions retryables
    for (final exceptionType in config.retryableExceptions) {
      if (error.runtimeType == exceptionType) {
        return true;
      }
    }

    // Vérifie les codes de statut HTTP retryables
    if (error is ApiException) {
      return config.retryableStatusCodes.contains(error.statusCode);
    }

    // Vérifie les erreurs de timeout
    if (error is TimeoutException) {
      return true;
    }

    // Vérifie les erreurs de réseau
    if (error is SocketException || error is HttpException) {
      return true;
    }

    // Vérifie les erreurs spécifiques aux mouvements financiers
    if (error.toString().contains('FinancialMovementException')) {
      // Parse le type d'erreur depuis le message ou utilise une propriété
      final errorString = error.toString().toLowerCase();

      // Erreurs retryables
      if (errorString.contains('network') || errorString.contains('timeout') || errorString.contains('server') || errorString.contains('connection')) {
        return true;
      }

      // Erreurs non retryables
      if (errorString.contains('validation') || errorString.contains('permission') || errorString.contains('authentication') || errorString.contains('not found')) {
        return false;
      }
    }

    // Erreurs de connexion spécifiques
    if (error.toString().contains('Connection refused') || error.toString().contains('Network is unreachable') || error.toString().contains('Connection timed out')) {
      return true;
    }

    return false;
  }

  /// Calcule le délai avec backoff exponentiel et jitter
  Duration _calculateDelay(int attempt) {
    final baseDelay = config.initialDelay.inMilliseconds;
    final exponentialDelay = baseDelay * pow(config.backoffMultiplier, attempt - 1);

    // Ajoute un jitter aléatoire pour éviter le thundering herd
    final jitter = Random().nextDouble() * 0.1 * exponentialDelay;
    final totalDelay = (exponentialDelay + jitter).round();

    // Limite le délai maximum
    final maxDelayMs = config.maxDelay.inMilliseconds;
    final finalDelay = totalDelay > maxDelayMs ? maxDelayMs : totalDelay;

    return Duration(milliseconds: finalDelay);
  }
}

/// Utilitaires pour les politiques de retry communes
class RetryPolicies {
  static const RetryPolicy readOperations = RetryPolicy(RetryConfig.defaultRead);
  static const RetryPolicy writeOperations = RetryPolicy(RetryConfig.defaultWrite);
  static const RetryPolicy criticalOperations = RetryPolicy(RetryConfig.noCritical);

  // Circuit breakers partagés pour les opérations financières
  static final CircuitBreaker _financialCircuitBreaker = CircuitBreaker(
    failureThreshold: 5,
    timeout: Duration(seconds: 60),
    resetTimeout: Duration(seconds: 30),
  );

  static final CircuitBreaker _financialWriteCircuitBreaker = CircuitBreaker(
    failureThreshold: 3,
    timeout: Duration(seconds: 120),
    resetTimeout: Duration(seconds: 60),
  );

  /// Politique personnalisée pour les opérations financières (lecture)
  static final RetryPolicy financialOperations = RetryPolicy(
    const RetryConfig(
      maxAttempts: 3,
      initialDelay: Duration(milliseconds: 500),
      backoffMultiplier: 2.0,
      maxDelay: Duration(seconds: 10),
      retryableStatusCodes: [408, 429, 500, 502, 503, 504],
    ),
    _financialCircuitBreaker,
  );

  /// Politique pour les opérations d'écriture financières (plus conservatrice)
  static final RetryPolicy financialWriteOperations = RetryPolicy(
    const RetryConfig(
      maxAttempts: 2,
      initialDelay: Duration(seconds: 1),
      backoffMultiplier: 1.5,
      maxDelay: Duration(seconds: 5),
      retryableStatusCodes: [408, 429, 500, 502, 503, 504],
    ),
    _financialWriteCircuitBreaker,
  );

  /// Politique pour les opérations critiques financières (suppression, etc.)
  static const RetryPolicy financialCriticalOperations = RetryPolicy(
    RetryConfig(
      maxAttempts: 1,
      initialDelay: Duration.zero,
      retryableStatusCodes: [], // Pas de retry pour les opérations critiques
    ),
  );

  /// Politique pour les opérations de cache (plus agressive)
  static const RetryPolicy cacheOperations = RetryPolicy(
    RetryConfig(
      maxAttempts: 2,
      initialDelay: Duration(milliseconds: 200),
      backoffMultiplier: 1.5,
      maxDelay: Duration(seconds: 2),
      retryableStatusCodes: [408, 429, 500, 502, 503, 504],
    ),
  );

  /// Réinitialise tous les circuit breakers
  static void resetCircuitBreakers() {
    _financialCircuitBreaker.reset();
    _financialWriteCircuitBreaker.reset();
    print('🔄 Tous les circuit breakers financiers ont été réinitialisés');
  }

  /// Obtient l'état des circuit breakers
  static Map<String, CircuitBreakerState> getCircuitBreakerStates() {
    return {
      'financial_read': _financialCircuitBreaker.state,
      'financial_write': _financialWriteCircuitBreaker.state,
    };
  }
}
