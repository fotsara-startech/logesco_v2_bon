import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/activity_report.dart';
import '../../../core/config/api_config.dart';

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

    // Charger le logo depuis le backend
    Uint8List? logoBytes;
    if (report.companyInfo.logoPath.isNotEmpty) {
      try {
        var logoPath = report.companyInfo.logoPath;
        // Extraire juste le nom du fichier si c'est un chemin complet
        if (logoPath.contains('\\') || logoPath.contains('/')) {
          logoPath = logoPath.replaceAll('\\', '/').split('/').last;
        }
        final serverUrl = ApiConfig.currentBaseUrl.replaceAll('/api/v1', '');
        final logoUrl = '$serverUrl/uploads/$logoPath';
        final response = await http.get(Uri.parse(logoUrl)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          logoBytes = response.bodyBytes;
        }
      } catch (e) {
        print('⚠️ Logo non chargé pour le PDF: $e');
      }
    }

    // Page 1: Résumé exécutif
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(report, logoBytes),
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
          _buildSectionHeader('reports_pdf_sales_analysis'.tr),
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
          _buildSectionHeader('reports_pdf_financial_movements'.tr),
          pw.SizedBox(height: 15),
          _buildFinancialMovements(report.financialMovements),
          pw.SizedBox(height: 20),
          _buildSectionHeader('reports_pdf_profit_analysis'.tr),
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
          _buildSectionHeader('reports_pdf_customer_debts'.tr),
          pw.SizedBox(height: 15),
          _buildCustomerDebts(report.customerDebts),
          pw.SizedBox(height: 20),
          _buildSectionHeader('reports_recommendations_title'.tr),
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
  pw.Widget _buildHeader(ActivityReport report, Uint8List? logoBytes) {
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
                // Logo + titre sur la même ligne
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoBytes != null)
                      pw.Container(
                        width: 50,
                        height: 50,
                        margin: const pw.EdgeInsets.only(right: 12),
                        child: pw.Image(
                          pw.MemoryImage(logoBytes),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    pw.Expanded(
                      child: pw.Text(
                        'reports_pdf_title'.tr,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ),
                  ],
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
                  '${'reports_pdf_period'.tr}: ${report.reportPeriod}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '${'reports_pdf_generated_on'.tr}: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
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
                    'reports_pdf_company_info'.tr,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (report.companyInfo.address.isNotEmpty && report.companyInfo.address != 'Adresse non configurée') ...[
                    pw.Text(
                      '${'reports_pdf_address'.tr}: ${report.companyInfo.address}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                  if (report.companyInfo.location.isNotEmpty && report.companyInfo.location != 'Cameroun, CMR') ...[
                    pw.Text(
                      '${'reports_pdf_location'.tr}: ${report.companyInfo.location}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                  if (report.companyInfo.phone.isNotEmpty && report.companyInfo.phone != 'Téléphone non configuré') ...[
                    pw.Text(
                      '${'reports_pdf_phone'.tr}: ${report.companyInfo.phone}',
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
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${'reports_pdf_system'.tr}: LOGESCO v2',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '${'reports_pdf_currency'.tr}: FCFA',
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
            'reports_pdf_executive_summary'.tr,
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
                '${'reports_pdf_status'.tr}: ${report.summary.overallStatus}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(report.summary.statusMessage),
          pw.SizedBox(height: 15),
          pw.Text(
            'reports_pdf_key_points'.tr,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('- ${'reports_pdf_revenue'.tr}: ${report.salesData.totalRevenueFormatted}'),
          pw.Text('- ${'reports_pdf_net_profit'.tr}: ${report.profitData.netProfitFormatted}'),
          pw.Text('- ${'reports_pdf_profit_margin'.tr}: ${report.profitData.profitMarginFormatted}'),
          pw.Text('- ${'reports_pdf_customer_debts_label'.tr}: ${report.customerDebts.totalOutstandingDebtFormatted}'),
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
          'reports_pdf_key_indicators'.tr,
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
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('reports_pdf_indicator'.tr, isHeader: true),
                _buildTableCell('reports_pdf_value'.tr, isHeader: true),
                _buildTableCell('reports_pdf_trend'.tr, isHeader: true),
              ],
            ),
            ...report.summary.keyMetrics.map((metric) => pw.TableRow(
                  children: [
                    _buildTableCell(metric.name),
                    _buildTableCell('${metric.value} ${metric.unit}'),
                    _buildTableCell(metric.trend == 'up' ? 'reports_pdf_trend_up'.tr : 'reports_pdf_trend_down'.tr),
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
              _buildMetricBox('reports_pdf_sales_count'.tr, salesData.totalSales.toString()),
              _buildMetricBox('reports_pdf_revenue'.tr, salesData.totalRevenueFormatted),
              _buildMetricBox('reports_pdf_avg_sale'.tr, salesData.averageSaleAmountFormatted),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Ventes par catégorie
        if (salesData.salesByCategory.isNotEmpty) ...[
          pw.Text(
            'reports_pdf_sales_by_category'.tr,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('reports_pdf_category'.tr, isHeader: true),
                  _buildTableCell('reports_pdf_amount'.tr, isHeader: true),
                  _buildTableCell('reports_pdf_percentage'.tr, isHeader: true),
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
            'reports_pdf_top_products'.tr,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('reports_pdf_product'.tr, isHeader: true),
                  _buildTableCell('reports_pdf_quantity'.tr, isHeader: true),
                  _buildTableCell('reports_pdf_revenue'.tr, isHeader: true),
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
              _buildMetricBox('reports_pdf_income'.tr, financialData.totalIncomeFormatted),
              _buildMetricBox('reports_pdf_expenses'.tr, financialData.totalExpensesFormatted),
              _buildMetricBox('reports_pdf_net_flow'.tr, financialData.netCashFlowFormatted),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        if (financialData.movementsByCategory.isNotEmpty) ...[
          pw.Text(
            'reports_pdf_movements_by_category'.tr,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('reports_pdf_category'.tr, isHeader: true),
                  _buildTableCell('reports_pdf_type'.tr, isHeader: true),
                  _buildTableCell('reports_pdf_amount'.tr, isHeader: true),
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
                  _buildMetricBox('reports_pdf_gross_profit'.tr, profitData.grossProfitFormatted),
                  _buildMetricBox('reports_pdf_net_profit'.tr, profitData.netProfitFormatted),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricBox('reports_pdf_cogs'.tr, profitData.costOfGoodsSoldFormatted),
                  _buildMetricBox('reports_pdf_profit_margin'.tr, profitData.profitMarginFormatted),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),

        // Tendance
        pw.Text(
          'reports_pdf_evolution'.tr,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text('${'reports_pdf_previous_period'.tr}: ${profitData.profitTrend.previousPeriodProfitFormatted}'),
        pw.Text('${'reports_pdf_growth'.tr}: ${profitData.profitTrend.growthRateFormatted}'),
        pw.Text('${'reports_pdf_trend'.tr}: ${profitData.profitTrend.isIncreasing ? 'reports_pdf_trend_positive'.tr : 'reports_pdf_trend_negative'.tr}'),
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
              _buildMetricBox('reports_pdf_total_debts'.tr, debtsData.totalOutstandingDebtFormatted),
              _buildMetricBox('reports_pdf_debtors'.tr, debtsData.customersWithDebt.toString()),
              _buildMetricBox('reports_pdf_avg_debt'.tr, debtsData.averageDebtPerCustomerFormatted),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        if (debtsData.topDebtors.isNotEmpty) ...[
          pw.Text(
            'reports_pdf_top_debtors'.tr,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('reports_pdf_customer'.tr, isHeader: true),
                  _buildTableCell('reports_pdf_debt_amount'.tr, isHeader: true),
                  _buildTableCell('reports_pdf_days_overdue'.tr, isHeader: true),
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
                'reports_recommendations_subtitle'.tr,
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
                        pw.Expanded(child: pw.Text(recommendation.tr)),
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
