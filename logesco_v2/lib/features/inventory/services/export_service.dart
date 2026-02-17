import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

/// Service pour gérer les exports de fichiers Excel
/// Utilise exactement la même approche que le module produits (ExcelService)
class ExportService {
  /// Exporte les stocks vers un fichier Excel
  /// Même comportement que ExcelService.exportProductsToExcel()
  static Future<String?> exportStocksToExcel(List<Map<String, dynamic>> stocks) async {
    try {
      // Créer un nouveau fichier Excel
      var excel = Excel.createExcel();
      Sheet sheet = excel['Stocks'];

      // Supprimer la feuille par défaut si elle existe
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Définir les en-têtes
      List<String> headers = [
        'Référence',
        'Nom du produit',
        'Quantité disponible',
        'Quantité réservée',
        'Seuil minimum',
        'Prix unitaire',
        'Prix d\'achat',
        'Valeur stock (vente)',
        'Valeur stock (achat)',
        'Statut',
        'Dernière MAJ',
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

      // Ajouter les données des stocks
      for (int i = 0; i < stocks.length; i++) {
        final stock = stocks[i];
        final rowIndex = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(stock['reference'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(stock['nom'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = IntCellValue(stock['quantiteDisponible'] ?? 0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = IntCellValue(stock['quantiteReservee'] ?? 0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = IntCellValue(stock['seuilMinimum'] ?? 0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = DoubleCellValue((stock['prixUnitaire'] ?? 0).toDouble());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = DoubleCellValue((stock['prixAchat'] ?? 0).toDouble());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = DoubleCellValue((stock['valeurVente'] ?? 0).toDouble());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex)).value = DoubleCellValue((stock['valeurAchat'] ?? 0).toDouble());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex)).value = TextCellValue(stock['statut'] ?? 'Normal');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = TextCellValue(stock['derniereMaj'] ?? '');
      }

      // Ajuster la largeur des colonnes
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'stocks_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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
      return null;
    }
  }

  /// Exporte les mouvements vers un fichier Excel
  static Future<String?> exportMovementsToExcel(List<Map<String, dynamic>> movements) async {
    try {
      // Créer un nouveau fichier Excel
      var excel = Excel.createExcel();
      Sheet sheet = excel['Mouvements'];

      // Supprimer la feuille par défaut si elle existe
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Définir les en-têtes
      List<String> headers = [
        'Date',
        'Référence produit',
        'Nom du produit',
        'Type de mouvement',
        'Changement quantité',
        'Type référence',
        'ID référence',
        'Notes',
      ];

      // Ajouter les en-têtes
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.green200,
        );
      }

      // Ajouter les données des mouvements
      for (int i = 0; i < movements.length; i++) {
        final movement = movements[i];
        final rowIndex = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(movement['date'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(movement['referenceProduit'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(movement['nomProduit'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(movement['typeMouvement'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = IntCellValue(movement['changementQuantite'] ?? 0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = TextCellValue(movement['typeReference'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = TextCellValue(movement['idReference']?.toString() ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = TextCellValue(movement['notes'] ?? '');
      }

      // Ajuster la largeur des colonnes
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'mouvements_stock_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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
      print('❌ Erreur lors de l\'export Excel mouvements: $e');
      return null;
    }
  }

  /// Partage le fichier Excel exporté (même que ExcelService.shareExcelFile())
  static Future<void> shareExcelFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Export Excel - LOGESCO');
    } catch (e) {
      print('❌ Erreur lors du partage: $e');
    }
  }

  /// Parse les données CSV en format pour Excel
  static List<Map<String, dynamic>> _parseCsvToStocks(String csvContent) {
    List<Map<String, dynamic>> stocks = [];
    
    try {
      final lines = csvContent.split('\n');
      if (lines.length < 2) return stocks; // Pas de données
      
      // Ignorer la première ligne (en-têtes)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        // Parser la ligne CSV (format simple)
        final values = line.split(',');
        if (values.length >= 11) {
          stocks.add({
            'reference': _cleanCsvValue(values[0]),
            'nom': _cleanCsvValue(values[1]),
            'quantiteDisponible': int.tryParse(values[2]) ?? 0,
            'quantiteReservee': int.tryParse(values[3]) ?? 0,
            'seuilMinimum': int.tryParse(values[4]) ?? 0,
            'prixUnitaire': double.tryParse(values[5]) ?? 0.0,
            'prixAchat': double.tryParse(values[6]) ?? 0.0,
            'valeurVente': double.tryParse(values[7]) ?? 0.0,
            'valeurAchat': double.tryParse(values[8]) ?? 0.0,
            'statut': _cleanCsvValue(values[9]),
            'derniereMaj': _cleanCsvValue(values[10]),
          });
        }
      }
    } catch (e) {
    }
    
    return stocks;
  }

  /// Parse les données CSV des mouvements en format pour Excel
  static List<Map<String, dynamic>> _parseCsvToMovements(String csvContent) {
    List<Map<String, dynamic>> movements = [];
    
    try {
      final lines = csvContent.split('\n');
      if (lines.length < 2) return movements; // Pas de données
      
      // Ignorer la première ligne (en-têtes)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        // Parser la ligne CSV (format simple)
        final values = line.split(',');
        if (values.length >= 8) {
          movements.add({
            'date': _cleanCsvValue(values[0]),
            'referenceProduit': _cleanCsvValue(values[1]),
            'nomProduit': _cleanCsvValue(values[2]),
            'typeMouvement': _cleanCsvValue(values[3]),
            'changementQuantite': int.tryParse(values[4]) ?? 0,
            'typeReference': _cleanCsvValue(values[5]),
            'idReference': values[6],
            'notes': _cleanCsvValue(values[7]),
          });
        }
      }
    } catch (e) {
    }
    
    return movements;
  }

  /// Nettoie les valeurs CSV (enlève les guillemets)
  static String _cleanCsvValue(String value) {
    return value.replaceAll('"', '').trim();
  }

  /// Exporte les stocks depuis CSV vers Excel (fonction principale)
  static Future<String?> exportStocksFromCsv(String csvContent) async {
    final stocks = _parseCsvToStocks(csvContent);
    return await exportStocksToExcel(stocks);
  }

  /// Exporte les mouvements depuis CSV vers Excel (fonction principale)
  static Future<String?> exportMovementsFromCsv(String csvContent) async {
    final movements = _parseCsvToMovements(csvContent);
    return await exportMovementsToExcel(movements);
  }

  /// Génère un nom de fichier avec timestamp (même format que le module produits)
  static String generateFilename(String prefix) {
    final now = DateTime.now();
    return '${prefix}_${now.millisecondsSinceEpoch}.xlsx';
  }

  /// Obtient le chemin du dossier Documents (même que le module produits)
  static Future<String> getDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
