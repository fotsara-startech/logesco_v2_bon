import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/financial_movements/utils/financial_error_handler.dart';
import 'package:logesco_v2/core/utils/exceptions.dart';
import 'dart:io';
import 'dart:async';

void main() {
  group('FinancialErrorHandler', () {
    group('handleError', () {
      test('should handle SocketException as network error', () {
        // Arrange
        final socketException = const SocketException('Connection failed');

        // Act
        final result = FinancialErrorHandler.handleError(socketException);

        // Assert
        expect(result, isA<FinancialMovementException>());
        expect(result.errorType, FinancialErrorType.networkError);
        expect(result.code, 'NETWORK_ERROR');
        expect(result.statusCode, 0);
      });

      test('should handle TimeoutException as timeout error', () {
        // Arrange
        final timeoutException = TimeoutException('Operation timed out', Duration(seconds: 30));

        // Act
        final result = FinancialErrorHandler.handleError(timeoutException, operation: 'test operation');

        // Assert
        expect(result, isA<FinancialMovementException>());
        expect(result.errorType, FinancialErrorType.timeoutError);
        expect(result.code, 'TIMEOUT_ERROR');
        expect(result.statusCode, 408);
        expect(result.details?['operation'], 'test operation');
      });

      test('should handle ApiException correctly', () {
        // Arrange
        final apiException = ApiException(
          message: 'Validation failed',
          code: 'VALIDATION_ERROR',
          statusCode: 400,
        );

        // Act
        final result = FinancialErrorHandler.handleError(apiException);

        // Assert
        expect(result, isA<FinancialMovementException>());
        expect(result.errorType, FinancialErrorType.validationError);
        expect(result.message, 'Validation failed');
        expect(result.code, 'VALIDATION_ERROR');
        expect(result.statusCode, 400);
      });

      test('should handle unknown error as unknown error type', () {
        // Arrange
        final unknownError = Exception('Something went wrong');

        // Act
        final result = FinancialErrorHandler.handleError(unknownError);

        // Assert
        expect(result, isA<FinancialMovementException>());
        expect(result.errorType, FinancialErrorType.unknownError);
        expect(result.code, 'UNKNOWN_ERROR');
        expect(result.statusCode, 500);
      });
    });

    group('FinancialMovementException', () {
      test('should create network error correctly', () {
        // Act
        final exception = FinancialMovementException.networkError(details: 'Connection refused');

        // Assert
        expect(exception.errorType, FinancialErrorType.networkError);
        expect(exception.code, 'NETWORK_ERROR');
        expect(exception.statusCode, 0);
        expect(exception.details?['details'], 'Connection refused');
      });

      test('should create timeout error correctly', () {
        // Act
        final exception = FinancialMovementException.timeout(operation: 'fetch movements');

        // Assert
        expect(exception.errorType, FinancialErrorType.timeoutError);
        expect(exception.code, 'TIMEOUT_ERROR');
        expect(exception.statusCode, 408);
        expect(exception.details?['operation'], 'fetch movements');
      });

      test('should create validation error correctly', () {
        // Arrange
        final fieldErrors = {'amount': 'Amount is required', 'description': 'Description is too long'};

        // Act
        final exception = FinancialMovementException.validation(
          message: 'Validation failed',
          fieldErrors: fieldErrors,
        );

        // Assert
        expect(exception.errorType, FinancialErrorType.validationError);
        expect(exception.code, 'VALIDATION_ERROR');
        expect(exception.statusCode, 400);
        expect(exception.details?['fieldErrors'], fieldErrors);
      });

      test('should determine retryable status correctly', () {
        // Arrange
        final networkError = FinancialMovementException.networkError();
        final timeoutError = FinancialMovementException.timeout();
        final validationError = FinancialMovementException.validation(message: 'Invalid data');
        final serverError = FinancialMovementException(
          message: 'Internal server error',
          code: 'SERVER_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        );

        // Assert
        expect(networkError.isRetryable, true);
        expect(timeoutError.isRetryable, true);
        expect(serverError.isRetryable, true);
        expect(validationError.isRetryable, false);
      });

      test('should provide user-friendly messages', () {
        // Arrange
        final networkError = FinancialMovementException.networkError();
        final authError = FinancialMovementException(
          message: 'Token expired',
          code: 'AUTH_ERROR',
          statusCode: 401,
          errorType: FinancialErrorType.authenticationError,
        );

        // Assert
        expect(networkError.userFriendlyMessage, contains('connexion'));
        expect(authError.userFriendlyMessage, contains('reconnecter'));
      });
    });

    group('Error Recovery', () {
      test('should identify auto-recoverable errors', () {
        // Arrange
        final networkError = FinancialMovementException.networkError();
        final timeoutError = FinancialMovementException.timeout();
        final validationError = FinancialMovementException.validation(message: 'Invalid');
        final serverError = FinancialMovementException(
          message: 'Server error',
          code: 'SERVER_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        );

        // Assert
        expect(FinancialErrorHandler.canAutoRecover(networkError), true);
        expect(FinancialErrorHandler.canAutoRecover(timeoutError), true);
        expect(FinancialErrorHandler.canAutoRecover(serverError), true);
        expect(FinancialErrorHandler.canAutoRecover(validationError), false);
      });

      test('should provide recovery actions', () {
        // Arrange
        final networkError = FinancialMovementException.networkError();
        final authError = FinancialMovementException(
          message: 'Unauthorized',
          code: 'AUTH_ERROR',
          statusCode: 401,
          errorType: FinancialErrorType.authenticationError,
        );

        // Act & Assert
        expect(FinancialErrorHandler.getRecoveryAction(networkError), isNotNull);
        expect(FinancialErrorHandler.getRecoveryAction(authError), contains('Reconnectez-vous'));
      });

      test('should assign error priorities correctly', () {
        // Arrange
        final authError = FinancialMovementException(
          message: 'Unauthorized',
          code: 'AUTH_ERROR',
          statusCode: 401,
          errorType: FinancialErrorType.authenticationError,
        );
        final networkError = FinancialMovementException.networkError();
        final unknownError = FinancialMovementException(
          message: 'Unknown',
          code: 'UNKNOWN',
          statusCode: 500,
          errorType: FinancialErrorType.unknownError,
        );

        // Act & Assert
        expect(FinancialErrorHandler.getErrorPriority(authError), 1);
        expect(FinancialErrorHandler.getErrorPriority(networkError), 5);
        expect(FinancialErrorHandler.getErrorPriority(unknownError), 7);
      });
    });
  });
}
