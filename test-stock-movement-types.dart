import 'dart:io';

/// Test pour identifier les types de mouvements de stock valides
void main() async {
  print('🔍 Test des types de mouvements de stock');
  print('=' * 50);

  await testMovementTypes();
  
  print('\n✅ Test terminé !');
  print('\n📋 Recommandations :');
  print('   1. Vérifier la documentation API pour les types valides');
  print('   2. Tester avec différents types de mouvements');
  print('   3. Simplifier les paramètres si nécessaire');
}

/// Test des types de mouvements
Future<void> testMovementTypes() async {
  print('📊 Analyse des types de mouvements possibles');
  
  // Types couramment utilisés
  final commonTypes = [
    'entree',
    'sortie', 
    'ajustement',
    'achat',
    'vente',
    'retour',
    'approvisionnement',
    'ENTREE',
    'SORTIE',
    'AJUSTEMENT',
    'ACHAT',
    'VENTE',
    'RETOUR',
    'APPROVISIONNEMENT',
  ];
  
  print('\n🔍 Types de mouvements à tester :');
  for (final type in commonTypes) {
    print('  - $type');
  }
  
  // Vérifier les fichiers de test pour des indices
  await checkTestFiles();
  
  // Vérifier les modèles
  await checkModels();
}

/// Vérifie les fichiers de test pour des indices
Future<void> checkTestFiles() async {
  print('\n🔍 Recherche dans les fichiers de test');
  
  final testFiles = [
    'test-inventory-features.dart',
    'test-financial-movements-classification.dart',
    'test_cash_register_module.dart',
  ];
  
  for (final fileName in testFiles) {
    final file = File(fileName);
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      
      // Rechercher des types de mouvements
      final types = <String>[];
      
      if (content.contains('entree')) types.add('entree');
      if (content.contains('sortie')) types.add('sortie');
      if (content.contains('ajustement')) types.add('ajustement');
      if (content.contains('achat')) types.add('achat');
      if (content.contains('vente')) types.add('vente');
      if (content.contains('retour')) types.add('retour');
      
      if (types.isNotEmpty) {
        print('  📄 $fileName: ${types.join(', ')}');
      }
    }
  }
}

/// Vérifie les modèles pour des indices
Future<void> checkModels() async {
  print('\n🔍 Vérification des modèles');
  
  final modelFile = File('logesco_v2/lib/features/inventory/models/stock_model.dart');
  if (modelFile.existsSync()) {
    final content = modelFile.readAsStringSync();
    
    print('  📄 Modèle StockMovement analysé');
    
    // Rechercher des validations ou énumérations
    if (content.contains('enum')) {
      print('    ✅ Énumération trouvée dans le modèle');
    } else {
      print('    ⚠️ Pas d\'énumération explicite');
    }
    
    // Rechercher des types spécifiques
    final types = <String>[];
    if (content.contains('\'entree\'')) types.add('entree');
    if (content.contains('\'sortie\'')) types.add('sortie');
    if (content.contains('\'ajustement\'')) types.add('ajustement');
    
    if (types.isNotEmpty) {
      print('    📋 Types trouvés: ${types.join(', ')}');
    }
  }
}

/// Propose des solutions
void proposeSolutions() {
  print('\n💡 Solutions proposées :');
  
  print('  1. 🔧 Tester les types un par un :');
  print('     - Commencer par "ajustement" (le plus probable)');
  print('     - Essayer "entree" en minuscules');
  print('     - Tester "achat" pour les entrées de stock');
  
  print('  2. 🔧 Simplifier les paramètres :');
  print('     - Utiliser seulement les champs obligatoires');
  print('     - Éviter typeReference si optionnel');
  
  print('  3. 🔧 Vérifier la documentation API :');
  print('     - Consulter le backend pour les types valides');
  print('     - Vérifier les validations côté serveur');
  
  print('  4. 🔧 Alternative - Utiliser adjustStock :');
  print('     - Si createStockMovement ne fonctionne pas');
  print('     - Utiliser la méthode adjustStock existante');
}