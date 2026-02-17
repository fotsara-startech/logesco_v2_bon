import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/movement_report_service.dart';

class FinancialReportPdfService {
  static Future<void> printFinancialReport({
    required DateTime startDate,
    required DateTime endDate,
    required MovementSummary summary,
    required List<CategorySummary> categorySummaries,
    required List<DailySummary> dailySummaries,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RAPPORT FINANCIER',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Periode: ${formatDate(startDate)} - ${formatDate(endDate)}'),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('RESUME', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Total des depenses: ${summary.totalAmountFormatted}'),
              pw.Text('Nombre de mouvements: ${summary.totalCount}'),
              pw.Text('Montant moyen: ${summary.averageAmountFormatted}'),
              pw.SizedBox(height: 20),
              if (categorySummaries.isNotEmpty) ...[
                pw.Text('CATEGORIES', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...categorySummaries.map((cat) => pw.Text('${cat.categoryDisplayName}: ${cat.amountFormatted}')),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rapport_Financier.pdf',
    );
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
