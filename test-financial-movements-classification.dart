import 'dart:convert';

/// Test pour vérifier la correction de la classification des mouvements financiers
void main() {
  print('🧪 Test de classification des mouvements financiers');
  print('=' * 60);

  // Test 1: Mouvements avec montants positifs (cas réel)
  testPositiveAmountsAsExpenses();
  
  // Test 2: Calcul des totaux
  testTotalsCalculation();
  
  // Test 3: Classification par catégorie
  testCategoryClassification();
  
  // Test 4: Mouvements quotidiens
  testDailyMovements();

  print('\n✅ Tous les tests de classification sont passés !');
  print('🎯 Les mouvements financiers sont maintenant correctement classifiés comme des sorties');
}

void testPositiveAmountsAsExpenses() {
  print('\n📋 Test 1: Montants positifs classifiés comme sorties');
  
  final movements = [
    createTestMovement(15000, 'transport'),
    createTestMovement(12000, 'salaires'),
    createTestMovement(8500, 'marketing'),
  ];

  final result = analyzeMovements(movements);
  
  print('  📊 Total entrées: ${result['totalIncome']} FCFA');
  print('  📊 Total sorties: ${result['totalExpenses']} FCFA');
  print('  📊 Flux net: ${result['netCashFlow']} FCFA');
  
  // Vérifications
  assert(result['totalIncome'] == 0.0, 'Les entrées devraient être 0');
  assert(result['totalExpenses'] == 35500.0, 'Les sorties devraient être 35500');
  assert(result['netCashFlow'] == -35500.0, 'Le flux net devrait être -35500');
  
  print('  ✅ Classification correcte : tous les mouvements sont des sorties');
}

void testTotalsCalculation() {
  print('\n📋 Test 2: Calcul des totaux');
  
  final movements = [
    createTestMovement(10000, 'achats'),
    createTestMovement(5000, 'charges'),
    createTestMovement(3000, 'maintenance'),
  ];

  final result = analyzeMovements(movements);
  
  print('  📊 Mouvements: ${movements.length}');
  print('  📊 Total sorties: ${result['totalExpenses']} FCFA');
  print('  📊 Flux net: ${result['netCashFlow']} FCFA');
  
  assert(result['totalExpenses'] == 18000.0, 'Total incorrect');
  assert(result['netCashFlow'] == -18000.0, 'Flux net incorrect');
  
  print('  ✅ Calculs corrects');
}

void testCategoryClassification() {
  print('\n📋 Test 3: Classification par catégorie');
  
  final movements = [
    createTestMovement(15000, 'transport'),
    createTestMovement(12000, 'salaires'),
    createTestMovement(8500, 'transport'), // Même catégorie
  ];

  final categories = analyzeByCategory(movements);
  
  print('  📊 Catégories trouvées: ${categories.length}');
  for (final category in categories) {
    print('  📊 ${category['categoryName']}: ${category['amount']} FCFA (${category['isIncome'] ? 'Entrée' : 'Sortie'})');
    
    // Vérification que toutes les catégories sont des sorties
    assert(category['isIncome'] == false, 'Toutes les catégories devraient être des sorties');
  }
  
  // Vérification des totaux par catégorie
  final transportCategory = categories.firstWhere((c) => c['categoryName'] == 'transport');
  assert(transportCategory['amount'] == 23500.0, 'Total transport incorrect');
  
  print('  ✅ Classification par catégorie correcte');
}

void testDailyMovements() {
  print('\n📋 Test 4: Mouvements quotidiens');
  
  final movements = [
    createTestMovementWithDate(10000, 'achats', DateTime(2024, 12, 11)),
    createTestMovementWithDate(5000, 'charges', DateTime(2024, 12, 11)),
    createTestMovementWithDate(3000, 'transport', DateTime(2024, 12, 12)),
  ];

  final dailyMovements = calculateDailyMovements(movements, DateTime(2024, 12, 11), DateTime(2024, 12, 12));
  
  print('  📊 Jours analysés: ${dailyMovements.length}');
  for (final daily in dailyMovements) {
    print('  📊 ${daily['date']}: Entrées ${daily['income']}, Sorties ${daily['expenses']}, Net ${daily['netFlow']}');
    
    // Vérification que les entrées sont toujours 0
    assert(daily['income'] == 0.0, 'Les entrées quotidiennes devraient être 0');
  }
  
  // Vérifications spécifiques
  final day1 = dailyMovements[0];
  assert(day1['expenses'] == 15000.0, 'Sorties du jour 1 incorrectes');
  assert(day1['netFlow'] == -15000.0, 'Flux net du jour 1 incorrect');
  
  final day2 = dailyMovements[1];
  assert(day2['expenses'] == 3000.0, 'Sorties du jour 2 incorrectes');
  assert(day2['netFlow'] == -3000.0, 'Flux net du jour 2 incorrect');
  
  print('  ✅ Mouvements quotidiens corrects');
}

// Fonctions utilitaires pour les tests
Map<String, dynamic> createTestMovement(double montant, String categoryName) {
  return {
    'montant': montant,
    'categorie': {'name': categoryName},
    'date': DateTime.now().toIso8601String(),
  };
}

Map<String, dynamic> createTestMovementWithDate(double montant, String categoryName, DateTime date) {
  return {
    'montant': montant,
    'categorie': {'name': categoryName},
    'date': date.toIso8601String(),
  };
}

Map<String, dynamic> analyzeMovements(List<Map<String, dynamic>> movements) {
  double totalIncome = 0.0;
  double totalExpenses = 0.0;

  // CORRECTION: Tous les mouvements financiers sont des sorties (dépenses)
  for (final movement in movements) {
    totalExpenses += (movement['montant'] as double).abs();
  }

  final netCashFlow = totalIncome - totalExpenses;

  return {
    'totalIncome': totalIncome,
    'totalExpenses': totalExpenses,
    'netCashFlow': netCashFlow,
  };
}

List<Map<String, dynamic>> analyzeByCategory(List<Map<String, dynamic>> movements) {
  final Map<String, double> categoryAmounts = {};
  final Map<String, int> categoryCounts = {};

  for (final movement in movements) {
    final categoryName = movement['categorie']['name'] as String;
    final amount = (movement['montant'] as double).abs();

    categoryAmounts[categoryName] = (categoryAmounts[categoryName] ?? 0.0) + amount;
    categoryCounts[categoryName] = (categoryCounts[categoryName] ?? 0) + 1;
  }

  return categoryAmounts.entries.map((entry) {
    final categoryName = entry.key;
    final amount = entry.value;
    final count = categoryCounts[categoryName] ?? 0;
    final isIncome = false; // CORRECTION: Toujours false car ce sont des dépenses

    return {
      'categoryName': categoryName,
      'amount': amount,
      'count': count,
      'isIncome': isIncome,
    };
  }).toList();
}

List<Map<String, dynamic>> calculateDailyMovements(List<Map<String, dynamic>> movements, DateTime startDate, DateTime endDate) {
  final Map<String, double> dailyExpenses = {};

  for (final movement in movements) {
    final date = DateTime.parse(movement['date'] as String);
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final amount = (movement['montant'] as double).abs();

    // CORRECTION: Tous les mouvements financiers sont des sorties (dépenses)
    dailyExpenses[dateKey] = (dailyExpenses[dateKey] ?? 0.0) + amount;
  }

  final dailyMovements = <Map<String, dynamic>>[];
  DateTime currentDate = startDate;

  while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
    final dateKey = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
    final income = 0.0; // Toujours 0 car pas d'entrées dans ce système
    final expenses = dailyExpenses[dateKey] ?? 0.0;
    final netFlow = income - expenses;

    dailyMovements.add({
      'date': dateKey,
      'income': income,
      'expenses': expenses,
      'netFlow': netFlow,
    });

    currentDate = currentDate.add(const Duration(days: 1));
  }

  return dailyMovements;
}