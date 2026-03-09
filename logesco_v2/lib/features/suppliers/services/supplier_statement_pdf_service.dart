import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

/// Service pour générer les PDF de relevés de compte fournisseur
class SupplierStatementPdfService {
  /// Génère le PDF du relevé de compte fournisseur
  static Future<Uint8List> generateStatementPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final entreprise = data['entreprise'] as Map<String, dynamic>?;
    final fournisseur = data['fournisseur'] as Map<String, dynamic>;
    final compte = data['compte'] as Map<String, dynamic>;
    final transactions = data['transactions'] as List<dynamic>;

    // Convertir le solde en double de manière sûre
    final soldeCompte = (compte['solde'] is int) ? (compte['solde'] as int).toDouble() : (compte['solde'] as double);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête entreprise
              if (entreprise != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        entreprise['nom'] ?? 'ENTREPRISE',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      if (entreprise['adresse'] != null) pw.Text(entreprise['adresse'], style: const pw.TextStyle(fontSize: 10)),
                      if (entreprise['telephone'] != null) pw.Text('Tél: ${entreprise['telephone']}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Titre
              pw.Center(
                child: pw.Text(
                  'RELEVÉ DE COMPTE FOURNISSEUR',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              // Informations fournisseur
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Fournisseur: ${fournisseur['nom']}',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    if (fournisseur['telephone'] != null) pw.Text('Téléphone: ${fournisseur['telephone']}', style: const pw.TextStyle(fontSize: 10)),
                    if (fournisseur['email'] != null) pw.Text('Email: ${fournisseur['email']}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Solde du compte
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: soldeCompte > 0 ? PdfColors.red50 : PdfColors.green50,
                  border: pw.Border.all(
                    color: soldeCompte > 0 ? PdfColors.red : PdfColors.green,
                    width: 2,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Solde du compte:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '${soldeCompte.toStringAsFixed(0)} FCFA',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: soldeCompte > 0 ? PdfColors.red : PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tableau des transactions
              pw.Text('Historique des transactions', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // En-tête
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _buildTableCell('Date', isHeader: true),
                      _buildTableCell('Type', isHeader: true),
                      _buildTableCell('Description', isHeader: true),
                      _buildTableCell('Montant', isHeader: true),
                      _buildTableCell('Solde', isHeader: true),
                    ],
                  ),
                  // Lignes de transactions
                  ...transactions.map((t) {
                    final transaction = t as Map<String, dynamic>;
                    // Convertir les montants de manière sûre
                    final montant = (transaction['montant'] is int) ? (transaction['montant'] as int).toDouble() : (transaction['montant'] as double);
                    final soldeApres = (transaction['soldeApres'] is int) ? (transaction['soldeApres'] as int).toDouble() : (transaction['soldeApres'] as double);

                    return pw.TableRow(
                      children: [
                        _buildTableCell(_formatDate(transaction['dateTransaction'])),
                        _buildTableCell(transaction['typeTransaction'] ?? ''),
                        _buildTableCell(transaction['description'] ?? ''),
                        _buildTableCell(
                          '${montant.toStringAsFixed(0)} FCFA',
                          color: transaction['typeTransaction'] == 'paiement' ? PdfColors.green : PdfColors.red,
                        ),
                        _buildTableCell('${soldeApres.toStringAsFixed(0)} FCFA'),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.Spacer(),

              // Pied de page
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date d\'impression: ${_formatDate(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Page 1/1', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is String) {
      dt = DateTime.parse(date);
    } else if (date is DateTime) {
      dt = date;
    } else {
      return '';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  /// Sauvegarde et ouvre le PDF
  static Future<String> saveAndOpenPDF(Uint8List pdfBytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }
}
