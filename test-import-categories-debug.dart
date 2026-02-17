import 'dart:io';

/// Test de débogage pour les catégories dans l'import Excel
void main() async {
  print('🔍 Test de débogage - Catégories dans l\'import Excel');
  print('=' * 60);

  await debugCategoriesImport();
  
  print('\n✅ Test de débogage des catégories terminé !');
  print('\n📋 Recommandations :');
  print('   1. Vérifier que les catégories existent dans le système avant l\'import');
  print('   2. Créer automatiquement les catégories manquantes lors de l\'import');
  print('   3. Ajouter une validation des catégories dans le service API');
}

/// Test de débogage des catégories
Future<void> debugCategoriesImport() async {
  print('📊 Analyse du traitement des catégories');
  
  // Vérifier le service API des produits
  await checkProductApiService();
  
  // Vérifier le modèle ProductForm
  await checkProductModel();
  
  // Proposer des améliorations
  await proposeImprovements();
}

/// Vérifie le service API des produits
Future<void> checkProductApiService() async {
  print('\n🔍 Vérification du service API des produits');
  
  final file = File('logesco_v2/lib/features/products/services/api_product_service.dart');
  if (!file.existsSync()) {
    print('  ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Vérifier les méthodes liées aux catégories
  final categoryFeatures = [
    'getCategories',
    'categorie',
    'categories',
  ];
  
  for (final feature in categoryFeatures) {
    if (content.contains(feature)) {
      print('  ✅ Catégorie: $feature trouvé');
    } else {
      print('  ❌ Catégorie: $feature manquant');
    }
  }
  
  // Vérifier la méthode d'import
  if (content.contains('importProducts')) {
    print('  ✅ Méthode importProducts trouvée');
    
    // Vérifier si elle gère les catégories
    final importSection = content.substring(
      content.indexOf('importProducts'),
      content.indexOf('}', content.indexOf('importProducts')) + 1
    );
    
    if (importSection.contains('categorie')) {
      print('    ✅ Import gère les catégories');
    } else {
      print('    ⚠️ Import ne mentionne pas les catégories explicitement');
    }
  }
}

/// Vérifie le modèle ProductForm
Future<void> checkProductModel() async {
  print('\n🔍 Vérification du modèle ProductForm');
  
  final file = File('logesco_v2/lib/features/products/models/product.dart');
  if (!file.existsSync()) {
    print('  ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Vérifier la classe ProductForm
  if (content.contains('class ProductForm')) {
    print('  ✅ Classe ProductForm trouvée');
    
    // Vérifier le champ catégorie
    final productFormSection = content.substring(
      content.indexOf('class ProductForm'),
      content.indexOf('class', content.indexOf('class ProductForm') + 1) != -1 
        ? content.indexOf('class', content.indexOf('class ProductForm') + 1)
        : content.length
    );
    
    if (productFormSection.contains('categorie')) {
      print('    ✅ Champ catégorie présent');
      
      // Vérifier le type
      if (productFormSection.contains('String? categorie')) {
        print('    ✅ Type String? categorie correct');
      } else if (productFormSection.contains('String categorie')) {
        print('    ✅ Type String categorie correct');
      } else {
        print('    ⚠️ Type de catégorie non standard');
      }
    } else {
      print('    ❌ Champ catégorie manquant');
    }
    
    // Vérifier la méthode toJson
    if (productFormSection.contains('toJson')) {
      print('    ✅ Méthode toJson présente');
      
      if (productFormSection.contains('\'categorie\': categorie')) {
        print('      ✅ Catégorie incluse dans toJson');
      } else {
        print('      ❌ Catégorie non incluse dans toJson');
      }
    }
  }
}

/// Propose des améliorations
Future<void> proposeImprovements() async {
  print('\n💡 Améliorations proposées');
  
  print('  1. 🔧 Validation des catégories :');
  print('     - Vérifier que la catégorie existe avant l\'import');
  print('     - Créer automatiquement les catégories manquantes');
  
  print('  2. 🔧 Logs de débogage :');
  print('     - Ajouter des logs pour tracer les catégories importées');
  print('     - Afficher les catégories créées/liées');
  
  print('  3. 🔧 Interface utilisateur :');
  print('     - Afficher les catégories dans l\'aperçu d\'import');
  print('     - Permettre la modification des catégories avant import');
  
  print('  4. 🔧 Backend :');
  print('     - S\'assurer que l\'API gère correctement les catégories');
  print('     - Retourner les catégories dans la réponse d\'import');
}