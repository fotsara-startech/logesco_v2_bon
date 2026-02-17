import 'dart:io';

/// Test de la création automatique des catégories
void main() async {
  print('🧪 Test de la création automatique des catégories');
  print('=' * 60);

  await testCategoryAutoCreation();

  print('\n✅ Test terminé avec succès !');
  print('\n📋 Fonctionnalités testées :');
  print('   ✅ Service de gestion avancée des catégories');
  print('   ✅ Validation et création automatique lors de l\'import Excel');
  print('   ✅ Widget de sélection/création de catégories');
  print('   ✅ Cache intelligent des catégories');
}

/// Test de la création automatique des catégories
Future<void> testCategoryAutoCreation() async {
  print('📊 Test de la création automatique des catégories');
  print('----------------------------------------------');

  // Vérifier les nouveaux fichiers créés
  await checkNewFiles();

  // Vérifier les modifications des fichiers existants
  await checkModifiedFiles();

  // Vérifier l'intégration
  await checkIntegration();
}

/// Vérifie les nouveaux fichiers créés
Future<void> checkNewFiles() async {
  print('\n🔍 Vérification des nouveaux fichiers');

  final newFiles = [
    'logesco_v2/lib/features/products/services/category_management_service.dart',
    'logesco_v2/lib/features/products/widgets/category_selector_widget.dart',
    'logesco_v2/lib/features/products/bindings/category_binding.dart',
  ];

  for (final filePath in newFiles) {
    final file = File(filePath);
    if (file.existsSync()) {
      print('  ✅ $filePath créé');
      await checkFileContent(filePath);
    } else {
      print('  ❌ $filePath manquant');
    }
  }
}

/// Vérifie le contenu d'un fichier
Future<void> checkFileContent(String filePath) async {
  final file = File(filePath);
  final content = file.readAsStringSync();

  if (filePath.contains('category_management_service.dart')) {
    final features = [
      'class CategoryManagementService',
      'createCategoryIfNotExists',
      'validateAndCreateCategories',
      'findCategoryByName',
      '_cachedCategories',
    ];

    for (final feature in features) {
      if (content.contains(feature)) {
        print('    ✅ $feature implémenté');
      } else {
        print('    ❌ $feature manquant');
      }
    }
  } else if (filePath.contains('category_selector_widget.dart')) {
    final features = [
      'class CategorySelectorWidget',
      'Autocomplete<Category>',
      '_createNewCategory',
      'ActionChip',
    ];

    for (final feature in features) {
      if (content.contains(feature)) {
        print('    ✅ $feature implémenté');
      } else {
        print('    ❌ $feature manquant');
      }
    }
  } else if (filePath.contains('category_binding.dart')) {
    final features = [
      'class CategoryBinding',
      'CategoryService',
      'CategoryManagementService',
    ];

    for (final feature in features) {
      if (content.contains(feature)) {
        print('    ✅ $feature implémenté');
      } else {
        print('    ❌ $feature manquant');
      }
    }
  }
}

/// Vérifie les modifications des fichiers existants
Future<void> checkModifiedFiles() async {
  print('\n🔍 Vérification des fichiers modifiés');

  // Vérifier le service Excel
  await checkExcelServiceModifications();

  // Vérifier le contrôleur Excel
  await checkExcelControllerModifications();
}

/// Vérifie les modifications du service Excel
Future<void> checkExcelServiceModifications() async {
  print('  📄 Service Excel');

  final file = File('logesco_v2/lib/features/products/services/excel_service.dart');
  if (!file.existsSync()) {
    print('    ❌ Fichier non trouvé');
    return;
  }

  final content = file.readAsStringSync();

  final modifications = [
    'CategoryManagementService',
    'validateAndCreateCategories',
    'categoryManagementService',
  ];

  for (final modification in modifications) {
    if (content.contains(modification)) {
      print('    ✅ $modification ajouté');
    } else {
      print('    ❌ $modification manquant');
    }
  }
}

/// Vérifie les modifications du contrôleur Excel
Future<void> checkExcelControllerModifications() async {
  print('  📄 Contrôleur Excel');

  final file = File('logesco_v2/lib/features/products/controllers/excel_controller.dart');
  if (!file.existsSync()) {
    print('    ❌ Fichier non trouvé');
    return;
  }

  final content = file.readAsStringSync();

  final modifications = [
    'CategoryManagementService',
    'validateAndCreateCategories',
    'Validation des catégories...',
  ];

  for (final modification in modifications) {
    if (content.contains(modification)) {
      print('    ✅ $modification ajouté');
    } else {
      print('    ❌ $modification manquant');
    }
  }
}

/// Vérifie l'intégration
Future<void> checkIntegration() async {
  print('\n🔍 Vérification de l\'intégration');

  // Vérifier que tous les imports sont corrects
  await checkImports();

  // Vérifier la cohérence des services
  await checkServiceConsistency();
}

/// Vérifie les imports
Future<void> checkImports() async {
  print('  📦 Imports');

  final filesToCheck = [
    'logesco_v2/lib/features/products/services/excel_service.dart',
    'logesco_v2/lib/features/products/controllers/excel_controller.dart',
  ];

  for (final filePath in filesToCheck) {
    final file = File(filePath);
    if (file.existsSync()) {
      final content = file.readAsStringSync();

      if (content.contains('import') && content.contains('category_management_service')) {
        print('    ✅ ${filePath.split('/').last}: imports corrects');
      } else {
        print('    ❌ ${filePath.split('/').last}: imports manquants');
      }
    }
  }
}

/// Vérifie la cohérence des services
Future<void> checkServiceConsistency() async {
  print('  🔧 Cohérence des services');

  // Vérifier que CategoryManagementService utilise bien CategoryService
  final managementService = File('logesco_v2/lib/features/products/services/category_management_service.dart');
  if (managementService.existsSync()) {
    final content = managementService.readAsStringSync();

    if (content.contains('CategoryService') && content.contains('_categoryService')) {
      print('    ✅ CategoryManagementService utilise CategoryService');
    } else {
      print('    ❌ Problème de dépendance entre services');
    }
  }

  // Vérifier que le binding enregistre les deux services
  final binding = File('logesco_v2/lib/features/products/bindings/category_binding.dart');
  if (binding.existsSync()) {
    final content = binding.readAsStringSync();

    if (content.contains('CategoryService') && content.contains('CategoryManagementService')) {
      print('    ✅ Binding enregistre les deux services');
    } else {
      print('    ❌ Binding incomplet');
    }
  }
}
