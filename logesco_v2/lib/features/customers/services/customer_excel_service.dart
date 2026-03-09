import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer.dart';

/// Service pour l'import/export Excel des clients
class CustomerExcelService {
  /// Exporte la liste des clients vers un fichier Excel
  Future<String?> exportCustomersToExcel(List<Customer> customers) async {
    try {
      // Créer un nouveau fichier Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Clients'];

      // Définir les en-têtes
      List<String> headers = [
        'Nom',
        'Prénom',
        'Téléphone',
        'Email',
        'Adresse',
        'Solde',
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
      for (int i = 0; i < customers.length; i++) {
        final customer = customers[i];

        var cell0 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1));
        cell0.value = TextCellValue(customer.nom);

        var cell1 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1));
        cell1.value = TextCellValue(customer.prenom ?? '');

        var cell2 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1));
        cell2.value = TextCellValue(customer.telephone ?? '');

        var cell3 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1));
        cell3.value = TextCellValue(customer.email ?? '');

        var cell4 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1));
        cell4.value = TextCellValue(customer.adresse ?? '');

        var cell5 = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1));
        cell5.value = DoubleCellValue(customer.solde);
      }

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/clients_$timestamp.xlsx';

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

  /// Importe des clients depuis un fichier Excel
  Future<List<CustomerImportData>?> importCustomersFromExcel() async {
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

  /// Parse les données Excel et retourne une liste de clients
  Future<List<CustomerImportData>> _parseExcelBytes(Uint8List bytes) async {
    List<CustomerImportData> customers = [];

    try {
      print('📊 Début du parsing Excel...');
      var excel = Excel.decodeBytes(bytes);
      print('✅ Excel décodé, ${excel.tables.length} feuille(s) trouvée(s)');

      // Prendre la première feuille
      if (excel.tables.isEmpty) {
        print('❌ Aucune feuille trouvée dans le fichier Excel');
        return customers;
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
        String? prenom = row.length > 1 ? row[1]?.value?.toString() : null;
        String? telephone = row.length > 2 ? row[2]?.value?.toString() : null;
        String? email = row.length > 3 ? row[3]?.value?.toString() : null;
        String? adresse = row.length > 4 ? row[4]?.value?.toString() : null;

        double solde = 0.0;
        if (row.length > 5 && row[5]?.value != null) {
          try {
            solde = double.parse(row[5]!.value.toString());
          } catch (e) {
            print('⚠️  Ligne $rowIndex: Erreur parsing solde, utilisation de 0.0');
            solde = 0.0;
          }
        }

        // Le nom est obligatoire
        if (nom == null || nom.isEmpty) {
          skippedCount++;
          print('⚠️  Ligne $rowIndex ignorée (nom vide)');
          continue;
        }

        print('✅ Ligne $rowIndex: $nom ${prenom ?? ''} - $telephone');

        customers.add(CustomerImportData(
          nom: nom,
          prenom: prenom,
          telephone: telephone,
          email: email,
          adresse: adresse,
          solde: solde,
        ));
        parsedCount++;
      }

      print('✅ ${customers.length} clients parsés depuis Excel');
      print('📊 Statistiques: $parsedCount parsés, $skippedCount ignorés');
      return customers;
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
        'Prénom',
        'Téléphone',
        'Email',
        'Adresse',
        'Solde',
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
        'Dupont',
        'Jean',
        '+237 6 XX XX XX XX',
        'jean.dupont@exemple.com',
        '123 Rue Exemple, Douala',
        '0',
      ];

      for (int i = 0; i < example.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        cell.value = TextCellValue(example[i]);
      }

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/template_clients.xlsx';

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

/// Données d'import d'un client
class CustomerImportData {
  final String nom;
  final String? prenom;
  final String? telephone;
  final String? email;
  final String? adresse;
  final double solde;

  CustomerImportData({
    required this.nom,
    this.prenom,
    this.telephone,
    this.email,
    this.adresse,
    this.solde = 0.0,
  });
}
