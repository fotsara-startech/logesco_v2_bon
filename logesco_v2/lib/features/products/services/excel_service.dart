import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../core/services/auth_service.dart';
import 'category_management_service.dart';

/// Service pour l'import/export Excel des produits
class ExcelService {
  final InventoryService? _inventoryService;
  final CategoryManagementService? _categoryManagementService;

  ExcelService({
    InventoryService? inventoryService,
    CategoryManagementService? categoryManagementService,
  })  : _inventoryService = inventoryService,
        _categoryManagementService = categoryManagementService;

  /// Exporte la liste des produits vers un fichier Excel
  Future<String?> exportProductsToExcel(List<Product> products) async {
    try {
      // Créer un nouveau fichier Excel
      var excel = Excel.createExcel();
      Sheet sheet = excel['Produits'];

      // Supprimer la feuille par défaut si elle existe
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Définir les en-têtes
      List<String> headers = [
        'Référence',
        'Nom',
        'Description',
        'Prix Unitaire',
        'Prix Achat',
        'Code Barre',
        'Catégorie',
        'Seuil Stock Minimum',
        'Remise Max Autorisée',
        'Est Actif',
        'Est Service',
        'Quantité Initiale',
      ];

      // Ajouter les en-têtes
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue200,
        );
      }

      // Ajouter les données des produits
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final rowIndex = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(product.reference);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(product.nom);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(product.description ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(product.prixUnitaire);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = product.prixAchat != null ? DoubleCellValue(product.prixAchat!) : TextCellValue('');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(product.codeBarre ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue(product.categorie ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = IntCellValue(product.seuilStockMinimum);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = DoubleCellValue(product.remiseMaxAutorisee);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex)).value = TextCellValue(product.estActif ? 'Oui' : 'Non');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = TextCellValue(product.estService ? 'Oui' : 'Non');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex)).value = TextCellValue(''); // Quantité initiale vide pour l'export
      }

      // Ajuster la largeur des colonnes
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'produits_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        return filePath;
      }

      return null;
    } catch (e) {
      print('Erreur lors de l\'export Excel: $e');
      return null;
    }
  }

  /// Partage le fichier Excel exporté
  Future<void> shareExcelFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Export des produits');
    } catch (e) {
      print('Erreur lors du partage: $e');
    }
  }

  /// Importe des produits depuis un fichier Excel avec quantités initiales
  Future<ImportResult?> importProductsFromExcel() async {
    try {
      // Sélectionner le fichier Excel
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        Uint8List bytes = result.files.single.bytes!;
        return await _parseExcelBytes(bytes);
      } else if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        Uint8List bytes = await file.readAsBytes();
        return await _parseExcelBytes(bytes);
      }

      return null;
    } catch (e) {
      print('Erreur lors de l\'import Excel: $e');
      return null;
    }
  }

  /// Parse les données Excel et retourne un ImportResult avec produits et quantités
  Future<ImportResult> _parseExcelBytes(Uint8List bytes) async {
    List<ProductForm> products = [];
    List<InitialStock> initialStocks = [];

    try {
      var excel = Excel.decodeBytes(bytes);

      // Prendre la première feuille
      String? sheetName = excel.tables.keys.first;
      Sheet? sheet = excel.tables[sheetName];

      if (sheet == null) return ImportResult(products: products, initialStocks: initialStocks);

      // Vérifier qu'il y a au moins 2 lignes (en-tête + données)
      if (sheet.maxRows < 2) return ImportResult(products: products, initialStocks: initialStocks);

      // Mapper les colonnes (supposer que la première ligne contient les en-têtes)
      Map<String, int> columnMap = {};
      var headerRow = sheet.rows[0];

      for (int i = 0; i < headerRow.length; i++) {
        var cellValue = headerRow[i]?.value?.toString().toLowerCase() ?? '';

        if (cellValue.contains('référence') || cellValue.contains('reference')) {
          columnMap['reference'] = i;
        } else if (cellValue.contains('nom')) {
          columnMap['nom'] = i;
        } else if (cellValue.contains('description')) {
          columnMap['description'] = i;
        } else if (cellValue.contains('prix unitaire') || cellValue.contains('prix_unitaire')) {
          columnMap['prixUnitaire'] = i;
        } else if (cellValue.contains('prix achat') || cellValue.contains('prix_achat')) {
          columnMap['prixAchat'] = i;
        } else if (cellValue.contains('code barre') || cellValue.contains('code_barre')) {
          columnMap['codeBarre'] = i;
        } else if (cellValue.contains('catégorie') || cellValue.contains('categorie')) {
          columnMap['categorie'] = i;
        } else if (cellValue.contains('seuil') || cellValue.contains('stock')) {
          columnMap['seuilStockMinimum'] = i;
        } else if (cellValue.contains('remise')) {
          columnMap['remiseMaxAutorisee'] = i;
        } else if (cellValue.contains('actif')) {
          columnMap['estActif'] = i;
        } else if (cellValue.contains('service')) {
          columnMap['estService'] = i;
        } else if (cellValue.contains('quantité') || cellValue.contains('quantite') || cellValue.contains('qte') || cellValue.contains('stock initial') || cellValue.contains('initiale')) {
          columnMap['quantiteInitiale'] = i;
          print('📋 Colonne quantité trouvée: "$cellValue" -> index $i');
        }
      }

      // Afficher le mapping des colonnes pour débogage
      print('📋 Mapping des colonnes:');
      columnMap.forEach((key, value) => print('  $key -> colonne $value'));

      // Parser chaque ligne de données
      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];

        try {
          // Vérifier que les champs obligatoires sont présents
          String? reference = _getCellValue(row, columnMap['reference']);
          String? nom = _getCellValue(row, columnMap['nom']);
          String? prixUnitaireStr = _getCellValue(row, columnMap['prixUnitaire']);

          if (reference == null || reference.isEmpty || nom == null || nom.isEmpty || prixUnitaireStr == null || prixUnitaireStr.isEmpty) {
            continue; // Ignorer les lignes incomplètes
          }

          double prixUnitaire = double.tryParse(prixUnitaireStr) ?? 0.0;
          if (prixUnitaire <= 0) continue; // Prix invalide

          ProductForm product = ProductForm(
            reference: reference,
            nom: nom,
            description: _getCellValue(row, columnMap['description']),
            prixUnitaire: prixUnitaire,
            prixAchat: _parseDouble(_getCellValue(row, columnMap['prixAchat'])),
            codeBarre: _getCellValue(row, columnMap['codeBarre']),
            categorie: _getCellValue(row, columnMap['categorie']),
            seuilStockMinimum: _parseInt(_getCellValue(row, columnMap['seuilStockMinimum'])) ?? 0,
            remiseMaxAutorisee: _parseDouble(_getCellValue(row, columnMap['remiseMaxAutorisee'])) ?? 0.0,
            estActif: _parseBool(_getCellValue(row, columnMap['estActif'])) ?? true,
            estService: _parseBool(_getCellValue(row, columnMap['estService'])) ?? false,
          );

          products.add(product);

          // Gérer la quantité initiale si ce n'est pas un service
          if (!product.estService) {
            String? quantiteStr = _getCellValue(row, columnMap['quantiteInitiale']);
            print('🔍 Ligne $i - Référence: $reference, Quantité brute: "$quantiteStr"');

            // Toujours créer le stock, même si la quantité n'est pas spécifiée (par défaut: 0)
            int quantiteInitiale = _parseInt(quantiteStr) ?? 0;
            print('🔍 Ligne $i - Quantité parsée: $quantiteInitiale');

            initialStocks.add(InitialStock(
              productReference: reference,
              quantite: quantiteInitiale,
            ));
            print('✅ Stock initial ajouté: $reference -> $quantiteInitiale');
          } else {
            print('ℹ️ Service ignoré pour stock: $reference');
          }
        } catch (e) {
          print('Erreur lors du parsing de la ligne $i: $e');
          continue; // Continuer avec la ligne suivante
        }
      }
    } catch (e) {
      print('Erreur lors du parsing Excel: $e');
    }

    return ImportResult(products: products, initialStocks: initialStocks);
  }

  /// Récupère la valeur d'une cellule de manière sécurisée
  String? _getCellValue(List<Data?> row, int? columnIndex) {
    if (columnIndex == null || columnIndex >= row.length) return null;
    return row[columnIndex]?.value?.toString();
  }

  /// Parse un double de manière sécurisée
  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  /// Parse un entier de manière sécurisée
  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Parse un booléen de manière sécurisée
  bool? _parseBool(String? value) {
    if (value == null || value.isEmpty) return null;
    String lowerValue = value.toLowerCase();
    return lowerValue == 'oui' || lowerValue == 'true' || lowerValue == '1' || lowerValue == 'vrai';
  }

  /// Génère un template Excel pour l'import
  Future<String?> generateImportTemplate() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Template_Produits'];

      // Supprimer la feuille par défaut
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Définir les en-têtes avec des exemples
      List<List<String>> templateData = [
        [
          'Référence',
          'Nom',
          'Description',
          'Prix Unitaire',
          'Prix Achat',
          'Code Barre',
          'Catégorie',
          'Seuil Stock Minimum',
          'Remise Max Autorisée',
          'Est Actif',
          'Est Service',
          'Quantité Initiale',
        ],
        [
          'REF001',
          'Produit Exemple',
          'Description du produit exemple',
          '2500',
          '1500',
          '1234567890123',
          'Électronique',
          '10',
          '5.0',
          'Oui',
          'Non',
          '50',
        ],
        [
          'REF002',
          'Service Exemple',
          'Description du service exemple',
          '5000',
          '',
          '',
          'Services',
          '0',
          '10.0',
          'Oui',
          'Oui',
          '', // Pas de quantité pour les services
        ],
      ];

      // Ajouter les données
      for (int rowIndex = 0; rowIndex < templateData.length; rowIndex++) {
        for (int colIndex = 0; colIndex < templateData[rowIndex].length; colIndex++) {
          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex));
          cell.value = TextCellValue(templateData[rowIndex][colIndex]);

          // Style pour les en-têtes
          if (rowIndex == 0) {
            cell.cellStyle = CellStyle(
              bold: true,
              backgroundColorHex: ExcelColor.green200,
            );
          }
        }
      }

      // Ajuster la largeur des colonnes
      for (int i = 0; i < templateData[0].length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Sauvegarder le template
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'template_import_produits.xlsx';
      final filePath = '${directory.path}/$fileName';

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        return filePath;
      }

      return null;
    } catch (e) {
      print('Erreur lors de la génération du template: $e');
      return null;
    }
  }

  /// Valide et crée automatiquement les catégories manquantes
  Future<void> validateAndCreateCategories(List<ProductForm> products) async {
    if (_categoryManagementService == null) {
      print('⚠️ CategoryManagementService non disponible - catégories non validées');
      return;
    }

    try {
      // Extraire toutes les catégories uniques des produits
      final categoryNames = products.map((p) => p.categorie).where((cat) => cat != null && cat.trim().isNotEmpty).cast<String>().toSet().toList();

      if (categoryNames.isEmpty) {
        print('ℹ️ Aucune catégorie à valider');
        return;
      }

      print('🔍 Validation de ${categoryNames.length} catégories: ${categoryNames.join(', ')}');

      // Valider et créer les catégories manquantes
      final categoryMap = await _categoryManagementService!.validateAndCreateCategories(categoryNames);

      print('✅ ${categoryMap.length} catégories validées/créées');

      // Afficher le résumé
      categoryMap.forEach((name, category) {
        print('  - "$name" → ID: ${category.id}');
      });
    } catch (e) {
      print('❌ Erreur lors de la validation des catégories: $e');
      // Ne pas faire échouer l'import pour autant
    }
  }

  /// Crée les mouvements de stock initiaux après l'import des produits
  Future<void> createInitialStockMovements(List<InitialStock> initialStocks, Map<String, int> productIdMap) async {
    if (_inventoryService == null || initialStocks.isEmpty) return;

    for (final initialStock in initialStocks) {
      final productId = productIdMap[initialStock.productReference];
      if (productId != null) {
        try {
          print('🔄 Tentative création mouvement pour ${initialStock.productReference} (ID: $productId)');
          print('   - Type: achat');
          print('   - Quantité: ${initialStock.quantite}');

          await _inventoryService!.createStockMovement(
            produitId: productId,
            typeMouvement: 'achat',
            changementQuantite: initialStock.quantite,
            notes: 'Stock initial importé depuis Excel',
          );
          print('✅ Stock initial créé pour ${initialStock.productReference}: ${initialStock.quantite}');
        } catch (e) {
          print('❌ Erreur création stock initial pour ${initialStock.productReference}: $e');

          // Essayer avec adjustStock comme alternative
          try {
            print('🔄 Tentative avec adjustStock...');
            await _inventoryService!.adjustStock(
              produitId: productId,
              changementQuantite: initialStock.quantite,
              notes: 'Stock initial importé depuis Excel',
            );
            print('✅ Stock initial créé (adjustStock) pour ${initialStock.productReference}: ${initialStock.quantite}');
          } catch (e2) {
            print('❌ Échec même avec adjustStock: $e2');
          }
        }
      }
    }
  }
}

/// Résultat de l'import Excel avec produits et stocks initiaux
class ImportResult {
  final List<ProductForm> products;
  final List<InitialStock> initialStocks;

  ImportResult({
    required this.products,
    required this.initialStocks,
  });
}

/// Stock initial pour un produit
class InitialStock {
  final String productReference;
  final int quantite;

  InitialStock({
    required this.productReference,
    required this.quantite,
  });
}
