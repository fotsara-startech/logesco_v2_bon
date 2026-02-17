// Test pour vérifier si le problème vient de l'affichage du widget
void main() {
  print('🔍 TEST AFFICHAGE WIDGET');
  print('=' * 40);
  
  testCustomerDebtsDataFormatting();
  testWidgetDisplay();
}

void testCustomerDebtsDataFormatting() {
  print('\n1️⃣ Test du formatage des données');
  print('-' * 30);
  
  // Simulation des données comme elles devraient être
  final customerDebtsData = {
    'totalOutstandingDebt': 4483.78,
    'customersWithDebt': 4,
    'averageDebtPerCustomer': 1120.95,
    'topDebtors': [
      {'customerName': 'Kalonjiiii Robert', 'debtAmount': 2260.0},
      {'customerName': 'Ilunga Daniel', 'debtAmount': 2220.0},
    ]
  };
  
  // Test du formatage comme dans Flutter
  final totalFormatted = '${customerDebtsData['totalOutstandingDebt']!.toStringAsFixed(0)} FCFA';
  final averageFormatted = '${customerDebtsData['averageDebtPerCustomer']!.toStringAsFixed(0)} FCFA';
  
  print('✅ Formatage des données:');
  print('   - Total: $totalFormatted');
  print('   - Clients débiteurs: ${customerDebtsData['customersWithDebt']}');
  print('   - Moyenne: $averageFormatted');
  
  if (totalFormatted.contains('4484') || totalFormatted.contains('4483')) {
    print('✅ Le formatage fonctionne correctement');
  } else {
    print('❌ Problème de formatage');
  }
}

void testWidgetDisplay() {
  print('\n2️⃣ Test de l\'affichage du widget');
  print('-' * 30);
  
  print('🔍 Points à vérifier dans CustomerDebtsWidget:');
  print('   1. Les logs "[CustomerDebtsWidget] Données reçues" apparaissent-ils ?');
  print('   2. Quelle valeur est affichée pour totalOutstandingDebt ?');
  print('   3. Le widget reçoit-il bien les bonnes données ?');
  print('   4. Y a-t-il une conversion incorrecte quelque part ?');
  
  print('\n🎯 SCÉNARIOS POSSIBLES:');
  print('   A. Les données sont nulles → Widget affiche 0');
  print('   B. Les données sont correctes → Problème de formatage');
  print('   C. Exception dans le widget → Affichage par défaut');
  print('   D. Problème de timing → Widget affiché avant les données');
  
  print('\n📱 ACTIONS À FAIRE DANS FLUTTER:');
  print('   1. Ouvrir le module "Bilan d\'activités"');
  print('   2. Générer un bilan pour le mois en cours');
  print('   3. Vérifier les logs dans la console');
  print('   4. Noter exactement ce qui s\'affiche');
}