import 'dart:io';

/// Test de débogage pour l'import Excel avec stocks
void main() async {
  print('🔍 Test de débogage - Import Excel avec stocks');
  print('=' * 55);

  await debugExcelImport();
  
  print('\n✅ Test de débogage terminé !');
}

/// Test de débogage de l'import Excel
Future<void> debugExcelImport() async {
  print('📊 Vérification des fichiers modifiés');
  
  // Vérifier le service Excel
  await checkExcelService();
  
  // Vérifier le contrôleur Excel
  await checkExcelController();
  
  // Vérifier le service d'inventaire
  await checkInventoryService();
}

/// Vérifie le service Excel
Future<void> checkExcelService() async {
  print('\n🔍 Vérification du service Excel');
  
  final file = File('logesco_v2/lib/features/products/services/excel_service.dart');
  if (!file.existsSync()) {
    print('  ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Vérifier les logs de débogage
  final debugFeatures = [
    'print(\'🔍 Ligne',
    'print(\'📋 Colonne quantité',
    'print(\'✅ Stock initial ajouté',
    'print(\'📋 Mapping des colonnes',
    'createInitialStockMovements',
  ];
  
  for (final feature in debugFeatures) {
    if (content.contains(feature)) {
      print('  ✅ Debug: $feature trouvé');
    } else {
      print('  ❌ Debug: $feature manquant');
    }
  }
}

/// Vérifie le contrôleur Excel
Future<void> checkExcelController() async {
  print('\n🔍 Vérification du contrôleur Excel');
  
  final file = File('logesco_v2/lib/features/products/controllers/excel_controller.dart');
  if (!file.existsSync()) {
    print('  ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Vérifier la logique corrigée
  final fixes = [
    'stocksCreated = initialStocksPreview.length',
    'await _excelService.createInitialStockMovements',
    'avec \$stocksCreated stocks initiaux',
  ];
  
  for (final fix in fixes) {
    if (content.contains(fix)) {
      print('  ✅ Fix: $fix trouvé');
    } else {
      print('  ❌ Fix: $fix manquant');
    }
  }
}

/// Vérifie le service d'inventaire
Future<void> checkInventoryService() async {
  print('\n🔍 Vérification du service d\'inventaire');
  
  final file = File('logesco_v2/lib/features/inventory/services/inventory_service.dart');
  if (!file.existsSync()) {
    print('  ❌ Fichier non trouvé');
    return;
  }
  
  final content = file.readAsStringSync();
  
  // Vérifier la méthode createStockMovement
  if (content.contains('createStockMovement')) {
    print('  ✅ Méthode createStockMovement trouvée');
    
    // Vérifier les paramètres
    final params = [
      'produitId',
      'typeMouvement',
      'changementQuantite',
      'notes',
      'typeReference',
    ];
    
    for (final param in params) {
      if (content.contains(param)) {
        print('    ✅ Paramètre $param supporté');
      } else {
        print('    ❌ Paramètre $param manquant');
      }
    }
  } else {
    print('  ❌ Méthode createStockMovement non trouvée');
  }
}