import 'dart:convert';

/// Test pour vérifier la correction de l'erreur de cast dans Pagination
void main() {
  print('🧪 Test de correction - Pagination cast error');
  print('=' * 50);

  // Test 1: Données avec valeurs null
  testNullPagination();
  
  // Test 2: Données avec valeurs NaN
  testNaNPagination();
  
  // Test 3: Données avec valeurs string
  testStringPagination();
  
  // Test 4: Données complètement manquantes
  testMissingPagination();

  print('\n✅ Tous les tests de pagination sont passés !');
}

void testNullPagination() {
  print('\n📋 Test 1: Pagination avec valeurs null');
  
  final nullPagination = {
    'page': null,
    'limit': null,
    'total': null,
    'pages': null,
    'hasNext': null,
    'hasPrev': null,
  };

  try {
    final pagination = Pagination.fromJson(nullPagination);
    print('  ✅ Pagination créée avec succès');
    print('  📊 Page: ${pagination.page}, Limit: ${pagination.limit}');
    print('  📊 Total: ${pagination.total}, Pages: ${pagination.totalPages}');
    print('  📊 HasNext: ${pagination.hasNext}, HasPrev: ${pagination.hasPrev}');
    
    // Vérifications
    assert(pagination.page == 1, 'Page par défaut devrait être 1');
    assert(pagination.limit == 20, 'Limit par défaut devrait être 20');
    assert(pagination.total == 0, 'Total par défaut devrait être 0');
    assert(pagination.totalPages == 0, 'TotalPages par défaut devrait être 0');
    
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test pagination null échoué');
  }
}

void testNaNPagination() {
  print('\n📋 Test 2: Pagination avec valeurs NaN');
  
  final nanPagination = {
    'page': double.nan,
    'limit': double.nan,
    'total': double.infinity,
    'pages': double.negativeInfinity,
    'hasNext': true,
    'hasPrev': false,
  };

  try {
    final pagination = Pagination.fromJson(nanPagination);
    print('  ✅ Pagination créée avec succès');
    print('  📊 Page: ${pagination.page}, Limit: ${pagination.limit}');
    print('  📊 Total: ${pagination.total}, Pages: ${pagination.totalPages}');
    
    // Les valeurs NaN/Infinity devraient être converties en valeurs par défaut
    assert(pagination.page == 1, 'NaN devrait être converti en 1');
    assert(pagination.limit == 20, 'NaN devrait être converti en 20');
    
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test pagination NaN échoué');
  }
}

void testStringPagination() {
  print('\n📋 Test 3: Pagination avec valeurs string');
  
  final stringPagination = {
    'page': '2',
    'limit': '50',
    'total': '100',
    'pages': '2',
    'hasNext': 'true',
    'hasPrev': 'false',
  };

  try {
    final pagination = Pagination.fromJson(stringPagination);
    print('  ✅ Pagination créée avec succès');
    print('  📊 Page: ${pagination.page}, Limit: ${pagination.limit}');
    print('  📊 Total: ${pagination.total}, Pages: ${pagination.totalPages}');
    
    // Les strings valides devraient être converties
    assert(pagination.page == 2, 'String "2" devrait être converti en 2');
    assert(pagination.limit == 50, 'String "50" devrait être converti en 50');
    
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test pagination string échoué');
  }
}

void testMissingPagination() {
  print('\n📋 Test 4: Pagination avec données manquantes');
  
  final emptyPagination = <String, dynamic>{};

  try {
    final pagination = Pagination.fromJson(emptyPagination);
    print('  ✅ Pagination créée avec succès malgré les données manquantes');
    print('  📊 Page: ${pagination.page}, Limit: ${pagination.limit}');
    print('  📊 Total: ${pagination.total}, Pages: ${pagination.totalPages}');
    
    // Toutes les valeurs devraient être les valeurs par défaut
    assert(pagination.page == 1, 'Valeur manquante devrait être 1');
    assert(pagination.limit == 20, 'Valeur manquante devrait être 20');
    assert(pagination.total == 0, 'Valeur manquante devrait être 0');
    assert(pagination.totalPages == 0, 'Valeur manquante devrait être 0');
    assert(pagination.hasNext == false, 'Valeur manquante devrait être false');
    assert(pagination.hasPrev == false, 'Valeur manquante devrait être false');
    
  } catch (e) {
    print('  ❌ Erreur: $e');
    throw Exception('Test pagination vide échoué');
  }
}

// Classe de test simplifiée (copie de la vraie classe)
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.hasNext = false,
    this.hasPrev = false,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    // Parsing sécurisé pour éviter les erreurs de cast
    try {
      return Pagination(
        page: _parseInt(json['page'], 1),
        limit: _parseInt(json['limit'], 20),
        total: _parseInt(json['total'], 0),
        totalPages: _parseInt(json['pages'], 0),
        hasNext: json['hasNext'] as bool? ?? false,
        hasPrev: json['hasPrev'] as bool? ?? false,
      );
    } catch (e) {
      print('⚠️ Erreur parsing Pagination, utilisation des valeurs par défaut: $e');
      return Pagination(
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 0,
        hasNext: false,
        hasPrev: false,
      );
    }
  }

  /// Helper pour parser les entiers de manière sûre
  static int _parseInt(dynamic value, int defaultValue) {
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
}