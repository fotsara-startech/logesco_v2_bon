import 'package:get/get.dart';
import '../utils/app_logger.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';

/// Service de gestion centralisée des erreurs
class ErrorService extends GetxService {
  static ErrorService get instance => Get.find<ErrorService>();

  /// Traite une erreur de façon centralisée
  void handleError(dynamic error, {String? context, bool showToUser = true}) {
    // Log l'erreur
    AppLogger.error('Error handled by ErrorService', error: error, data: {
      'context': context,
      'showToUser': showToUser,
    });

    // Afficher à l'utilisateur si demandé
    if (showToUser) {
      ErrorHandler.showError(error, context: context);
    }

    // Actions spécifiques selon le type d'erreur
    if (error is ApiException) {
      _handleApiError(error);
    } else if (error is BusinessException) {
      _handleBusinessError(error);
    }
  }

  /// Traite les erreurs d'API spécifiquement
  void _handleApiError(ApiException error) {
    // Déconnexion automatique si token expiré
    if (ErrorHandler.requiresReauth(error)) {
      AppLogger.security('Auto logout due to authentication error', data: {
        'errorCode': error.code,
        'statusCode': error.statusCode,
      });

      // Rediriger vers la page de connexion
      Get.offAllNamed('/auth/login');
      ErrorHandler.showWarning('Session expirée. Veuillez vous reconnecter.');
    }

    // Log de sécurité pour les erreurs d'accès
    if (error.statusCode == 403) {
      AppLogger.security('Access denied', data: {
        'errorCode': error.code,
        'message': error.message,
      });
    }
  }

  /// Traite les erreurs métier
  void _handleBusinessError(BusinessException error) {
    AppLogger.audit('Business rule violation', details: {
      'errorCode': error.code,
      'message': error.message,
    });
  }

  /// Traite les erreurs de validation
  Map<String, String> handleValidationErrors(dynamic response) {
    try {
      if (response != null && response.errors != null) {
        return ErrorHandler.handleValidationErrors(response);
      }
    } catch (e) {
      AppLogger.error('Error handling validation errors', error: e);
    }

    return {};
  }

  /// Exécute une opération avec gestion d'erreur automatique
  Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
    String? successMessage,
    bool showSuccess = false,
    bool showError = true,
  }) async {
    try {
      final result = await operation();

      if (showSuccess && successMessage != null) {
        ErrorHandler.showSuccess(successMessage);
      }

      return result;
    } catch (error) {
      handleError(error, context: context, showToUser: showError);
      return null;
    }
  }

  /// Exécute une opération avec retry automatique
  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? context,
  }) async {
    return await ErrorHandler.handleWithRetry(
      operation,
      maxRetries: maxRetries,
      delay: delay,
      context: context,
    );
  }

  /// Vérifie l'état de la connectivité et affiche un message si nécessaire
  void checkConnectivity(dynamic error) {
    if (ErrorHandler.isNetworkError(error)) {
      ErrorHandler.showWarning(
        'Vérifiez votre connexion internet',
        title: 'Connexion',
      );
    }
  }

  /// Traite les erreurs de façon silencieuse (logs uniquement)
  void logSilently(dynamic error, {String? context}) {
    ErrorHandler.logSilently(error, context: context);
  }

  /// Obtient un message d'erreur formaté pour l'utilisateur
  String getErrorMessage(dynamic error, {String? context}) {
    return ErrorHandler.handleError(error, context: context);
  }

  /// Vérifie si une erreur nécessite une action spécifique
  bool requiresSpecialHandling(dynamic error) {
    if (error is ApiException) {
      return ErrorHandler.requiresReauth(error) || error.statusCode == 403 || error.code == 'INSUFFICIENT_STOCK' || error.code == 'CREDIT_LIMIT_EXCEEDED';
    }

    return false;
  }

  /// Traite les erreurs de stock insuffisant
  void handleStockError(InsufficientStockException error) {
    AppLogger.audit('Stock insufficient', details: {
      'productName': error.productName,
      'available': error.available,
      'requested': error.requested,
    });

    ErrorHandler.showWarning(
      error.message,
      title: 'Stock insuffisant',
    );
  }

  /// Traite les erreurs de limite de crédit
  void handleCreditLimitError(ApiException error) {
    AppLogger.audit('Credit limit exceeded', details: {
      'errorCode': error.code,
      'message': error.message,
    });

    ErrorHandler.showWarning(
      error.message,
      title: 'Limite de crédit',
    );
  }
}
