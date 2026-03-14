// import 'dart:io';
// import 'dart:typed_data';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';

// /// Service pour générer les PDF de relevés de compte fournisseur
// class SupplierStatementPdfService {
//   /// Génère le PDF du relevé de compte fournisseur
//   static Future<Uint8List> generateStatementPDF(Map<String, dynamic> data) async {
//     final pdf = pw.Document();

//     final entreprise = data['entreprise'] as Map<String, dynamic>?;
//     final fournisseur = data['fournisseur'] as Map<String, dynamic>;
//     final compte = data['compte'] as Map<String, dynamic>;
//     final transactions = data['transactions'] as List<dynamic>;

//     // Convertir le solde en double de manière sûre
//     final soldeCompte = (compte['solde'] is int) ? (compte['solde'] as int).toDouble() : (compte['solde'] as double);

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(40),
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // En-tête entreprise
//               if (entreprise != null) ...[
//                 pw.Container(
//                   padding: const pw.EdgeInsets.all(16),
//                   decoration: pw.BoxDecoration(
//                     border: pw.Border.all(color: PdfColors.grey400),
//                     borderRadius: pw.BorderRadius.circular(8),
//                   ),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text(
//                         entreprise['nom'] ?? 'ENTREPRISE',
//                         style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
//                       ),
//                       pw.SizedBox(height: 4),
//                       if (entreprise['adresse'] != null) pw.Text(entreprise['adresse'], style: const pw.TextStyle(fontSize: 10)),
//                       if (entreprise['telephone'] != null) pw.Text('Tél: ${entreprise['telephone']}', style: const pw.TextStyle(fontSize: 10)),
//                     ],
//                   ),
//                 ),
//                 pw.SizedBox(height: 20),
//               ],

//               // Titre
//               pw.Center(
//                 child: pw.Text(
//                   'RELEVÉ DE COMPTE FOURNISSEUR',
//                   style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
//                 ),
//               ),
//               pw.SizedBox(height: 20),

//               // Informations fournisseur
//               pw.Container(
//                 padding: const pw.EdgeInsets.all(12),
//                 decoration: pw.BoxDecoration(
//                   color: PdfColors.grey200,
//                   borderRadius: pw.BorderRadius.circular(8),
//                 ),
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       'Fournisseur: ${fournisseur['nom']}',
//                       style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
//                     ),
//                     if (fournisseur['telephone'] != null) pw.Text('Téléphone: ${fournisseur['telephone']}', style: const pw.TextStyle(fontSize: 10)),
//                     if (fournisseur['email'] != null) pw.Text('Email: ${fournisseur['email']}', style: const pw.TextStyle(fontSize: 10)),
//                   ],
//                 ),
//               ),
//               pw.SizedBox(height: 20),

//               // Solde du compte
//               pw.Container(
//                 padding: const pw.EdgeInsets.all(12),
//                 decoration: pw.BoxDecoration(
//                   color: soldeCompte > 0 ? PdfColors.red50 : PdfColors.green50,
//                   border: pw.Border.all(
//                     color: soldeCompte > 0 ? PdfColors.red : PdfColors.green,
//                     width: 2,
//                   ),
//                   borderRadius: pw.BorderRadius.circular(8),
//                 ),
//                 child: pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Text('Solde du compte:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
//                     pw.Text(
//                       '${soldeCompte.toStringAsFixed(0)} FCFA',
//                       style: pw.TextStyle(
//                         fontSize: 16,
//                         fontWeight: pw.FontWeight.bold,
//                         color: soldeCompte > 0 ? PdfColors.red : PdfColors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               pw.SizedBox(height: 20),

//               // Tableau des transactions
//               pw.Text('Historique des transactions', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 10),

//               pw.Table(
//                 border: pw.TableBorder.all(color: PdfColors.grey400),
//                 children: [
//                   // En-tête
//                   pw.TableRow(
//                     decoration: const pw.BoxDecoration(color: PdfColors.grey300),
//                     children: [
//                       _buildTableCell('Date', isHeader: true),
//                       _buildTableCell('Type', isHeader: true),
//                       _buildTableCell('Description', isHeader: true),
//                       _buildTableCell('Montant', isHeader: true),
//                       _buildTableCell('Solde', isHeader: true),
//                     ],
//                   ),
//                   // Lignes de transactions
//                   ...transactions.map((t) {
//                     final transaction = t as Map<String, dynamic>;
//                     // Convertir les montants de manière sûre
//                     final montant = (transaction['montant'] is int) ? (transaction['montant'] as int).toDouble() : (transaction['montant'] as double);
//                     final soldeApres = (transaction['soldeApres'] is int) ? (transaction['soldeApres'] as int).toDouble() : (transaction['soldeApres'] as double);

//                     return pw.TableRow(
//                       children: [
//                         _buildTableCell(_formatDate(transaction['dateTransaction'])),
//                         _buildTableCell(transaction['typeTransaction'] ?? ''),
//                         _buildTableCell(transaction['description'] ?? ''),
//                         _buildTableCell(
//                           '${montant.toStringAsFixed(0)} FCFA',
//                           color: transaction['typeTransaction'] == 'paiement' ? PdfColors.green : PdfColors.red,
//                         ),
//                         _buildTableCell('${soldeApres.toStringAsFixed(0)} FCFA'),
//                       ],
//                     );
//                   }).toList(),
//                 ],
//               ),

//               pw.Spacer(),

//               // Pied de page
//               pw.Divider(),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text('Date d\'impression: ${_formatDate(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
//                   pw.Text('Page 1/1', style: const pw.TextStyle(fontSize: 8)),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     return pdf.save();
//   }

//   static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.all(4),
//       child: pw.Text(
//         text,
//         style: pw.TextStyle(
//           fontSize: isHeader ? 10 : 9,
//           fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
//           color: color,
//         ),
//       ),
//     );
//   }

//   static String _formatDate(dynamic date) {
//     if (date == null) return '';
//     DateTime dt;
//     if (date is String) {
//       dt = DateTime.parse(date);
//     } else if (date is DateTime) {
//       dt = date;
//     } else {
//       return '';
//     }
//     return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
//   }

//   /// Sauvegarde et ouvre le PDF
//   static Future<String> saveAndOpenPDF(Uint8List pdfBytes, String filename) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/$filename');
//     await file.writeAsBytes(pdfBytes);
//     return file.path;
//   }
// }

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../core/config/api_config.dart';

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
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ── Bannière fusionnée : titre + infos fournisseur + solde ──────
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
                            _getTranslation('statement_title_supplier'),
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            _getTranslation('statement_generated_date').replaceAll('@date', _formatDateFull(DateTime.now())),
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Infos fournisseur + solde côte à côte ──
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Infos fournisseur (partie gauche)
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  _getTranslation('statement_supplier_label'),
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.blue700,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  '${fournisseur['nom']}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (fournisseur['telephone'] != null)
                                  pw.Text(
                                    '${_getTranslation('statement_phone_label')}: ${fournisseur['telephone']}',
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                if (fournisseur['email'] != null)
                                  pw.Text(
                                    '${_getTranslation('statement_email_label')}: ${fournisseur['email']}',
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
                                  color: soldeCompte > 0 ? PdfColors.red50 : PdfColors.green50,
                                  border: pw.Border.all(
                                    color: soldeCompte > 0 ? PdfColors.red : PdfColors.green,
                                    width: 1.5,
                                  ),
                                  borderRadius: pw.BorderRadius.circular(5),
                                ),
                                child: pw.Text(
                                  '${soldeCompte.toStringAsFixed(0)} FCFA',
                                  style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: soldeCompte > 0 ? PdfColors.red : PdfColors.green,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                soldeCompte > 0 ? _getTranslation('statement_balance_due') : _getTranslation('statement_balanced'),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: soldeCompte > 0 ? PdfColors.red : PdfColors.green,
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
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
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
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(3),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // En-tête
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableCell(_getTranslation('statement_table_date'), isHeader: true),
                        _buildTableCell(_getTranslation('statement_table_type'), isHeader: true),
                        _buildTableCell(_getTranslation('statement_table_description'), isHeader: true),
                        _buildTableCell(_getTranslation('statement_table_amount'), isHeader: true),
                        _buildTableCell(_getTranslation('statement_table_balance'), isHeader: true),
                      ],
                    ),
                    // Lignes de transactions
                    ...transactions.map((t) {
                      final transaction = t as Map<String, dynamic>;
                      final montant = (transaction['montant'] is int) ? (transaction['montant'] as int).toDouble() : (transaction['montant'] as double);
                      final soldeApres = (transaction['soldeApres'] is int) ? (transaction['soldeApres'] as int).toDouble() : (transaction['soldeApres'] as double);

                      final isPaiement = transaction['typeTransaction'] == 'paiement';

                      return pw.TableRow(
                        children: [
                          _buildTableCell(_formatDate(transaction['dateTransaction'])),
                          _buildTableCell(transaction['typeTransaction'] ?? ''),
                          _buildTableCell(transaction['description'] ?? ''),
                          _buildTableCell(
                            '${isPaiement ? '-' : '+'}${montant.toStringAsFixed(0)} F',
                            color: isPaiement ? PdfColors.green : PdfColors.red,
                          ),
                          _buildTableCell('${soldeApres.toStringAsFixed(0)} F'),
                        ],
                      );
                    }).toList(),
                  ],
                ),

              pw.Spacer(),

              // ── Pied de page ───────────────────────────────────────────────
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    _getTranslation('statement_generated_on').replaceAll('@date', _formatDateFull(DateTime.now())),
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                  pw.Text('Page 1/1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
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
      padding: const pw.EdgeInsets.all(6),
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

  /// Formate une date courte (jj/mm/aaaa)
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

  /// Formate une date complète avec heure (jj/mm/aaaa hh:mm)
  static String _formatDateFull(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Sauvegarde et ouvre le PDF
  static Future<String> saveAndOpenPDF(Uint8List pdfBytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(pdfBytes);
    print('✅ PDF sauvegardé: ${file.path}');
    return file.path;
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
}
