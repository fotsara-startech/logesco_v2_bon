import 'dart:convert';

/// Test de débogage pour identifier l'erreur de cast dans les mouvements financiers
void main() {
  print('🔍 Test de débogage - Erreur de cast mouvements financiers');
  print('=' * 60);

  // Simulons des données qui pourraient causer l'erreur
  testPotentialProblematicData();
  
  print('\n✅ Tests de débogage terminés');
}

void testPotentialProblematicData() {
  print('\n📋 Test avec des données potentiellement problématiques');
  
  // Cas 1: Données avec des valeurs numériques étranges
  final problematicMovement = {
    'id': 1,
    'reference': 'REF001',
    'montant': double.nan, // Valeur NaN
    'categorieId': 1,
    'description': 'Test movement',
    'date': '2024-12-11T10:00:00Z',
    'utilisateurId': 1,
    'dateCreation': '2024-12-11T10:00:00Z',
    'dateModification': '2024-12-11T10:00:00Z',
  };

  try {
    final movement = FinancialMovement.fromJson(problematicMovement);
    print('  ✅ Mouvement avec NaN créé: montant = ${movement.montant}');
    
    // Test des calculs qui pourraient causer l'erreur
    final movements = [movement];
    final total = movements.fold(0.0, (sum, m) => sum + m.montant);
    print('  📊 Total calculé: $total');
    
    if (total.isNaN) {
      print('  ⚠️ Le total est NaN - cela pourrait causer l\'erreur de cast');
    }
    
    final average = movements.isNotEmpty ? total / movements.length : 0.0;
    print('  📊 Moyenne calculée: $average');
    
    if (average.isNaN) {
      print('  ⚠️ La moyenne est NaN - cela pourrait causer l\'erreur de cast');
    }
    
    // Test de conversion en string (comme dans quickStats)
    try {
      final totalStr = total.toStringAsFixed(0);
      print('  📊 Total formaté: $totalStr');
    } catch (e) {
      print('  ❌ Erreur lors du formatage du total: $e');
    }
    
    try {
      final avgStr = average.toStringAsFixed(0);
      print('  📊 Moyenne formatée: $avgStr');
    } catch (e) {
      print('  ❌ Erreur lors du formatage de la moyenne: $e');
    }
    
  } catch (e) {
    print('  ❌ Erreur lors de la création du mouvement: $e');
  }

  // Cas 2: Test avec des données de statistiques problématiques
  print('\n📋 Test avec des statistiques problématiques');
  
  final problematicStats = {
    'totalAmount': double.infinity,
    'totalCount': 5,
    'averageAmount': double.nan,
    'categoryBreakdown': [
      {
        'categoryId': 1,
        'categoryName': 'Test',
        'amount': null,
        'count': 3,
        'percentage': double.negativeInfinity,
      }
    ],
    'dailyBreakdown': []
  };

  try {
    final stats = MovementStatistics.fromJson(problematicStats);
    print('  ✅ Statistiques créées avec succès');
    print('  📊 Total: ${stats.totalAmount}, Moyenne: ${stats.averageAmount}');
    
    // Test des opérations qui pourraient causer l'erreur
    final categoryStats = stats.categoryBreakdown.first;
    print('  📊 Catégorie: ${categoryStats.categoryName}, Montant: ${categoryStats.amount}');
    
  } catch (e) {
    print('  ❌ Erreur lors de la création des statistiques: $e');
    if (e.toString().contains('type \'Null\' is not a subtype of type \'num\'')) {
      print('  🎯 ERREUR TROUVÉE: C\'est exactement l\'erreur que nous cherchons !');
    }
  }

  // Cas 3: Test avec des données de rapport problématiques
  print('\n📋 Test avec des données de rapport problématiques');
  
  final problematicSummary = {
    'totalAmount': null,
    'totalCount': 'invalid',
    'averageAmount': {},
    'maxAmount': double.infinity,
    'minAmount': double.negativeInfinity,
    'lastMovementDate': null,
  };

  try {
    final summary = MovementSummary.fromJson(problematicSummary);
    print('  ✅ Résumé créé avec succès');
    print('  📊 Total: ${summary.totalAmount}, Moyenne: ${summary.averageAmount}');
    
  } catch (e) {
    print('  ❌ Erreur lors de la création du résumé: $e');
    if (e.toString().contains('type \'Null\' is not a subtype of type \'num\'')) {
      print('  🎯 ERREUR TROUVÉE: C\'est exactement l\'erreur que nous cherchons !');
    }
  }
}

// Classes de test (copies simplifiées des vraies classes)
class FinancialMovement {
  final int id;
  final String reference;
  final double montant;
  final int categorieId;
  final String description;
  final DateTime date;
  final int utilisateurId;
  final DateTime dateCreation;
  final DateTime dateModification;

  FinancialMovement({
    required this.id,
    required this.reference,
    required this.montant,
    required this.categorieId,
    required this.description,
    required this.date,
    required this.utilisateurId,
    required this.dateCreation,
    required this.dateModification,
  });

  factory FinancialMovement.fromJson(Map<String, dynamic> json) {
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

    return FinancialMovement(
      id: parseInt(json['id']),
      reference: json['reference']?.toString() ?? '',
      montant: parseDouble(json['montant']),
      categorieId: parseInt(json['categorieId']),
      description: json['description']?.toString() ?? '',
      date: parseDate(json['date']),
      utilisateurId: parseInt(json['utilisateurId']),
      dateCreation: parseDate(json['dateCreation']),
      dateModification: parseDate(json['dateModification']),
    );
  }
}

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
    return DailyStatistic(
      date: DateTime.now(),
      amount: 0.0,
      count: 0,
    );
  }
}

class MovementSummary {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final double maxAmount;
  final double minAmount;
  final DateTime? lastMovementDate;

  MovementSummary({
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
    required this.maxAmount,
    required this.minAmount,
    this.lastMovementDate,
  });

  factory MovementSummary.fromJson(Map<String, dynamic> json) {
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

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return MovementSummary(
      totalAmount: parseDouble(json['totalAmount']),
      totalCount: parseInt(json['totalCount']),
      averageAmount: parseDouble(json['averageAmount']),
      maxAmount: parseDouble(json['maxAmount']),
      minAmount: parseDouble(json['minAmount']),
      lastMovementDate: parseDate(json['lastMovementDate']),
    );
  }
}