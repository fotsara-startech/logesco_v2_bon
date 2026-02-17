import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/activity_report.dart';

/// Service pour exporter les bilans comptables en PDF
class PdfExportService {
  /// Style de texte par défaut pour éviter les problèmes de police
  static pw.TextStyle get _defaultTextStyle => const pw.TextStyle(
        fontSize: 12,
      );

  /// Style de texte pour les en-têtes
  static pw.TextStyle get _headerTextStyle => pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
      );

  /// Génère un PDF du bilan comptable
  Future<File> generateActivityReportPdf(ActivityReport report) async {
    final pdf = pw.Document();

    // Configuration par défaut pour éviter les problèmes de police
    pw.Document.debug = false;

    // Page 1: Résumé exécutif
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(report),
          pw.SizedBox(height: 20),
          _buildExecutiveSummary(report),
          pw.SizedBox(height: 20),
          _buildKeyMetrics(report),
        ],
      ),
    );

    // Page 2: Analyse des ventes
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildSectionHeader('Analyse des Ventes'),
          pw.SizedBox(height: 15),
          _buildSalesAnalysis(report.salesData),
        ],
      ),
    );

    // Page 3: Mouvements financiers et bénéfices
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildSectionHeader('Mouvements Financiers'),
          pw.SizedBox(height: 15),
          _buildFinancialMovements(report.financialMovements),
          pw.SizedBox(height: 20),
          _buildSectionHeader('Analyse des Bénéfices'),
          pw.SizedBox(height: 15),
          _buildProfitAnalysis(report.profitData),
        ],
      ),
    );

    // Page 4: Dettes clients et recommandations
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildSectionHeader('Dettes Clients'),
          pw.SizedBox(height: 15),
          _buildCustomerDebts(report.customerDebts),
          pw.SizedBox(height: 20),
          _buildSectionHeader('Recommandations'),
          pw.SizedBox(height: 15),
          _buildRecommendations(report.summary.recommendations),
        ],
      ),
    );

    // Sauvegarder le PDF
    final output = await getApplicationDocumentsDirectory();
    final fileName = 'bilan_comptable_${_formatDateForFile(report.startDate)}_${_formatDateForFile(report.endDate)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// En-tête du document
  pw.Widget _buildHeader(ActivityReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Informations principales
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILAN COMPTABLE D\'ACTIVITES',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  report.companyInfo.name,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Periode: ${report.reportPeriod}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Genere le: ${DateFormat('dd/MM/yyyy a HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          // Informations de l'entreprise
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INFORMATIONS ENTREPRISE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  // Informations complètes de l'entreprise depuis la base de données
                  if (report.companyInfo.address.isNotEmpty && report.companyInfo.address != 'Adresse non configurée') ...[
                    pw.Text(
                      'Adresse: ${report.companyInfo.address}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                  if (report.companyInfo.location.isNotEmpty && report.companyInfo.location != 'Cameroun, CMR') ...[
                    pw.Text(
                      'Localisation: ${report.companyInfo.location}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                  if (report.companyInfo.phone.isNotEmpty && report.companyInfo.phone != 'Téléphone non configuré') ...[
                    pw.Text(
                      'Tel: ${report.companyInfo.phone}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                  if (report.companyInfo.email.isNotEmpty && report.companyInfo.email != 'email@logesco.com') ...[
                    pw.Text(
                      'Email: ${report.companyInfo.email}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                  if (report.companyInfo.nuiRccm.isNotEmpty && report.companyInfo.nuiRccm != 'NUI RCCM non configuré') ...[
                    pw.Text(
                      'NUI RCCM: ${report.companyInfo.nuiRccm}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 4),
                  ],
                  // Informations système
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Systeme: LOGESCO v2',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'Devise: FCFA',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Résumé exécutif
  pw.Widget _buildExecutiveSummary(ActivityReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUME EXECUTIF',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: _getColorFromHex(report.summary.statusColor),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Statut: ${report.summary.overallStatus}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(report.summary.statusMessage),
          pw.SizedBox(height: 15),
          pw.Text(
            'Points cles:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('- Chiffre d\'affaires: ${report.salesData.totalRevenueFormatted}'),
          pw.Text('- Benefice net: ${report.profitData.netProfitFormatted}'),
          pw.Text('- Marge de profit: ${report.profitData.profitMarginFormatted}'),
          pw.Text('- Dettes clients: ${report.customerDebts.totalOutstandingDebtFormatted}'),
        ],
      ),
    );
  }

  /// Métriques clés
  pw.Widget _buildKeyMetrics(ActivityReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INDICATEURS CLES',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // En-tête
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Indicateur', isHeader: true),
                _buildTableCell('Valeur', isHeader: true),
                _buildTableCell('Tendance', isHeader: true),
              ],
            ),
            // Données
            ...report.summary.keyMetrics.map((metric) => pw.TableRow(
                  children: [
                    _buildTableCell(metric.name),
                    _buildTableCell('${metric.value} ${metric.unit}'),
                    _buildTableCell(metric.trend == 'up' ? 'Hausse' : 'Baisse'),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  /// Analyse des ventes
  pw.Widget _buildSalesAnalysis(SalesData salesData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Résumé des ventes
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBox('Nombre de ventes', salesData.totalSales.toString()),
              _buildMetricBox('Chiffre d\'affaires', salesData.totalRevenueFormatted),
              _buildMetricBox('Vente moyenne', salesData.averageSaleAmountFormatted),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Ventes par catégorie
        if (salesData.salesByCategory.isNotEmpty) ...[
          pw.Text(
            'Ventes par categorie',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Catégorie', isHeader: true),
                  _buildTableCell('Montant', isHeader: true),
                  _buildTableCell('Pourcentage', isHeader: true),
                ],
              ),
              ...salesData.salesByCategory.take(5).map((category) => pw.TableRow(
                    children: [
                      _buildTableCell(category.categoryName),
                      _buildTableCell(category.amountFormatted),
                      _buildTableCell(category.percentageFormatted),
                    ],
                  )),
            ],
          ),
          pw.SizedBox(height: 20),
        ],

        // Top produits
        if (salesData.topProducts.isNotEmpty) ...[
          pw.Text(
            'Produits les plus vendus',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Produit', isHeader: true),
                  _buildTableCell('Quantite', isHeader: true),
                  _buildTableCell('Chiffre d\'affaires', isHeader: true),
                ],
              ),
              ...salesData.topProducts.take(5).map((product) => pw.TableRow(
                    children: [
                      _buildTableCell(product.productName),
                      _buildTableCell(product.quantitySold.toString()),
                      _buildTableCell(product.revenueFormatted),
                    ],
                  )),
            ],
          ),
        ],
      ],
    );
  }

  /// Mouvements financiers
  pw.Widget _buildFinancialMovements(FinancialMovementsData financialData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBox('Entrées', financialData.totalIncomeFormatted),
              _buildMetricBox('Sorties', financialData.totalExpensesFormatted),
              _buildMetricBox('Flux net', financialData.netCashFlowFormatted),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        if (financialData.movementsByCategory.isNotEmpty) ...[
          pw.Text(
            'Mouvements par categorie',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Catégorie', isHeader: true),
                  _buildTableCell('Type', isHeader: true),
                  _buildTableCell('Montant', isHeader: true),
                ],
              ),
              ...financialData.movementsByCategory.take(5).map((movement) => pw.TableRow(
                    children: [
                      _buildTableCell(movement.categoryName),
                      _buildTableCell(movement.typeLabel),
                      _buildTableCell(movement.amountFormatted),
                    ],
                  )),
            ],
          ),
        ],
      ],
    );
  }

  /// Analyse des bénéfices
  pw.Widget _buildProfitAnalysis(ProfitData profitData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: profitData.isProfitable ? PdfColors.green50 : PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricBox('Marge brute', profitData.grossProfitFormatted),
                  _buildMetricBox('Benefice net', profitData.netProfitFormatted),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricBox('Cout marchandises', profitData.costOfGoodsSoldFormatted),
                  _buildMetricBox('Marge (%)', profitData.profitMarginFormatted),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),

        // Tendance
        pw.Text(
          'Evolution',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text('Periode precedente: ${profitData.profitTrend.previousPeriodProfitFormatted}'),
        pw.Text('Croissance: ${profitData.profitTrend.growthRateFormatted}'),
        pw.Text('Tendance: ${profitData.profitTrend.isIncreasing ? 'Positive' : 'Negative'}'),
      ],
    );
  }

  /// Dettes clients
  pw.Widget _buildCustomerDebts(CustomerDebtsData debtsData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBox('Total dettes', debtsData.totalOutstandingDebtFormatted),
              _buildMetricBox('Clients debiteurs', debtsData.customersWithDebt.toString()),
              _buildMetricBox('Dette moyenne', debtsData.averageDebtPerCustomerFormatted),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        if (debtsData.topDebtors.isNotEmpty) ...[
          pw.Text(
            'Principaux debiteurs',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Client', isHeader: true),
                  _buildTableCell('Montant du', isHeader: true),
                  _buildTableCell('Jours de retard', isHeader: true),
                ],
              ),
              ...debtsData.topDebtors.take(5).map((debt) => pw.TableRow(
                    children: [
                      _buildTableCell(debt.customerName),
                      _buildTableCell(debt.debtAmountFormatted),
                      _buildTableCell(debt.daysOverdue.toString()),
                    ],
                  )),
            ],
          ),
        ],
      ],
    );
  }

  /// Recommandations
  pw.Widget _buildRecommendations(List<String> recommendations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.yellow50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.yellow200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Actions recommandees:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.yellow800,
                ),
              ),
              pw.SizedBox(height: 10),
              ...recommendations.map((recommendation) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('- ', style: pw.TextStyle(color: PdfColors.yellow800)),
                        pw.Expanded(child: pw.Text(recommendation)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // Widgets utilitaires

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildMetricBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Utilitaires

  PdfColor _getColorFromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    final r = int.parse(hex.substring(0, 2), radix: 16) / 255;
    final g = int.parse(hex.substring(2, 4), radix: 16) / 255;
    final b = int.parse(hex.substring(4, 6), radix: 16) / 255;
    return PdfColor(r, g, b);
  }

  String _formatDateForFile(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
