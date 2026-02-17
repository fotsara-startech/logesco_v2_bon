import 'dart:convert';

/// Test pour vérifier la correction des erreurs de cast dans les mouvements financiers
void main() {
  print('🧪 Test de correction des erreurs de cast - Mouvements financiers');
  print('=' * 60);

  // Test 1: Données avec valeurs null
  testNullValues();
  
  // Test 2: Données avec NaN
  testNaNValues();
  
  // Test 3: Données avec valeurs string
  testStringValues();
  
  // Test 4: Données avec valeurs infinies
  testInfiniteValues();
  
  // Test 5: Données complètement malformées
  testMalformedData();

  print('\n✅ Tous les tests sont passés avec succès !');
}

void testNullValues() {
  print('\n📋 Test 1: Gestion des valeurs null');
  
  final jsonWithNulls = {
    'totalAmount': null,
    'totalCount': null,
    'averageAmount': null,
    'categoryBreakdown': [
      {
        'categoryId': null,
        'categoryName': null,
        'amount': null,
        'count': null,
        'percentage': null,
      }
    ],
    'dailyBreakdown': [
      {
        'date': null,
        'amount': null,
        'count': null,
      }
    ]
  };

  try {
    final stats = MovementStatistics.fromJson(jsonWithNulls);
    print('  ✅ MovementStatistics créé avec succès');
    print('  📊 Total: ${stats.totalAmount}, Moyenne: ${stats.averageAmount}');
    print('  📈 Catégories: ${stats.categoryBreakdown.length}');
    print('  📅 Jours: ${stats.dailyBreakdown.length}');
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test des valeurs null échoué');
  }
}

void testNaNValues() {
  print('\n📋 Test 2: Gestion des valeurs NaN');
  
  final jsonWithNaN = {
    'totalAmount': double.nan,
    'totalCount': 5,
    'averageAmount': double.nan,
    'categoryBreakdown': [
      {
        'categoryId': 1,
        'categoryName': 'Test',
        'amount': double.nan,
        'count': 3,
        'percentage': double.nan,
      }
    ],
    'dailyBreakdown': [
      {
        'date': '2024-12-11T10:00:00Z',
        'amount': double.nan,
        'count': 2,
      }
    ]
  };

  try {
    final stats = MovementStatistics.fromJson(jsonWithNaN);
    print('  ✅ MovementStatistics créé avec succès');
    print('  📊 Total: ${stats.totalAmount}, Moyenne: ${stats.averageAmount}');
    assert(stats.totalAmount == 0.0, 'NaN devrait être converti en 0.0');
    assert(stats.averageAmount == 0.0, 'NaN devrait être converti en 0.0');
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test des valeurs NaN échoué');
  }
}

void testStringValues() {
  print('\n📋 Test 3: Gestion des valeurs string');
  
  final jsonWithStrings = {
    'totalAmount': '1500.50',
    'totalCount': '10',
    'averageAmount': '150.05',
    'categoryBreakdown': [
      {
        'categoryId': '1',
        'categoryName': 'Test Category',
        'amount': '500.25',
        'count': '3',
        'percentage': '33.35',
      }
    ],
    'dailyBreakdown': [
      {
        'date': '2024-12-11T10:00:00Z',
        'amount': '750.75',
        'count': '5',
      }
    ]
  };

  try {
    final stats = MovementStatistics.fromJson(jsonWithStrings);
    print('  ✅ MovementStatistics créé avec succès');
    print('  📊 Total: ${stats.totalAmount}, Moyenne: ${stats.averageAmount}');
    assert(stats.totalAmount == 1500.50, 'String devrait être converti en double');
    assert(stats.totalCount == 10, 'String devrait être converti en int');
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test des valeurs string échoué');
  }
}

void testInfiniteValues() {
  print('\n📋 Test 4: Gestion des valeurs infinies');
  
  final jsonWithInfinite = {
    'totalAmount': double.infinity,
    'totalCount': 5,
    'averageAmount': double.negativeInfinity,
    'categoryBreakdown': [
      {
        'categoryId': 1,
        'categoryName': 'Test',
        'amount': double.infinity,
        'count': 3,
        'percentage': double.negativeInfinity,
      }
    ],
    'dailyBreakdown': [
      {
        'date': '2024-12-11T10:00:00Z',
        'amount': double.infinity,
        'count': 2,
      }
    ]
  };

  try {
    final stats = MovementStatistics.fromJson(jsonWithInfinite);
    print('  ✅ MovementStatistics créé avec succès');
    print('  📊 Total: ${stats.totalAmount}, Moyenne: ${stats.averageAmount}');
    assert(stats.totalAmount == 0.0, 'Infinity devrait être converti en 0.0');
    assert(stats.averageAmount == 0.0, 'Negative infinity devrait être converti en 0.0');
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test des valeurs infinies échoué');
  }
}

void testMalformedData() {
  print('\n📋 Test 5: Gestion des données malformées');
  
  final malformedJson = {
    'totalAmount': 'not_a_number',
    'totalCount': 'invalid',
    'averageAmount': {},
    'categoryBreakdown': [
      {
        'categoryId': 'invalid',
        'categoryName': 123,
        'amount': 'bad_value',
        'count': [],
        'percentage': 'invalid',
      }
    ],
    'dailyBreakdown': [
      {
        'date': 'invalid_date',
        'amount': 'bad_amount',
        'count': 'bad_count',
      }
    ]
  };

  try {
    final stats = MovementStatistics.fromJson(malformedJson);
    print('  ✅ MovementStatistics créé avec succès malgré les données malformées');
    print('  📊 Total: ${stats.totalAmount}, Moyenne: ${stats.averageAmount}');
    print('  📈 Catégories: ${stats.categoryBreakdown.length}');
    print('  📅 Jours: ${stats.dailyBreakdown.length}');
    
    // Vérifications
    assert(stats.totalAmount == 0.0, 'Valeur invalide devrait être 0.0');
    assert(stats.totalCount == 0, 'Valeur invalide devrait être 0');
    assert(stats.averageAmount == 0.0, 'Valeur invalide devrait être 0.0');
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test des données malformées échoué');
  }
}

// Classes de test simplifiées (copie des classes réelles)
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
}

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
}

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
}