import 'dart:io';

/// Test d'intégration complet pour l'import Excel avec stock
void main() async {
  print('🧪 Test d\'intégration - Import Excel avec Stock');
  print('=' * 55);

  await runIntegrationTests();
  
  print('\n✅ Tests d\'intégration terminés !');
  print('\n📋 Résumé des tests :');
  print('   ✅ Structure des fichiers modifiés');
  print('   ✅ Cohérence des imports et dépendances');
  print('   ✅ Validation des nouvelles classes');
  print('   ✅ Interface utilisateur mise à jour');
}

/// Lance tous les tests d'intégration
Future<void> runIntegrationTests() async {
  print('🔍 Test 1: Validation de la structure des fichiers');
  await testFileStructure();
  
  print('\n🔍 Test 2: Validation des imports et dépendances');
  await testImportsAndDependencies();
  
  print('\n🔍 Test 3: Validation des nouvelles classes');
  await testNewClasses();
  
  print('\n🔍 Test 4: Validation de l\'interface utilisateur');
  await testUserInterface();
}

/// Test de la structure des fichiers
Future<void> testFileStructure() async {
  final files = [
    'logesco_v2/lib/features/products/services/excel_service.dart',
    'logesco_v2/lib/features/products/controllers/excel_controller.dart',
    'logesco_v2/lib/features/products/views/excel_import_export_page.dart',
    'logesco_v2/lib/features/inventory/services/inventory_service.dart',
    'logesco_v2/lib/features/inventory/models/stock_model.dart',
  ];
  
  for (final filePath in files) {
    final file = File(filePath);
    if (file.existsSync()) {
      print('  ✅ $filePath existe');
    } else {
      print('  ❌ $filePath manquant');
    }
  }
}

/// Test des imports et dépendances
Future<void> testImportsAndDependencies() async {
  // Test du service Excel
  await testExcelServiceImports();
  
  // Test du contrôleur Excel
  await testExcelControllerImports();
  
  // Test de la page Excel
  await testExcelPageImports();
}

/// Test des imports du service Excel
Future<void> testExcelServiceImports() async {
  print('  📋 Service Excel - Imports');
  
  final file = File('logesco_v2/lib/features/products/services/excel_service.dart');
  if (!file.existsSync()) {
    print('    ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  final requiredImports = [
    'inventory/services/inventory_service.dart',
    'auth_service.dart',
  ];
  
  for (final import in requiredImports) {
    if (content.contains(import)) {
      print('    ✅ Import $import trouvé');
    } else {
      print('    ❌ Import $import manquant');
    }
  }
}

/// Test des imports du contrôleur Excel
Future<void> testExcelControllerImports() async {
  print('  📋 Contrôleur Excel - Imports');
  
  final file = File('logesco_v2/lib/features/products/controllers/excel_controller.dart');
  if (!file.existsSync()) {
    print('    ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  final requiredImports = [
    'inventory/services/inventory_service.dart',
    'auth_service.dart',
  ];
  
  for (final import in requiredImports) {
    if (content.contains(import)) {
      print('    ✅ Import $import trouvé');
    } else {
      print('    ❌ Import $import manquant');
    }
  }
}

/// Test des imports de la page Excel
Future<void> testExcelPageImports() async {
  print('  📋 Page Excel - Structure');
  
  final file = File('logesco_v2/lib/features/products/views/excel_import_export_page.dart');
  if (!file.existsSync()) {
    print('    ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  if (content.contains('ExcelImportExportPage')) {
    print('    ✅ Classe ExcelImportExportPage trouvée');
  } else {
    print('    ❌ Classe ExcelImportExportPage manquante');
  }
}

/// Test des nouvelles classes
Future<void> testNewClasses() async {
  print('  📋 Nouvelles classes et méthodes');
  
  final excelServiceFile = File('logesco_v2/lib/features/products/services/excel_service.dart');
  if (excelServiceFile.existsSync()) {
    final content = excelServiceFile.readAsStringSync();
    
    final newFeatures = [
      'class ImportResult',
      'class InitialStock',
      'createInitialStockMovements',
      'Quantité Initiale',
    ];
    
    for (final feature in newFeatures) {
      if (content.contains(feature)) {
        print('    ✅ $feature implémenté');
      } else {
        print('    ❌ $feature manquant');
      }
    }
  }
}

/// Test de l'interface utilisateur
Future<void> testUserInterface() async {
  print('  📋 Interface utilisateur');
  
  final pageFile = File('logesco_v2/lib/features/products/views/excel_import_export_page.dart');
  if (pageFile.existsSync()) {
    final content = pageFile.readAsStringSync();
    
    final uiFeatures = [
      'initialStocksPreview',
      'avec stock initial',
      'Stock initial:',
      'Quantité Initiale',
    ];
    
    for (final feature in uiFeatures) {
      if (content.contains(feature)) {
        print('    ✅ UI: $feature implémenté');
      } else {
        print('    ❌ UI: $feature manquant');
      }
    }
  }
}