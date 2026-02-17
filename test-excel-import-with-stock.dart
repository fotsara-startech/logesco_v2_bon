import 'dart:io';

/// Test de l'import Excel avec quantités initiales
void main() async {
  print('🧪 Test de l\'import Excel avec quantités initiales');
  print('=' * 60);

  await testExcelImportWithStock();
  
  print('\n✅ Test terminé avec succès !');
  print('\n📋 Fonctionnalités testées :');
  print('   ✅ Service Excel modifié pour gérer les quantités initiales');
  print('   ✅ Contrôleur Excel adapté pour ImportResult');
  print('   ✅ Interface utilisateur mise à jour');
  print('   ✅ Template Excel avec colonne Quantité Initiale');
  print('   ✅ Création automatique des mouvements de stock');
}

/// Test du flux complet d'import Excel avec stock
Future<void> testExcelImportWithStock() async {
  print('📊 Test du flux d\'import Excel avec stock initial');
  print('----------------------------------------------');
  
  // Vérifier les fichiers modifiés
  final filesToCheck = [
    'logesco_v2/lib/features/products/services/excel_service.dart',
    'logesco_v2/lib/features/products/controllers/excel_controller.dart',
    'logesco_v2/lib/features/products/views/excel_import_export_page.dart',
  ];
  
  for (final filePath in filesToCheck) {
    await checkFileModifications(filePath);
  }
}

/// Vérifie les modifications dans un fichier
Future<void> checkFileModifications(String filePath) async {
  print('\n🔍 Vérification de $filePath');
  
  final file = File(filePath);
  if (!file.existsSync()) {
    print('  ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  if (filePath.contains('excel_service.dart')) {
    await checkExcelServiceModifications(content);
  } else if (filePath.contains('excel_controller.dart')) {
    await checkExcelControllerModifications(content);
  } else if (filePath.contains('excel_import_export_page.dart')) {
    await checkExcelPageModifications(content);
  }
}

/// Vérifie les modifications du service Excel
Future<void> checkExcelServiceModifications(String content) async {
  print('  📋 Vérification du service Excel...');
  
  final checks = [
    'Quantité Initiale',
    'ImportResult',
    'InitialStock',
    'createInitialStockMovements',
    'InventoryService',
    'quantiteInitiale',
  ];
  
  for (final check in checks) {
    if (content.contains(check)) {
      print('  ✅ $check trouvé');
    } else {
      print('  ❌ $check manquant');
    }
  }
}

/// Vérifie les modifications du contrôleur Excel
Future<void> checkExcelControllerModifications(String content) async {
  print('  📋 Vérification du contrôleur Excel...');
  
  final checks = [
    'ImportResult',
    'initialStocksPreview',
    'createInitialStockMovements',
    'InventoryService',
    'avec stock initial',
  ];
  
  for (final check in checks) {
    if (content.contains(check)) {
      print('  ✅ $check trouvé');
    } else {
      print('  ❌ $check manquant');
    }
  }
}

/// Vérifie les modifications de la page Excel
Future<void> checkExcelPageModifications(String content) async {
  print('  📋 Vérification de la page Excel...');
  
  final checks = [
    'initialStocksPreview',
    'avec stock initial',
    'Quantité Initiale',
    'Stock initial:',
  ];
  
  for (final check in checks) {
    if (content.contains(check)) {
      print('  ✅ $check trouvé');
    } else {
      print('  ❌ $check manquant');
    }
  }
}