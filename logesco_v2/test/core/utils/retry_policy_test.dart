import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/core/utils/retry_policy.dart';
import 'package:logesco_v2/core/utils/exceptions.dart';
import 'dart:io';
import 'dart:async';

void main() {
  group('RetryPolicy', () {
    group('Basic Retry Logic', () {
      test('should succeed on first attempt', () async {
        // Arrange
        final policy = RetryPolicy(RetryConfig(maxAttempts: 3));
        var callCount = 0;

        // Act
        final result = await policy.execute(() async {
          callCount++;
          return 'success';
        });

        // Assert
        expect(result, 'success');
        expect(callCount, 1);
      });

      test('should retry on retryable error and succeed', () async {
        // Arrange
        final policy = RetryPolicy(RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ));
        var callCount = 0;

        // Act
        final result = await policy.execute(() async {
          callCount++;
          if (callCount < 3) {
            throw SocketException('Connection failed');
          }
          return 'success';
        });

        // Assert
        expect(result, 'success');
        expect(callCount, 3);
      });

      test('should not retry on non-retryable error', () async {
        // Arrange
        final policy = RetryPolicy(RetryConfig(maxAttempts: 3));
        var callCount = 0;

        // Act & Assert
        try {
          await policy.execute(() async {
            callCount++;
            throw ApiException(
              message: 'Validation error',
              code: 'VALIDATION_ERROR',
              statusCode: 400,
            );
          });
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<ApiException>());
        }

        expect(callCount, 1);
      });

      test('should fail after max attempts', () async {
        // Arrange
        final policy = RetryPolicy(RetryConfig(
          maxAttempts: 2,
          initialDelay: Duration(milliseconds: 10),
        ));
        var callCount = 0;

        // Act & Assert
        try {
          await policy.execute(() async {
            callCount++;
            throw SocketException('Connection failed');
          });
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<SocketException>());
        }

        expect(callCount, 2);
      });
    });

    group('Circuit Breaker', () {
      test('should start in closed state', () {
        // Arrange
        final circuitBreaker = CircuitBreaker(failureThreshold: 3);

        // Assert
        expect(circuitBreaker.state, CircuitBreakerState.closed);
        expect(circuitBreaker.failureCount, 0);
      });

      test('should open circuit after failure threshold', () async {
        // Arrange
        final circuitBreaker = CircuitBreaker(
          failureThreshold: 2,
          resetTimeout: Duration(milliseconds: 100),
        );

        // Act - Cause failures
        for (int i = 0; i < 2; i++) {
          try {
            await circuitBreaker.execute(() async {
              throw Exception('Test failure');
            });
          } catch (e) {
            // Expected
          }
        }

        // Assert
        expect(circuitBreaker.state, CircuitBreakerState.open);
        expect(circuitBreaker.failureCount, 2);
      });

      test('should reject calls when circuit is open', () async {
        // Arrange
        final circuitBreaker = CircuitBreaker(
          failureThreshold: 1,
          resetTimeout: Duration(seconds: 1),
        );

        // Cause circuit to open
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected
        }

        // Act & Assert
        try {
          await circuitBreaker.execute(() async {
            return 'should not execute';
          });
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('Circuit breaker ouvert'));
        }
      });

      test('should transition to half-open after reset timeout', () async {
        // Arrange
        final circuitBreaker = CircuitBreaker(
          failureThreshold: 1,
          resetTimeout: Duration(milliseconds: 50),
        );

        // Cause circuit to open
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected
        }

        expect(circuitBreaker.state, CircuitBreakerState.open);

        // Wait for reset timeout
        await Future.delayed(Duration(milliseconds: 60));

        // Act - Next call should transition to half-open
        try {
          await circuitBreaker.execute(() async {
            return 'success';
          });
        } catch (e) {
          // May fail, but state should change
        }

        // The circuit should either be closed (success) or have attempted half-open
        expect(circuitBreaker.state, CircuitBreakerState.closed);
      });

      test('should reset circuit breaker manually', () async {
        // Arrange
        final circuitBreaker = CircuitBreaker(failureThreshold: 1);

        // Cause circuit to open
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected
        }

        expect(circuitBreaker.state, CircuitBreakerState.open);

        // Act
        circuitBreaker.reset();

        // Assert
        expect(circuitBreaker.state, CircuitBreakerState.closed);
        expect(circuitBreaker.failureCount, 0);
      });
    });

    group('RetryPolicies', () {
      test('should provide different policies for different operations', () {
        // Assert
        expect(RetryPolicies.financialOperations, isA<RetryPolicy>());
        expect(RetryPolicies.financialWriteOperations, isA<RetryPolicy>());
        expect(RetryPolicies.financialCriticalOperations, isA<RetryPolicy>());
        expect(RetryPolicies.cacheOperations, isA<RetryPolicy>());
      });

      test('should reset all circuit breakers', () {
        // Act
        RetryPolicies.resetCircuitBreakers();

        // Assert
        final states = RetryPolicies.getCircuitBreakerStates();
        expect(states['financial_read'], CircuitBreakerState.closed);
        expect(states['financial_write'], CircuitBreakerState.closed);
      });

      test('should provide circuit breaker states', () {
        // Act
        final states = RetryPolicies.getCircuitBreakerStates();

        // Assert
        expect(states, isA<Map<String, CircuitBreakerState>>());
        expect(states.containsKey('financial_read'), true);
        expect(states.containsKey('financial_write'), true);
      });
    });

    group('Error Detection', () {
      test('should detect retryable errors correctly', () async {
        // Arrange
        final policy = RetryPolicy(RetryConfig(maxAttempts: 1));

        // Test different error types
        final retryableErrors = [
          SocketException('Connection failed'),
          TimeoutException('Timeout'),
          HttpException('Server error'),
        ];

        final nonRetryableErrors = [
          ApiException(message: 'Bad request', code: 'BAD_REQUEST', statusCode: 400),
          ApiException(message: 'Unauthorized', code: 'UNAUTHORIZED', statusCode: 401),
          ApiException(message: 'Forbidden', code: 'FORBIDDEN', statusCode: 403),
        ];

        // Test retryable errors (should be detected as retryable)
        for (final error in retryableErrors) {
          var callCount = 0;
          try {
            await RetryPolicy(RetryConfig(maxAttempts: 2, initialDelay: Duration(milliseconds: 1))).execute(() async {
              callCount++;
              throw error;
            });
          } catch (e) {
            // Expected to fail after retries
          }
          expect(callCount, 2, reason: 'Should retry for ${error.runtimeType}');
        }

        // Test non-retryable errors (should not retry)
        for (final error in nonRetryableErrors) {
          var callCount = 0;
          try {
            await policy.execute(() async {
              callCount++;
              throw error;
            });
          } catch (e) {
            // Expected to fail immediately
          }
          expect(callCount, 1, reason: 'Should not retry for ${error.runtimeType}');
        }
      });
    });
  });
}
