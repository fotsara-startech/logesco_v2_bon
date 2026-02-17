import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

/// Service pour générer les PDF de relevés de compte
class StatementPdfService {
  /// Génère le PDF du relevé de compte
  static Future<Uint8List> generateStatementPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final entreprise = data['entreprise'] as Map<String, dynamic>?;
    final client = data['client'] as Map<String, dynamic>;
    final compte = data['compte'] as Map<String, dynamic>;
    final transactions = data['transactions'] as List<dynamic>;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête entreprise (si disponible)
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
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (entreprise['adresse'] != null) pw.Text(entreprise['adresse'], style: const pw.TextStyle(fontSize: 10)),
                      if (entreprise['telephone'] != null) pw.Text('Tél: ${entreprise['telephone']}', style: const pw.TextStyle(fontSize: 10)),
                      if (entreprise['email'] != null) pw.Text('Email: ${entreprise['email']}', style: const pw.TextStyle(fontSize: 10)),
                      if (entreprise['nuiRccm'] != null) pw.Text('NUI/RCCM: ${entreprise['nuiRccm']}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Titre du relevé
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RELEVÉ DE COMPTE CLIENT',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Date: ${_formatDateForPDF(DateTime.now())}',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Informations client
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
                      'INFORMATIONS CLIENT',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text('Nom: ${client['nomComplet']}', style: const pw.TextStyle(fontSize: 12)),
                    if (client['telephone'] != null) pw.Text('Téléphone: ${client['telephone']}', style: const pw.TextStyle(fontSize: 12)),
                    if (client['email'] != null) pw.Text('Email: ${client['email']}', style: const pw.TextStyle(fontSize: 12)),
                    if (client['adresse'] != null) pw.Text('Adresse: ${client['adresse']}', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Solde du compte
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: compte['aDette'] == true ? PdfColors.red50 : PdfColors.green50,
                  border: pw.Border.all(
                    color: compte['aDette'] == true ? PdfColors.red : PdfColors.green,
                    width: 2,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SOLDE ACTUEL',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${compte['soldeActuel'].toStringAsFixed(0)} FCFA',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: compte['aDette'] == true ? PdfColors.red : PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Tableau des transactions
              pw.Text(
                'HISTORIQUE DES TRANSACTIONS (${transactions.length})',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              if (transactions.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Aucune transaction enregistrée',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // En-tête du tableau
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCell('Date', isHeader: true),
                        _buildTableCell('Description', isHeader: true),
                        _buildTableCell('Montant', isHeader: true),
                        _buildTableCell('Solde', isHeader: true),
                      ],
                    ),
                    // Lignes de transactions
                    ...transactions.take(50).map((t) {
                      final isCredit = t['isCredit'] == true;
                      final typeDetail = t['typeTransactionDetail'] ?? t['typeTransaction'];

                      // Construire la description avec la référence de vente si disponible
                      String description = t['description'] ?? _getTransactionTypeLabel(typeDetail);
                      if (t['venteReference'] != null && t['venteReference'].toString().isNotEmpty) {
                        final venteRef = t['venteReference'];
                        // Si la description ne contient pas déjà la référence, l'ajouter
                        if (!description.contains(venteRef)) {
                          description = '$description - Vente $venteRef';
                        }
                      }

                      return pw.TableRow(
                        children: [
                          _buildTableCell(_formatDateForPDF(DateTime.parse(t['dateTransaction']))),
                          _buildTableCell(description),
                          _buildTableCell(
                            '${isCredit ? '+' : '-'}${t['montant'].toStringAsFixed(0)} F',
                            color: isCredit ? PdfColors.green : PdfColors.red,
                          ),
                          _buildTableCell('${t['soldeApres'].toStringAsFixed(0)} F'),
                        ],
                      );
                    }).toList(),
                  ],
                ),

              pw.Spacer(),

              // Pied de page
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Document généré automatiquement le ${_formatDateForPDF(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construit une cellule de tableau
  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  /// Formate une date pour le PDF
  static String _formatDateForPDF(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Obtient le label d'un type de transaction
  static String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'achat_comptant':
        return 'Achat comptant';
      case 'achat_credit':
        return 'Achat à crédit';
      case 'paiement':
        return 'Paiement';
      case 'paiement_comptant':
        return 'Paiement comptant';
      case 'paiement_dette':
        return 'Paiement dette';
      case 'credit':
        return 'Crédit';
      case 'debit':
        return 'Débit';
      default:
        return type;
    }
  }

  /// Sauvegarde le PDF
  static Future<String> saveAndOpenPDF(Uint8List pdfBytes, String filename) async {
    try {
      // Pour desktop/mobile, sauvegarder dans le répertoire documents
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');

      // Écrire le fichier
      await file.writeAsBytes(pdfBytes);

      print('✅ PDF sauvegardé: ${file.path}');

      // Retourner le chemin
      return file.path;
    } catch (e) {
      print('❌ Erreur sauvegarde PDF: $e');
      throw Exception('Erreur lors de la sauvegarde du PDF: $e');
    }
  }
}
