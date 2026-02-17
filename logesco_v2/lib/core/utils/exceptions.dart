import 'dart:convert';
import 'package:http/http.dart' as http;

/// Exception personnalisée pour les erreurs d'API
class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  ApiException({
    required this.message,
    required this.code,
    required this.statusCode,
  });

  /// Crée une ApiException à partir d'une réponse HTTP
  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = json.decode(response.body);

      // Gestion des différents formats de réponse d'erreur
      String message = 'Erreur inconnue';
      String code = 'UNKNOWN_ERROR';

      if (body is Map<String, dynamic>) {
        // Format standard avec 'message' direct
        if (body.containsKey('message')) {
          message = body['message'] ?? message;
        }

        // Format avec 'error' object
        if (body.containsKey('error') && body['error'] is Map<String, dynamic>) {
          final error = body['error'] as Map<String, dynamic>;
          message = error['message'] ?? message;
          code = error['code'] ?? code;
        }

        // Format avec 'errors' array
        if (body.containsKey('errors') && body['errors'] is List) {
          final errors = body['errors'] as List;
          if (errors.isNotEmpty && errors.first is Map<String, dynamic>) {
            final firstError = errors.first as Map<String, dynamic>;
            message = firstError['message'] ?? message;
            code = firstError['field'] ?? code;
          }
        }
      }

      return ApiException(
        message: message,
        code: code,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiException(
        message: 'Erreur de communication avec le serveur (${response.statusCode})',
        code: 'COMMUNICATION_ERROR',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  String toString() {
    return 'ApiException: $message (Code: $code, Status: $statusCode)';
  }
}

/// Exception pour les erreurs métier
class BusinessException implements Exception {
  final String message;
  final String code;

  BusinessException({
    required this.message,
    required this.code,
  });

  @override
  String toString() {
    return 'BusinessException: $message (Code: $code)';
  }
}

/// Exception pour stock insuffisant
class InsufficientStockException extends BusinessException {
  final String productName;
  final int available;
  final int requested;

  InsufficientStockException({
    required this.productName,
    required this.available,
    required this.requested,
  }) : super(
          message: 'Stock insuffisant pour $productName. Disponible: $available, Demandé: $requested',
          code: 'INSUFFICIENT_STOCK',
        );
}
