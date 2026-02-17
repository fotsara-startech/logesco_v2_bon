import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../../../core/utils/snackbar_utils.dart';

/// Types d'erreurs spécifiques aux mouvements financiers
enum FinancialErrorType {
  networkError,
  authenticationError,
  validationError,
  permissionError,
  notFoundError,
  serverError,
  timeoutError,
  unknownError,
}

/// Exception spécifique aux mouvements financiers
class FinancialMovementException extends ApiException {
  final FinancialErrorType errorType;
  final Map<String, dynamic>? details;

  FinancialMovementException({
    required String message,
    required String code,
    required int statusCode,
    required this.errorType,
    this.details,
  }) : super(message: message, code: code, statusCode: statusCode);

  factory FinancialMovementException.fromApiException(
    ApiException apiException, {
    Map<String, dynamic>? details,
  }) {
    final errorType = _determineErrorType(apiException.statusCode, apiException.code);

    return FinancialMovementException(
      message: apiException.message,
      code: apiException.code,
      statusCode: apiException.statusCode,
      errorType: errorType,
      details: details,
    );
  }

  factory FinancialMovementException.networkError({String? details}) {
    return FinancialMovementException(
      message: 'Erreur de connexion réseau. Vérifiez votre connexion internet.',
      code: 'NETWORK_ERROR',
      statusCode: 0,
      errorType: FinancialErrorType.networkError,
      details: details != null ? {'details': details} : null,
    );
  }

  factory FinancialMovementException.timeout({String? operation}) {
    return FinancialMovementException(
      message: 'L\'opération a pris trop de temps. Veuillez réessayer.',
      code: 'TIMEOUT_ERROR',
      statusCode: 408,
      errorType: FinancialErrorType.timeoutError,
      details: operation != null ? {'operation': operation} : null,
    );
  }

  factory FinancialMovementException.validation({
    required String message,
    Map<String, String>? fieldErrors,
  }) {
    return FinancialMovementException(
      message: message,
      code: 'VALIDATION_ERROR',
      statusCode: 400,
      errorType: FinancialErrorType.validationError,
      details: fieldErrors != null ? {'fieldErrors': fieldErrors} : null,
    );
  }

  static FinancialErrorType _determineErrorType(int statusCode, String code) {
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
      case 0:
        return FinancialErrorType.networkError;
      default:
        return FinancialErrorType.unknownError;
    }
  }

  bool get isRetryable {
    switch (errorType) {
      case FinancialErrorType.networkError:
      case FinancialErrorType.timeoutError:
      case FinancialErrorType.serverError:
        return true;
      case FinancialErrorType.authenticationError:
      case FinancialErrorType.validationError:
      case FinancialErrorType.permissionError:
      case FinancialErrorType.notFoundError:
        return false;
      case FinancialErrorType.unknownError:
        return statusCode >= 500;
    }
  }

  String get userFriendlyMessage {
    switch (errorType) {
      case FinancialErrorType.networkError:
        return 'Problème de connexion. Vérifiez votre réseau et réessayez.';
      case FinancialErrorType.authenticationError:
        return 'Session expirée. Veuillez vous reconnecter.';
      case FinancialErrorType.validationError:
        return message; // Le message de validation est déjà user-friendly
      case FinancialErrorType.permissionError:
        return 'Vous n\'avez pas les permissions nécessaires pour cette action.';
      case FinancialErrorType.notFoundError:
        return 'L\'élément demandé n\'a pas été trouvé.';
      case FinancialErrorType.serverError:
        return 'Erreur du serveur. Veuillez réessayer dans quelques instants.';
      case FinancialErrorType.timeoutError:
        return 'L\'opération a pris trop de temps. Veuillez réessayer.';
      case FinancialErrorType.unknownError:
        return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
    }
  }
}

/// Gestionnaire d'erreurs pour les mouvements financiers
class FinancialErrorHandler {
  /// Traite une erreur et la convertit en FinancialMovementException
  static FinancialMovementException handleError(dynamic error, {String? operation}) {
    if (error is FinancialMovementException) {
      return error;
    }

    if (error is ApiException) {
      return FinancialMovementException.fromApiException(error);
    }

    if (error is SocketException) {
      return FinancialMovementException.networkError(
        details: 'SocketException: ${error.message}',
      );
    }

    if (error is TimeoutException) {
      return FinancialMovementException.timeout(operation: operation);
    }

    if (error is HttpException) {
      return FinancialMovementException(
        message: 'Erreur HTTP: ${error.message}',
        code: 'HTTP_ERROR',
        statusCode: 500,
        errorType: FinancialErrorType.serverError,
        details: {'httpMessage': error.message},
      );
    }

    // Erreur générique
    return FinancialMovementException(
      message: 'Erreur inattendue: ${error.toString()}',
      code: 'UNKNOWN_ERROR',
      statusCode: 500,
      errorType: FinancialErrorType.unknownError,
      details: {'originalError': error.toString()},
    );
  }

  /// Affiche une notification d'erreur à l'utilisateur
  static void showErrorToUser(FinancialMovementException error, {String? context}) {
    final message = error.userFriendlyMessage;

    switch (error.errorType) {
      case FinancialErrorType.networkError:
      case FinancialErrorType.timeoutError:
        SnackbarUtils.showWarning(message);
        break;
      case FinancialErrorType.authenticationError:
        SnackbarUtils.showError(message);
        // Optionnel: rediriger vers la page de connexion
        break;
      case FinancialErrorType.validationError:
        SnackbarUtils.showWarning(message);
        break;
      case FinancialErrorType.permissionError:
        SnackbarUtils.showError(message);
        break;
      case FinancialErrorType.notFoundError:
        SnackbarUtils.showWarning(message);
        break;
      case FinancialErrorType.serverError:
      case FinancialErrorType.unknownError:
        SnackbarUtils.showError(message);
        break;
    }
  }

  /// Détermine si une erreur nécessite une action spéciale
  static bool requiresSpecialAction(FinancialMovementException error) {
    switch (error.errorType) {
      case FinancialErrorType.authenticationError:
        return true; // Redirection vers login
      case FinancialErrorType.permissionError:
        return true; // Redirection ou refresh des permissions
      default:
        return false;
    }
  }

  /// Exécute une action spéciale basée sur le type d'erreur
  static Future<void> executeSpecialAction(FinancialMovementException error) async {
    switch (error.errorType) {
      case FinancialErrorType.authenticationError:
        // Rediriger vers la page de connexion
        Get.offAllNamed('/login');
        break;
      case FinancialErrorType.permissionError:
        // Optionnel: rafraîchir les permissions ou rediriger
        break;
      default:
        break;
    }
  }

  /// Logs une erreur pour le debugging
  static void logError(FinancialMovementException error, {String? operation, Map<String, dynamic>? context}) {
    final logContext = {
      'operation': operation,
      'errorType': error.errorType.toString(),
      'statusCode': error.statusCode,
      'code': error.code,
      'message': error.message,
      if (error.details != null) 'details': error.details,
      if (context != null) 'context': context,
    };

    print('🚨 FinancialMovementError: ${error.errorType} - ${error.message}');
    print('📊 Context: $logContext');
  }

  /// Détermine si une erreur peut être récupérée automatiquement
  static bool canAutoRecover(FinancialMovementException error) {
    switch (error.errorType) {
      case FinancialErrorType.networkError:
      case FinancialErrorType.timeoutError:
        return true;
      case FinancialErrorType.serverError:
        // Récupération possible pour certaines erreurs serveur
        return error.statusCode >= 500 && error.statusCode < 600;
      default:
        return false;
    }
  }

  /// Suggère une action de récupération pour l'utilisateur
  static String? getRecoveryAction(FinancialMovementException error) {
    switch (error.errorType) {
      case FinancialErrorType.networkError:
        return 'Vérifiez votre connexion internet et réessayez';
      case FinancialErrorType.timeoutError:
        return 'Réessayez dans quelques instants';
      case FinancialErrorType.authenticationError:
        return 'Reconnectez-vous à votre compte';
      case FinancialErrorType.permissionError:
        return 'Contactez votre administrateur pour obtenir les permissions nécessaires';
      case FinancialErrorType.serverError:
        return 'Le service est temporairement indisponible, réessayez plus tard';
      default:
        return null;
    }
  }

  /// Obtient la priorité de l'erreur (pour le tri et l'affichage)
  static int getErrorPriority(FinancialMovementException error) {
    switch (error.errorType) {
      case FinancialErrorType.authenticationError:
        return 1; // Priorité maximale
      case FinancialErrorType.permissionError:
        return 2;
      case FinancialErrorType.validationError:
        return 3;
      case FinancialErrorType.serverError:
        return 4;
      case FinancialErrorType.networkError:
      case FinancialErrorType.timeoutError:
        return 5;
      case FinancialErrorType.notFoundError:
        return 6;
      case FinancialErrorType.unknownError:
        return 7; // Priorité minimale
    }
  }
}

/// Extension pour faciliter la gestion d'erreurs dans les services
extension FinancialErrorHandling on Future {
  /// Wrapper pour capturer et traiter les erreurs financières
  Future<T> catchFinancialError<T>({String? operation}) async {
    try {
      return await this as T;
    } catch (error) {
      final financialError = FinancialErrorHandler.handleError(error, operation: operation);
      FinancialErrorHandler.logError(financialError, operation: operation);
      throw financialError;
    }
  }
}
