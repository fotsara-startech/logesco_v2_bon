import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/api_response.dart';
import 'exceptions.dart';

/// Gestionnaire centralisé des erreurs pour l'application LOGESCO
class ErrorHandler {
  static const String _logTag = 'LOGESCO_ERROR';

  /// Traite une erreur et retourne un message utilisateur approprié
  static String handleError(dynamic error, {String? context}) {
    String userMessage;
    String logMessage;

    if (error is ApiException) {
      userMessage = _handleApiException(error);
      logMessage = 'API Error: ${error.message} (Code: ${error.code}, Status: ${error.statusCode})';
    } else if (error is BusinessException) {
      userMessage = error.message;
      logMessage = 'Business Error: ${error.message} (Code: ${error.code})';
    } else if (error is InsufficientStockException) {
      userMessage = error.message;
      logMessage = 'Stock Error: ${error.message}';
    } else {
      userMessage = 'Une erreur inattendue s\'est produite';
      logMessage = 'Unexpected Error: ${error.toString()}';
    }

    // Log l'erreur avec contexte
    _logError(logMessage, error, context);

    return userMessage;
  }

  /// Traite spécifiquement les erreurs d'API
  static String _handleApiException(ApiException error) {
    switch (error.code) {
      case 'NO_INTERNET':
        return 'Vérifiez votre connexion internet';
      case 'AUTHENTICATION_REQUIRED':
        return 'Veuillez vous reconnecter';
      case 'ACCESS_DENIED':
        return 'Vous n\'avez pas les permissions nécessaires';
      case 'RESOURCE_NOT_FOUND':
        return 'Ressource non trouvée';
      case 'VALIDATION_ERROR':
        return 'Données invalides: ${error.message}';
      case 'INSUFFICIENT_STOCK':
        return error.message;
      case 'CREDIT_LIMIT_EXCEEDED':
        return error.message;
      case 'DUPLICATE_PRODUCT_REFERENCE':
        return 'Cette référence produit existe déjà';
      case 'DELETE_CONSTRAINT_VIOLATION':
        return 'Impossible de supprimer: élément lié à d\'autres données';
      case 'INVALID_TRANSACTION':
        return 'Transaction invalide: ${error.message}';
      case 'ORDER_ALREADY_PROCESSED':
        return error.message;
      case 'SALE_ALREADY_CANCELLED':
        return error.message;
      case 'DATABASE_ERROR':
        return 'Erreur de base de données. Veuillez réessayer';
      case 'CONFIGURATION_ERROR':
        return 'Erreur de configuration. Contactez l\'administrateur';
      default:
        if (error.statusCode >= 500) {
          return 'Erreur serveur. Veuillez réessayer plus tard';
        } else if (error.statusCode == 429) {
          return 'Trop de requêtes. Veuillez patienter';
        } else {
          return error.message.isNotEmpty ? error.message : 'Erreur inconnue';
        }
    }
  }

  /// Affiche un message d'erreur à l'utilisateur
  static void showError(dynamic error, {String? context, String? title}) {
    final message = handleError(error, context: context);

    Get.snackbar(
      title ?? 'Erreur',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Affiche un message de succès
  static void showSuccess(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Succès',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Affiche un message d'information
  static void showInfo(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Information',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.surface,
      colorText: Get.theme.colorScheme.onSurface,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Affiche un message d'avertissement
  static void showWarning(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Attention',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.secondary,
      colorText: Get.theme.colorScheme.onSecondary,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Gère les erreurs de validation de formulaire
  static Map<String, String> handleValidationErrors(ApiResponse response) {
    final errors = <String, String>{};

    if (response.errors != null) {
      for (final error in response.errors!) {
        errors[error.field] = error.message;
      }
    }

    return errors;
  }

  /// Vérifie si une erreur nécessite une reconnexion
  static bool requiresReauth(dynamic error) {
    if (error is ApiException) {
      return error.code == 'AUTHENTICATION_REQUIRED' || error.statusCode == 401;
    }
    return false;
  }

  /// Vérifie si une erreur est liée au réseau
  static bool isNetworkError(dynamic error) {
    if (error is ApiException) {
      return error.code == 'NO_INTERNET' || error.statusCode == 0;
    }
    return false;
  }

  /// Log une erreur avec contexte
  static void _logError(String message, dynamic error, String? context) {
    final logData = <String, dynamic>{
      'message': message,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'error_type': error.runtimeType.toString(),
    };

    if (error is ApiException) {
      logData.addAll({
        'api_code': error.code,
        'status_code': error.statusCode,
      });
    }

    if (kDebugMode) {
      developer.log(
        message,
        name: _logTag,
        error: error,
        time: DateTime.now(),
      );
    }

    // En production, on pourrait envoyer les logs à un service externe
    // comme Firebase Crashlytics ou Sentry
  }

  /// Traite les erreurs de façon asynchrone avec retry
  static Future<T?> handleWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? context,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempts++;

        if (attempts >= maxRetries || !_shouldRetry(error)) {
          showError(error, context: context);
          return null;
        }

        // Attendre avant de réessayer
        await Future.delayed(delay * attempts);
      }
    }

    return null;
  }

  /// Détermine si une erreur justifie un retry
  static bool _shouldRetry(dynamic error) {
    if (error is ApiException) {
      // Retry pour les erreurs réseau et serveur
      return error.statusCode == 0 || error.statusCode >= 500 || error.code == 'NO_INTERNET';
    }
    return false;
  }

  /// Traite les erreurs de façon silencieuse (sans affichage utilisateur)
  static void logSilently(dynamic error, {String? context}) {
    final message = 'Silent error: ${error.toString()}';
    _logError(message, error, context);
  }

  /// Crée un wrapper pour les opérations avec gestion d'erreur automatique
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? context,
    String? successMessage,
    bool showSuccess = false,
  }) async {
    try {
      final result = await operation();

      if (showSuccess && successMessage != null) {
        ErrorHandler.showSuccess(successMessage);
      }

      return result;
    } catch (error) {
      showError(error, context: context);
      return null;
    }
  }
}
