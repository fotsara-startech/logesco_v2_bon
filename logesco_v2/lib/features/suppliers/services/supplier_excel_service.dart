import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/supplier.dart';

/// Service pour l'import/export Excel des fournisseurs
class SupplierExcelService {
  /// Exporte la liste des fournisseurs vers un fichier Excel
  Future<String?> exportSuppliersToExcel(List<Supplier> suppliers) async {
    try {
      // Créer un nouveau fichier Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Fournisseurs'];

      // Définir les en-têtes
      List<String> headers = [
        'Nom',
        'Personne Contact',
        'Téléphone',
        'Email',
        'Adresse',
      ];

      // Ajouter les en-têtes
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Ajouter les données
      for (int i = 0; i < suppliers.length; i++) {
        final supplier = suppliers[i];
        List<String?> row = [
          supplier.nom,
          supplier.personneContact,
          supplier.telephone,
          supplier.email,
          supplier.adresse,
        ];

        for (int j = 0; j < row.length; j++) {
          var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = TextCellValue(row[j] ?? '');
        }
      }

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/fournisseurs_$timestamp.xlsx';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      print('✅ Export Excel réussi: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Erreur lors de l\'export Excel: $e');
      return null;
    }
  }

  /// Importe des fournisseurs depuis un fichier Excel
  Future<List<SupplierImportData>?> importSuppliersFromExcel() async {
    try {
      // Sélectionner le fichier Excel
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) {
        print('❌ Aucun fichier sélectionné');
        return null;
      }

      print('✅ Fichier sélectionné: ${result.files.single.name}');

      // Sur desktop (Windows/Linux/Mac), utiliser le path au lieu de bytes
      Uint8List? bytes;

      if (result.files.single.bytes != null) {
        // Web: utiliser bytes directement
        bytes = result.files.single.bytes!;
        print('✅ Bytes du fichier (Web): ${bytes.length} octets');
      } else if (result.files.single.path != null) {
        // Desktop: lire le fichier depuis le path
        final file = File(result.files.single.path!);
        bytes = await file.readAsBytes();
        print('✅ Bytes du fichier (Desktop): ${bytes.length} octets');
      } else {
        print('❌ Impossible de lire le fichier (ni bytes ni path disponible)');
        return null;
      }

      return await _parseExcelBytes(bytes);
    } catch (e) {
      print('❌ Erreur lors de l\'import Excel: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Parse les données Excel et retourne une liste de fournisseurs
  Future<List<SupplierImportData>> _parseExcelBytes(Uint8List bytes) async {
    List<SupplierImportData> suppliers = [];

    try {
      print('📊 Début du parsing Excel...');
      var excel = Excel.decodeBytes(bytes);
      print('✅ Excel décodé, ${excel.tables.length} feuille(s) trouvée(s)');

      // Prendre la première feuille
      if (excel.tables.isEmpty) {
        print('❌ Aucune feuille trouvée dans le fichier Excel');
        return suppliers;
      }

      var table = excel.tables.keys.first;
      var sheet = excel.tables[table]!;
      print('📄 Feuille sélectionnée: $table');
      print('📊 Nombre de lignes: ${sheet.maxRows}');
      print('📊 Nombre de colonnes: ${sheet.maxColumns}');

      // Afficher les en-têtes (première ligne)
      if (sheet.maxRows > 0) {
        var headerRow = sheet.rows[0];
        print('📋 En-têtes: ${headerRow.map((cell) => cell?.value?.toString() ?? 'null').join(' | ')}');
      }

      // Ignorer la première ligne (en-têtes)
      int parsedCount = 0;
      int skippedCount = 0;

      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        var row = sheet.rows[rowIndex];

        // Vérifier que la ligne n'est pas vide
        if (row.isEmpty || row[0]?.value == null) {
          skippedCount++;
          print('⚠️  Ligne $rowIndex ignorée (vide)');
          continue;
        }

        String? nom = row.length > 0 ? row[0]?.value?.toString() : null;
        String? contact = row.length > 1 ? row[1]?.value?.toString() : null;
        String? telephone = row.length > 2 ? row[2]?.value?.toString() : null;
        String? email = row.length > 3 ? row[3]?.value?.toString() : null;
        String? adresse = row.length > 4 ? row[4]?.value?.toString() : null;

        // Le nom est obligatoire
        if (nom == null || nom.isEmpty) {
          skippedCount++;
          print('⚠️  Ligne $rowIndex ignorée (nom vide)');
          continue;
        }

        print('✅ Ligne $rowIndex: $nom - ${contact ?? 'Pas de contact'} - $telephone');

        suppliers.add(SupplierImportData(
          nom: nom,
          contact: contact,
          telephone: telephone,
          email: email,
          adresse: adresse,
        ));
        parsedCount++;
      }

      print('✅ ${suppliers.length} fournisseurs parsés depuis Excel');
      print('📊 Statistiques: $parsedCount parsés, $skippedCount ignorés');
      return suppliers;
    } catch (e) {
      print('❌ Erreur lors du parsing Excel: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Génère un template Excel pour l'import
  Future<String?> generateImportTemplate() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Template'];

      // Définir les en-têtes
      List<String> headers = [
        'Nom',
        'Personne Contact',
        'Téléphone',
        'Email',
        'Adresse',
      ];

      // Ajouter les en-têtes
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Ajouter une ligne d'exemple
      List<String> example = [
        'Fournisseur Exemple',
        'Jean Dupont',
        '+237 6 XX XX XX XX',
        'contact@exemple.com',
        '123 Rue Exemple, Douala, Cameroun',
      ];

      for (int i = 0; i < example.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        cell.value = TextCellValue(example[i]);
      }

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/template_fournisseurs.xlsx';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      print('✅ Template généré: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Erreur lors de la génération du template: $e');
      return null;
    }
  }
}

/// Données d'import d'un fournisseur
class SupplierImportData {
  final String nom;
  final String? contact;
  final String? telephone;
  final String? email;
  final String? adresse;

  SupplierImportData({
    required this.nom,
    this.contact,
    this.telephone,
    this.email,
    this.adresse,
  });
}
