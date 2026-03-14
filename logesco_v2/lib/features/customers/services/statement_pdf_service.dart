import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../core/config/api_config.dart';

/// Service pour générer les PDF de relevés de compte
class StatementPdfService {
  /// Génère le PDF du relevé de compte
  static Future<Uint8List> generateStatementPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    print('📊 [PDF] Données reçues:');
    print('   - Type: ${data.runtimeType}');
    print('   - Clés: ${data.keys.toList()}');

    final entreprise = data['entreprise'] as Map<String, dynamic>?;
    final client = data['client'] as Map<String, dynamic>;
    final compte = data['compte'] as Map<String, dynamic>;
    final transactions = (data['transactions'] as List<dynamic>?) ?? [];

    print('📊 Génération PDF relevé de compte:');
    print('   Transactions reçues: ${transactions.length}');
    print('   Logo path: ${entreprise?['logoPath']}');
    print('   Entreprise: ${entreprise?['nom']}');

    // Charger le logo depuis le backend via HTTP
    Uint8List? logoBytes;
    if (entreprise?['logoPath'] != null && (entreprise!['logoPath'] as String).isNotEmpty) {
      try {
        var logoPath = entreprise['logoPath'] as String;
        print('🖼️ Tentative de chargement du logo depuis le backend: $logoPath');

        // Nettoyer le chemin: extraire juste le nom du fichier au cas où
        // (au cas où le backend envoie encore un chemin complet)
        if (logoPath.contains('\\') || logoPath.contains('/')) {
          final parts = logoPath.replaceAll('\\', '/').split('/');
          logoPath = parts.last;
          print('   Chemin nettoyé: $logoPath');
        }

        // Construire l'URL du logo depuis le backend
        final baseUrl = ApiConfig.currentBaseUrl;
        // Retirer /api/v1 de la fin pour obtenir l'URL de base du serveur
        final serverUrl = baseUrl.replaceAll('/api/v1', '');
        final logoUrl = '$serverUrl/uploads/$logoPath';

        print('   URL du logo: $logoUrl');

        final response = await http.get(Uri.parse(logoUrl)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Timeout lors du chargement du logo');
            throw Exception('Timeout');
          },
        );

        if (response.statusCode == 200) {
          logoBytes = response.bodyBytes;
          print('✅ Logo chargé depuis le backend (${logoBytes.length} bytes)');
        } else {
          print('⚠️ Erreur HTTP ${response.statusCode} lors du chargement du logo');
        }
      } catch (e) {
        print('⚠️ Erreur chargement logo: $e');
      }
    } else {
      print('⚠️ Logo path non défini ou vide');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── En-tête : logo + infos entreprise ──────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Logo
                    if (logoBytes != null)
                      pw.Container(
                        width: 45,
                        height: 45,
                        margin: const pw.EdgeInsets.only(right: 12),
                        child: pw.Image(
                          pw.MemoryImage(logoBytes),
                          fit: pw.BoxFit.contain,
                        ),
                      )
                    else
                      pw.Container(
                        width: 45,
                        height: 45,
                        margin: const pw.EdgeInsets.only(right: 12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: pw.BorderRadius.circular(3),
                          border: pw.Border.all(color: PdfColors.blue, width: 1),
                        ),
                        child: pw.Center(
                          child: pw.Text('LOGO', style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue)),
                        ),
                      ),
                    // Informations entreprise
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            entreprise?['nom'] ?? 'ENTREPRISE',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (entreprise?['localisation'] != null)
                            pw.Text(
                              entreprise!['localisation'],
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          pw.Row(
                            children: [
                              if (entreprise?['telephone'] != null)
                                pw.Text(
                                  '${_getTranslation('statement_phone_label')}: ${entreprise!['telephone']}',
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              if (entreprise?['nuiRccm'] != null) ...[
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  '${_getTranslation('statement_nui_rccm_label')}: ${entreprise!['nuiRccm']}',
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ── Bannière fusionnée : titre + infos client + solde ──────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue700, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // ── Titre du relevé ──
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue700,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5),
                          topRight: pw.Radius.circular(5),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            _getTranslation('statement_title_customer'),
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            _getTranslation('statement_generated_date').replaceAll('@date', _formatDateForPDF(DateTime.now())),
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Infos client + solde côte à côte ──
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Infos client (partie gauche)
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  _getTranslation('statement_client_label'),
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue700,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  '${client['nomComplet']}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (client['telephone'] != null)
                                  pw.Text(
                                    '${_getTranslation('statement_phone_label')}: ${client['telephone']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                if (client['email'] != null)
                                  pw.Text(
                                    '${_getTranslation('statement_email_label')}: ${client['email']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                              ],
                            ),
                          ),

                          // Séparateur vertical
                          pw.Container(
                            width: 1,
                            height: 55,
                            margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                            color: PdfColors.grey300,
                          ),

                          // Solde (partie droite)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                _getTranslation('statement_balance_label'),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue700,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: pw.BoxDecoration(
                                  color: compte['aDette'] == true ? PdfColors.red50 : PdfColors.green50,
                                  border: pw.Border.all(
                                    color: compte['aDette'] == true ? PdfColors.red : PdfColors.green,
                                    width: 1.5,
                                  ),
                                  borderRadius: pw.BorderRadius.circular(5),
                                ),
                                child: pw.Text(
                                  '${compte['soldeActuel'].toStringAsFixed(0)} FCFA',
                                  style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: compte['aDette'] == true ? PdfColors.red : PdfColors.green,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                compte['aDette'] == true ? _getTranslation('statement_balance_due') : _getTranslation('statement_credit_available'),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: compte['aDette'] == true ? PdfColors.red : PdfColors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ── Tableau des transactions ────────────────────────────────────
              pw.Text(
                _getTranslation('statement_transactions_history').replaceAll('@count', transactions.length.toString()),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              if (transactions.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      _getTranslation('statement_no_transactions'),
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    ),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: _buildTransactionRows(transactions),
                ),

              pw.Spacer(),

              // ── Pied de page ───────────────────────────────────────────────
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                _getTranslation('statement_generated_on').replaceAll('@date', _formatDateForPDF(DateTime.now())),
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

  /// Construit les lignes du tableau des transactions
  static List<pw.TableRow> _buildTransactionRows(List<dynamic> transactions) {
    print('📊 [PDF] Construction des lignes du tableau');
    print('   - Nombre de transactions: ${transactions.length}');
    print('   - Type: ${transactions.runtimeType}');

    final rows = <pw.TableRow>[];

    // En-tête du tableau
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildTableCell(_getTranslation('statement_table_date'), isHeader: true),
          _buildTableCell(_getTranslation('statement_table_description'), isHeader: true),
          _buildTableCell(_getTranslation('statement_table_amount'), isHeader: true),
          _buildTableCell(_getTranslation('statement_table_balance'), isHeader: true),
        ],
      ),
    );

    // Lignes de transactions
    for (int i = 0; i < transactions.length; i++) {
      try {
        final t = transactions[i];
        print('📝 [PDF] Traitement transaction #$i');
        print('   - Type: ${t.runtimeType}');
        print('   - Clés: ${(t as Map).keys.toList()}');

        final isCredit = t['isCredit'] == true || (t['typeTransaction'] != null && (t['typeTransaction'].toString().contains('paiement') || t['typeTransaction'].toString().contains('credit')));

        final typeDetail = t['typeTransactionDetail'] ?? t['typeTransaction'] ?? 'Transaction';

        // Construire la description
        String description = t['description'] ?? _getTransactionTypeLabel(typeDetail.toString());
        if (t['venteReference'] != null && t['venteReference'].toString().isNotEmpty) {
          final venteRef = t['venteReference'];
          if (!description.contains(venteRef)) {
            description = '$description - Vente $venteRef';
          }
        }

        final montant = t['montant'] is num ? t['montant'] : double.tryParse(t['montant'].toString()) ?? 0;
        final soldeApres = t['soldeApres'] is num ? t['soldeApres'] : double.tryParse(t['soldeApres'].toString()) ?? 0;

        print('   ✅ Description: $description, Montant: $montant, Solde: $soldeApres');

        rows.add(
          pw.TableRow(
            children: [
              _buildTableCell(_formatDateForPDF(DateTime.parse(t['dateTransaction'].toString()))),
              _buildTableCell(description),
              _buildTableCell(
                '${isCredit ? '+' : '-'}${montant.toStringAsFixed(0)} F',
                color: isCredit ? PdfColors.green : PdfColors.red,
              ),
              _buildTableCell('${soldeApres.toStringAsFixed(0)} F'),
            ],
          ),
        );
      } catch (e) {
        print('⚠️ [PDF] Erreur parsing transaction #$i: $e');
        print('   - Transaction: ${transactions[i]}');
        rows.add(
          pw.TableRow(
            children: [
              _buildTableCell('Erreur'),
              _buildTableCell('Erreur parsing'),
              _buildTableCell('0 F'),
              _buildTableCell('0 F'),
            ],
          ),
        );
      }
    }

    print('📊 [PDF] ${rows.length} lignes construites (1 en-tête + ${rows.length - 1} transactions)');
    return rows;
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

  /// Obtient une traduction basée sur la langue actuelle
  static String _getTranslation(String key) {
    try {
      return key.tr;
    } catch (e) {
      // Fallback si la traduction n'existe pas
      print('⚠️ Traduction manquante: $key');
      return key;
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
