import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/financial_movements/services/financial_movement_cache_service.dart';

void main() {
  group('FinancialMovementCacheService', () {
    late FinancialMovementCacheService cacheService;

    setUp(() {
      cacheService = FinancialMovementCacheService();
    });

    test('should generate unique cache keys', () {
      // Act
      final key1 = cacheService.generateCacheKey(page: 1, limit: 20);
      final key2 = cacheService.generateCacheKey(page: 2, limit: 20);
      final key3 = cacheService.generateCacheKey(
        page: 1,
        limit: 20,
        categoryId: 1,
      );

      // Assert
      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
      expect(key2, isNot(equals(key3)));
    });

    test('should generate cache key with search parameter', () {
      // Act
      final key1 = cacheService.generateCacheKey(
        page: 1,
        limit: 20,
        search: 'test search',
      );
      final key2 = cacheService.generateCacheKey(
        page: 1,
        limit: 20,
        search: 'different search',
      );

      // Assert
      expect(key1, isNot(equals(key2)));
      expect(key1, contains('search_'));
      expect(key2, contains('search_'));
    });

    test('should generate cache key with date parameters', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // Act
      final key = cacheService.generateCacheKey(
        page: 1,
        limit: 20,
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(key, contains('start_'));
      expect(key, contains('end_'));
    });

    test('should return default movements key when no filters', () {
      // Act
      final key = cacheService.generateCacheKey();

      // Assert
      expect(key, equals('movements'));
    });
  });
}
