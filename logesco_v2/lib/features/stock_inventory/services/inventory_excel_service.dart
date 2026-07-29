import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/inventory_model.dart';

/// Service pour l'export et l'import Excel des fiches de comptage
class InventoryExcelService {
  /// Exporter la fiche de comptage en Excel
  static Future<String> exportCountingSheet(
    StockInventory inventory,
    List<InventoryItem> items,
  ) async {
    try {
      // Créer un nouveau document Excel
      final excel = Excel.createExcel();
      final sheet = excel['Fiche_Comptage'];

      // Supprimer la feuille par défaut si elle existe
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // === EN-TÊTE DU DOCUMENT ===
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('F1'),
      );
      final titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('FICHE DE COMPTAGE D\'INVENTAIRE');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Informations de l'inventaire
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Inventaire:');
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(inventory.nom);
      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Type:');
      sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(inventory.type.displayName);
      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Date:');
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue(DateTime.now().toString().substring(0, 10));

      // === EN-TÊTES DES COLONNES ===
      const headers = [
        'Code',
        'Produit',
        'Catégorie',
        'Stock Système',
        'Qté Comptée',
        'Écart',
        'Commentaire',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 7));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // === DONNÉES DES PRODUITS ===
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final rowIndex = i + 8; // Commencer après les en-têtes

        // Code produit
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(item.codeProduit ?? '');

        // Nom produit
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(item.nomProduit);

        // Catégorie
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(item.categorieProduit ?? '');

        // Stock système
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(item.quantiteSysteme);

        // Quantité comptée (vide pour remplissage manuel)
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(item.quantiteComptee?.toString() ?? '');

        // Écart (formule Excel)
        final ecartCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex));
        ecartCell.value = FormulaCellValue('=E${rowIndex + 1}-D${rowIndex + 1}');

        // Commentaire
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue(item.commentaire ?? '');
      }

      // === INSTRUCTIONS AU BAS ===
      final instructionRow = items.length + 10;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: instructionRow)).value = TextCellValue('INSTRUCTIONS:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: instructionRow + 1)).value = TextCellValue('1. Remplir la colonne "Qté Comptée" avec les quantités physiques');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: instructionRow + 2)).value = TextCellValue('2. L\'écart sera calculé automatiquement');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: instructionRow + 3)).value = TextCellValue('3. Ajouter un commentaire si nécessaire');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: instructionRow + 4)).value = TextCellValue('4. Sauvegarder et réimporter le fichier');

      // === AJUSTEMENT DES LARGEURS DE COLONNES ===
      sheet.setColumnWidth(0, 15); // Code
      sheet.setColumnWidth(1, 35); // Produit
      sheet.setColumnWidth(2, 20); // Catégorie
      sheet.setColumnWidth(3, 15); // Stock Système
      sheet.setColumnWidth(4, 15); // Qté Comptée
      sheet.setColumnWidth(5, 12); // Écart
      sheet.setColumnWidth(6, 30); // Commentaire

      // === SAUVEGARDE DU FICHIER ===
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'Fiche_Comptage_${inventory.nom.replaceAll(' ', '_')}_$timestamp.xlsx';
      final filePath = '${directory.path}/$filename';

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      } else {
        throw Exception('Impossible de générer le fichier Excel');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'export Excel: $e');
    }
  }

  /// Importer une fiche de comptage depuis Excel
  static Future<List<CountingSheetImport>> importCountingSheet() async {
    try {
      // Ouvrir le sélecteur de fichier
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('Aucun fichier sélectionné');
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Prendre la première feuille
      final sheet = excel.sheets[excel.sheets.keys.first];
      if (sheet == null) {
        throw Exception('Feuille Excel vide');
      }

      final imports = <CountingSheetImport>[];

      // Parcourir les lignes à partir de la ligne 8 (après les en-têtes)
      for (var i = 8; i < sheet.maxRows; i++) {
        // Vérifier si c'est une ligne de données valide
        final codeCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
        final produitCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i));
        final qteCompteeCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i));

        // Si le nom du produit est vide, on arrête (fin des données)
        if (produitCell.value == null || produitCell.value.toString().isEmpty) {
          break;
        }

        // Extraire les données
        final codeProduit = codeCell.value?.toString();
        final nomProduit = produitCell.value?.toString() ?? '';

        // Essayer d'extraire la quantité comptée
        double? quantiteComptee;
        if (qteCompteeCell.value != null) {
          final value = qteCompteeCell.value;
          if (value is DoubleCellValue) {
            quantiteComptee = value.value;
          } else if (value is IntCellValue) {
            quantiteComptee = value.value.toDouble();
          } else {
            // Essayer de parser la valeur comme string
            final strValue = value.toString().trim();
            if (strValue.isNotEmpty) {
              quantiteComptee = double.tryParse(strValue);
            }
          }
        }

        // Si une quantité a été saisie, on l'ajoute à la liste
        if (quantiteComptee != null) {
          final commentaireCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i));
          final commentaire = commentaireCell.value?.toString();

          imports.add(CountingSheetImport(
            codeProduit: codeProduit,
            nomProduit: nomProduit,
            quantiteComptee: quantiteComptee,
            commentaire: commentaire,
          ));
        }
      }

      return imports;
    } catch (e) {
      throw Exception('Erreur lors de l\'import Excel: $e');
    }
  }
}

/// Modèle pour les données importées
class CountingSheetImport {
  final String? codeProduit;
  final String nomProduit;
  final double quantiteComptee;
  final String? commentaire;

  CountingSheetImport({
    this.codeProduit,
    required this.nomProduit,
    required this.quantiteComptee,
    this.commentaire,
  });

  @override
  String toString() {
    return 'CountingSheetImport(code: $codeProduit, produit: $nomProduit, qté: $quantiteComptee)';
  }
}
