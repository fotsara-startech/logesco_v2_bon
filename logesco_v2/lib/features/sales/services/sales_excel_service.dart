import 'package:get/get.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../models/sale.dart';
import '../../../core/utils/file_download_helper.dart';

/// Service d'export Excel des ventes (même approche que CustomerExcelService
/// et ExportService : un fichier simple, pas de mise en forme avancée).
class SalesExcelService {
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Exporte une liste de ventes vers un fichier Excel (.xlsx).
  /// Retourne le chemin du fichier généré, ou null en cas d'échec.
  Future<String?> exportSalesToExcel(List<Sale> sales) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Ventes'];
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final headers = [
        'N° Vente',
        'suppliers_transaction_date'.tr,
        'sales_customer'.tr,
        'Vendeur',
        'suppliers_payment_method'.tr,
        'Statut',
        'Sous-total',
        'Remise',
        'TVA',
        'sales_total_amount'.tr,
        'sales_amount_paid'.tr,
        'printing_montant_restant'.tr,
        'sales_advance_used_label'.tr,
        'accounting_profit'.tr,
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      for (int i = 0; i < sales.length; i++) {
        final sale = sales[i];
        final row = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(sale.numeroVente);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(_dateFormat.format(sale.dateCreation));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
            TextCellValue(sale.client != null ? '${sale.client!.nom} ${sale.client!.prenom ?? ''}'.trim() : 'sales_walk_in'.tr);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(sale.vendeur?.nomUtilisateur ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(sale.modePaiement);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(sale.statut);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(sale.sousTotal);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(sale.montantRemise);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = DoubleCellValue(sale.montantTva);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value = DoubleCellValue(sale.montantTotal);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value = DoubleCellValue(sale.montantPaye);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value = DoubleCellValue(sale.montantRestant);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value = DoubleCellValue(sale.avanceUtilisee);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row)).value = DoubleCellValue(sale.benefice);
      }

      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 18);
      }

      final fileName = 'ventes_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final bytes = excel.encode();
      if (bytes == null) return null;

      final filePath = await FileDownloadHelper.saveFile(
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      // Ouvrir automatiquement le fichier généré (desktop/mobile seulement :
      // sur web, FileDownloadHelper déclenche déjà le téléchargement navigateur).
      if (!kIsWeb) {
        try {
          await OpenFile.open(filePath);
        } catch (e) {
          print('⚠️ Fichier Excel créé mais impossible de l\'ouvrir automatiquement: $e');
        }
      }

      return filePath;
    } catch (e) {
      print('❌ Erreur lors de l\'export Excel des ventes: $e');
      return null;
    }
  }
}
