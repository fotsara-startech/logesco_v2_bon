import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/financial_balance.dart';
import '../../company_settings/models/company_profile.dart';
import '../../company_settings/services/company_settings_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';

/// Service d'export PDF et Excel pour le module comptabilite
class AccountingExportService {
  // ─── Helpers communs ────────────────────────────────────────────────────────

  static Future<CompanyProfile?> _loadCompanyProfile() async {
    try {
      if (Get.isRegistered<AuthService>()) {
        final service = CompanySettingsService(Get.find<AuthService>());
        final response = await service.getCompanyProfile();
        if (response.isSuccess && response.data != null) return response.data;
      }
    } catch (_) {}
    return null;
  }

  static Future<Uint8List?> _loadLogo(String? logoPath) async {
    if (logoPath == null || logoPath.isEmpty) return null;
    try {
      var path = logoPath;
      if (path.contains('\\') || path.contains('/')) {
        path = path.replaceAll('\\', '/').split('/').last;
      }
      final serverUrl = AppConfig.currentBaseUrl.replaceAll('/api/v1', '');
      final response = await http.get(Uri.parse('$serverUrl/uploads/$path')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  static String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  // ─── PDF ────────────────────────────────────────────────────────────────────

  static Future<void> exportToPdf({
    required FinancialBalance balance,
    String? boutiqueName,
  }) async {
    final company = await _loadCompanyProfile();
    final logoBytes = await _loadLogo(company?.logo);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _pdfCompanyHeader(company, logoBytes, boutiqueName),
        build: (pw.Context context) => [
          pw.SizedBox(height: 8),
          // Titre du document
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green800,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'BILAN COMPTABLE & RENTABILITE',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Periode: ${balance.periodFormatted}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Statut: ${balance.statusMessage}',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 16),

          // Résumé financier
          _pdfSectionTitle('RESUME FINANCIER'),
          pw.SizedBox(height: 6),
          _pdfTable([
            ['Indicateur', 'Montant'],
            ["Chiffre d'affaires", balance.totalRevenueFormatted],
            ['Cout des marchandises vendues', balance.totalCostOfGoodsFormatted],
            ['Marge brute', balance.grossProfitFormatted],
            ['Depenses operationnelles', balance.totalExpensesFormatted],
            ['Benefice net', balance.netProfitFormatted],
            ['Marge brute (%)', balance.grossMarginFormatted],
            ['Marge nette (%)', balance.profitMarginFormatted],
          ]),
          pw.SizedBox(height: 16),

          // Statistiques
          _pdfSectionTitle('STATISTIQUES'),
          pw.SizedBox(height: 6),
          _pdfTable([
            ['Indicateur', 'Valeur'],
            ['Nombre de ventes', '${balance.totalSales}'],
            ['Nombre de depenses', '${balance.totalExpenseItems}'],
            ['Vente moyenne', balance.averageSaleAmountFormatted],
            ['Depense moyenne', balance.averageExpenseAmountFormatted],
            ['Benefice moyen/jour', balance.averageDailyProfitFormatted],
          ]),
          pw.SizedBox(height: 16),

          // Depenses par categorie
          if (balance.expensesByCategory.isNotEmpty) ...[
            _pdfSectionTitle('DEPENSES PAR CATEGORIE'),
            pw.SizedBox(height: 6),
            _pdfTable([
              ['Categorie', 'Montant', 'Nb', '%'],
              ...balance.expensesByCategory.map((c) => [
                    c.categoryDisplayName,
                    c.amountFormatted,
                    '${c.count}',
                    c.percentageFormatted,
                  ]),
            ]),
            pw.SizedBox(height: 16),
          ],

          // Evolution quotidienne
          if (balance.dailyBalances.isNotEmpty) ...[
            _pdfSectionTitle('EVOLUTION QUOTIDIENNE'),
            pw.SizedBox(height: 6),
            _pdfTable([
              ['Date', 'Revenus', 'Depenses', 'Benefice', 'Ventes', 'Dep.'],
              ...balance.dailyBalances.map((d) => [
                    d.dateFormatted,
                    d.revenueFormatted,
                    d.expensesFormatted,
                    d.profitFormatted,
                    '${d.salesCount}',
                    '${d.expensesCount}',
                  ]),
            ]),
          ],
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Genere le ${_fmt(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final period = balance.periodFormatted.replaceAll('/', '-').replaceAll(' ', '_');
    final filePath = '${dir.path}/Bilan_Comptable_$period.pdf';
    final bytes = await pdf.save();
    await File(filePath).writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }

  static pw.Widget _pdfCompanyHeader(CompanyProfile? company, Uint8List? logoBytes, String? boutiqueName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green800, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo
          if (logoBytes != null) ...[
            pw.Container(
              width: 55,
              height: 55,
              margin: const pw.EdgeInsets.only(right: 12),
              child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
            ),
          ],
          // Infos entreprise
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  company?.name ?? 'ENTREPRISE',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                if (company?.slogan != null && company!.slogan!.isNotEmpty)
                  pw.Text(
                    company.slogan!,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                  ),
                if (company?.address != null && company!.address.isNotEmpty) pw.Text(company.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (company?.location != null && company!.location!.isNotEmpty) pw.Text(company.location!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
          ),
          // Contacts
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (company?.phone != null && company!.phone!.isNotEmpty) pw.Text('Tel: ${company.phone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              if (company?.email != null && company!.email!.isNotEmpty) pw.Text(company.email!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              if (company?.nuiRccm != null && company!.nuiRccm!.isNotEmpty) pw.Text('NUI/RCCM: ${company.nuiRccm}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              if (boutiqueName != null) pw.Text('Boutique: $boutiqueName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _pdfTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: rows.asMap().entries.map((entry) {
        final isHeader = entry.key == 0;
        return pw.TableRow(
          decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.grey300) : null,
          children: entry.value
              .map((cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: pw.Text(
                      cell,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: isHeader ? pw.FontWeight.bold : null,
                      ),
                    ),
                  ))
              .toList(),
        );
      }).toList(),
    );
  }

  // ─── Excel ──────────────────────────────────────────────────────────────────

  static Future<String?> exportToExcel({
    required FinancialBalance balance,
    String? boutiqueName,
  }) async {
    final company = await _loadCompanyProfile();
    final excel = Excel.createExcel();
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

    _buildSummarySheet(excel, balance, company, boutiqueName);
    _buildDailySheet(excel, balance);
    _buildCategorySheet(excel, balance);

    final dir = await getApplicationDocumentsDirectory();
    final period = balance.periodFormatted.replaceAll('/', '-').replaceAll(' ', '_');
    final filePath = '${dir.path}/Bilan_Comptable_$period.xlsx';
    final bytes = excel.encode();
    if (bytes == null) return null;

    await File(filePath).writeAsBytes(bytes);
    await OpenFile.open(filePath);
    return filePath;
  }

  static void _buildSummarySheet(
    Excel excel,
    FinancialBalance balance,
    CompanyProfile? company,
    String? boutiqueName,
  ) {
    final sheet = excel['Bilan'];
    int row = 0;

    // En-tete entreprise
    _excelBigHeader(sheet, row, 0, company?.name ?? 'ENTREPRISE', span: 2);
    row++;
    if (company?.slogan != null && company!.slogan!.isNotEmpty) {
      _excelCell(sheet, row, 0, company.slogan!);
      row++;
    }
    if (company?.address != null && company!.address.isNotEmpty) {
      _excelCell(sheet, row, 0, company.address);
      row++;
    }
    if (company?.phone != null && company!.phone!.isNotEmpty) {
      _excelCell(sheet, row, 0, 'Tel: ${company.phone}');
      row++;
    }
    if (company?.email != null && company!.email!.isNotEmpty) {
      _excelCell(sheet, row, 0, 'Email: ${company.email}');
      row++;
    }
    if (company?.nuiRccm != null && company!.nuiRccm!.isNotEmpty) {
      _excelCell(sheet, row, 0, 'NUI/RCCM: ${company.nuiRccm}');
      row++;
    }
    if (boutiqueName != null) {
      _excelCell(sheet, row, 0, 'Boutique: $boutiqueName');
      row++;
    }
    row++; // ligne vide

    // Titre document
    _excelBigHeader(sheet, row, 0, 'BILAN COMPTABLE & RENTABILITE', span: 2);
    row++;
    _excelCell(sheet, row, 0, 'Periode: ${balance.periodFormatted}');
    row++;
    _excelCell(sheet, row, 0, 'Statut: ${balance.statusMessage}');
    row++;
    _excelCell(sheet, row, 0, 'Genere le: ${_fmt(DateTime.now())}');
    row += 2;

    // Colonnes
    _excelHeader(sheet, row, 0, 'Indicateur');
    _excelHeader(sheet, row, 1, 'Valeur');
    row++;

    final dataRows = [
      ["Chiffre d'affaires", balance.totalRevenueFormatted],
      ['Cout des marchandises vendues', balance.totalCostOfGoodsFormatted],
      ['Marge brute', balance.grossProfitFormatted],
      ['Depenses operationnelles', balance.totalExpensesFormatted],
      ['Benefice net', balance.netProfitFormatted],
      ['Marge brute (%)', balance.grossMarginFormatted],
      ['Marge nette (%)', balance.profitMarginFormatted],
      ['Nombre de ventes', '${balance.totalSales}'],
      ['Nombre de depenses', '${balance.totalExpenseItems}'],
      ['Vente moyenne', balance.averageSaleAmountFormatted],
      ['Depense moyenne', balance.averageExpenseAmountFormatted],
      ['Benefice moyen/jour', balance.averageDailyProfitFormatted],
    ];

    for (final r in dataRows) {
      _excelCell(sheet, row, 0, r[0]);
      _excelCell(sheet, row, 1, r[1]);
      row++;
    }
  }

  static void _buildDailySheet(Excel excel, FinancialBalance balance) {
    if (balance.dailyBalances.isEmpty) return;
    final sheet = excel['Evolution quotidienne'];
    int row = 0;

    for (final h in ['Date', 'Revenus', 'Depenses', 'Benefice', 'Nb ventes', 'Nb depenses']) {
      _excelHeader(sheet, row, ['Date', 'Revenus', 'Depenses', 'Benefice', 'Nb ventes', 'Nb depenses'].indexOf(h), h);
    }
    row++;

    for (final d in balance.dailyBalances) {
      _excelCell(sheet, row, 0, '${d.date.day}/${d.date.month}/${d.date.year}');
      _excelCell(sheet, row, 1, d.revenueFormatted);
      _excelCell(sheet, row, 2, d.expensesFormatted);
      _excelCell(sheet, row, 3, d.profitFormatted);
      _excelCell(sheet, row, 4, '${d.salesCount}');
      _excelCell(sheet, row, 5, '${d.expensesCount}');
      row++;
    }
  }

  static void _buildCategorySheet(Excel excel, FinancialBalance balance) {
    if (balance.expensesByCategory.isEmpty) return;
    final sheet = excel['Depenses par categorie'];
    int row = 0;

    _excelHeader(sheet, row, 0, 'Categorie');
    _excelHeader(sheet, row, 1, 'Montant');
    _excelHeader(sheet, row, 2, 'Nb mouvements');
    _excelHeader(sheet, row, 3, 'Pourcentage');
    row++;

    for (final c in balance.expensesByCategory) {
      _excelCell(sheet, row, 0, c.categoryDisplayName);
      _excelCell(sheet, row, 1, c.amountFormatted);
      _excelCell(sheet, row, 2, '${c.count}');
      _excelCell(sheet, row, 3, c.percentageFormatted);
      row++;
    }
  }

  static void _excelBigHeader(Sheet sheet, int row, int col, String value, {int span = 1}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      backgroundColorHex: ExcelColor.green200,
    );
  }

  static void _excelHeader(Sheet sheet, int row, int col, String value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.blue200,
    );
  }

  static void _excelCell(Sheet sheet, int row, int col, String value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = TextCellValue(value);
  }
}
