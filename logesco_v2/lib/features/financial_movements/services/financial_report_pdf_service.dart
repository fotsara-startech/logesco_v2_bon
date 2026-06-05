import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../services/movement_report_service.dart';
import '../../../core/utils/pdf_save_helper.dart';

/// Service pour générer les PDF de rapports financiers
class FinancialReportPdfService {
  /// Génère et ouvre automatiquement le PDF du rapport financier
  static Future<String?> generateAndOpenFinancialReport({
    required DateTime startDate,
    required DateTime endDate,
    required MovementSummary summary,
    required List<CategorySummary> categorySummaries,
    required List<DailySummary> dailySummaries,
  }) async {
    try {
      print('📄 Génération du rapport financier PDF...');

      // Récupérer les informations de l'entreprise
      final entrepriseData = await _fetchEntrepriseData();

      print('📄 ========================================');
      print('📄 Données entreprise pour PDF:');
      print('📄 ========================================');
      print('📄 Données brutes: $entrepriseData');
      print('📄 Type: ${entrepriseData.runtimeType}');
      if (entrepriseData != null) {
        print('📄 Clés disponibles: ${entrepriseData.keys.toList()}');
        entrepriseData.forEach((key, value) {
          print('📄   $key: $value (${value.runtimeType})');
        });
      }
      print('📄 ========================================');

      // Générer le PDF
      final pdfBytes = await _generatePDF(
        startDate: startDate,
        endDate: endDate,
        summary: summary,
        categorySummaries: categorySummaries,
        dailySummaries: dailySummaries,
        entreprise: entrepriseData,
      );

      // Sauvegarder et ouvrir le PDF
      final filePath = await _saveAndOpenPDF(pdfBytes, startDate, endDate);

      print('✅ Rapport PDF généré et ouvert: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Erreur génération rapport PDF: $e');
      rethrow;
    }
  }

  /// Récupère les données de l'entreprise depuis le backend
  static Future<Map<String, dynamic>?> _fetchEntrepriseData() async {
    try {
      final authService = Get.find<AuthService>();
      final token = await authService.getToken();

      if (token == null) {
        print('⚠️ Token non disponible pour récupérer les infos entreprise');
        return null;
      }

      final baseUrl = AppConfig.currentBaseUrl;

      // Essayer l'endpoint /company-settings (authentifié)
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/company-settings'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Données entreprise récupérées depuis /company-settings');
          return data['data'] as Map<String, dynamic>?;
        } else {
          print('⚠️ Erreur HTTP ${response.statusCode} depuis /company-settings');
        }
      } catch (e) {
        print('⚠️ Erreur avec /company-settings: $e');
      }

      // Si ça échoue, essayer /company-settings/public (sans auth)
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/company-settings/public'),
          headers: {
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Données entreprise récupérées depuis /company-settings/public');
          return data['data'] as Map<String, dynamic>?;
        } else {
          print('⚠️ Erreur HTTP ${response.statusCode} depuis /company-settings/public');
        }
      } catch (e) {
        print('⚠️ Erreur avec /company-settings/public: $e');
      }
    } catch (e) {
      print('⚠️ Erreur récupération infos entreprise: $e');
    }

    // En dernier recours, retourner null
    print('⚠️ Aucune donnée entreprise disponible');
    return null;
  }

  /// Charge le logo de l'entreprise
  static Future<Uint8List?> _loadLogo(String? logoPath) async {
    if (logoPath == null || logoPath.isEmpty) return null;

    try {
      // Nettoyer le chemin
      var cleanPath = logoPath;
      if (cleanPath.contains('\\') || cleanPath.contains('/')) {
        final parts = cleanPath.replaceAll('\\', '/').split('/');
        cleanPath = parts.last;
      }

      // Construire l'URL du logo
      final baseUrl = AppConfig.currentBaseUrl;
      final serverUrl = baseUrl.replaceAll('/api/v1', '');
      final logoUrl = '$serverUrl/uploads/$cleanPath';

      final response = await http.get(Uri.parse(logoUrl)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('⚠️ Erreur chargement logo: $e');
    }
    return null;
  }

  /// Génère le document PDF
  static Future<Uint8List> _generatePDF({
    required DateTime startDate,
    required DateTime endDate,
    required MovementSummary summary,
    required List<CategorySummary> categorySummaries,
    required List<DailySummary> dailySummaries,
    Map<String, dynamic>? entreprise,
  }) async {
    final pdf = pw.Document();

    // Charger le logo
    Uint8List? logoBytes;
    if (entreprise?['logo'] != null) {
      logoBytes = await _loadLogo(entreprise!['logo']);
    }

    // Calculer les statistiques
    final periodDays = endDate.difference(startDate).inDays + 1;
    final dailyAverage = summary.totalAmount / periodDays;

    // Trier les catégories par montant décroissant
    final sortedCategories = List<CategorySummary>.from(categorySummaries)..sort((a, b) => b.amount.compareTo(a.amount));

    // Prendre les 5 premières catégories
    final topCategories = sortedCategories.take(5).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            // En-tête avec logo et infos entreprise
            _buildHeader(entreprise, logoBytes),
            pw.SizedBox(height: 15),

            // Titre du rapport
            _buildTitle(startDate, endDate),
            pw.SizedBox(height: 20),

            // Résumé général
            _buildSummarySection(summary, periodDays, dailyAverage),
            pw.SizedBox(height: 20),

            // Analyse par catégorie
            if (topCategories.isNotEmpty) ...[
              _buildCategorySection(topCategories, summary.totalAmount),
              pw.SizedBox(height: 20),
            ],

            // Tableau détaillé des catégories
            if (sortedCategories.isNotEmpty) ...[
              _buildCategoryTable(sortedCategories),
              pw.SizedBox(height: 20),
            ],

            // Évolution quotidienne
            if (dailySummaries.isNotEmpty) ...[
              _buildDailyEvolutionSection(dailySummaries),
              pw.SizedBox(height: 20),
            ],

            // Pied de page
            pw.Spacer(),
            _buildFooter(),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construit l'en-tête du document
  static pw.Widget _buildHeader(Map<String, dynamic>? entreprise, Uint8List? logoBytes) {
    print('🏢 Construction en-tête PDF:');
    print('  - Entreprise data: $entreprise');
    print('  - Logo bytes: ${logoBytes?.length ?? 0} bytes');

    // Essayer différents noms de champs possibles
    final nom = entreprise?['nom']?.toString() ?? entreprise?['nomEntreprise']?.toString() ?? entreprise?['name']?.toString() ?? 'ENTREPRISE';
    final localisation = entreprise?['localisation']?.toString() ?? entreprise?['adresse']?.toString() ?? entreprise?['address']?.toString() ?? '';
    final telephone = entreprise?['telephone']?.toString() ?? entreprise?['phone']?.toString() ?? '';
    final email = entreprise?['email']?.toString() ?? '';

    print('  - Nom final: $nom');
    print('  - Localisation finale: $localisation');
    print('  - Téléphone final: $telephone');
    print('  - Email final: $email');

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Partie gauche: Logo + Informations entreprise
            pw.Expanded(
              flex: 2,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo
                  if (logoBytes != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      margin: const pw.EdgeInsets.only(right: 15),
                      child: pw.Image(
                        pw.MemoryImage(logoBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    )
                  else
                    pw.Container(
                      width: 60,
                      height: 60,
                      margin: const pw.EdgeInsets.only(right: 15),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue200,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.blue700, width: 2),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'LOGO',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ),
                    ),
                  // Informations entreprise
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          nom,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        if (localisation.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            localisation,
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                        ],
                        if (telephone.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Tél: $telephone',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                        ],
                        if (email.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Email: $email',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.blue700, thickness: 2),
      ],
    );
  }

  /// Construit le titre du rapport
  static pw.Widget _buildTitle(DateTime startDate, DateTime endDate) {
    return pw.Column(
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'RAPPORT DES MOUVEMENTS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'FINANCIERS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Période: ${_formatDate(startDate)} au ${_formatDate(endDate)}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.blue700, thickness: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'Généré le ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit la section résumé
  static pw.Widget _buildSummarySection(MovementSummary summary, int periodDays, double dailyAverage) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RÉSUMÉ GÉNÉRAL',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard(
                'Total des dépenses',
                summary.totalAmountFormatted,
                PdfColors.red700,
              ),
              _buildSummaryCard(
                'Nombre de mouvements',
                '${summary.totalCount}',
                PdfColors.blue700,
              ),
              _buildSummaryCard(
                'Montant moyen',
                summary.averageAmountFormatted,
                PdfColors.green700,
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard(
                'Durée de la période',
                '$periodDays jour${periodDays > 1 ? 's' : ''}',
                PdfColors.purple700,
              ),
              _buildSummaryCard(
                'Moyenne quotidienne',
                '${_formatAmount(dailyAverage)} FCFA',
                PdfColors.orange700,
              ),
              _buildSummaryCard(
                'Montant max',
                '${_formatAmount(summary.maxAmount)} FCFA',
                PdfColors.pink700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une carte de résumé
  static pw.Widget _buildSummaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white, // Fond blanc
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 1), // Bordure colorée fine
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section analyse par catégorie
  static pw.Widget _buildCategorySection(List<CategorySummary> topCategories, double totalAmount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TOP 5 DES CATÉGORIES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          ...topCategories.map((category) {
            final percentage = (category.amount / totalAmount * 100);
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        category.categoryDisplayName,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${category.amountFormatted} (${percentage.toStringAsFixed(1)}%)',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Container(
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: (percentage / 100) * 500, // Approximation de la largeur
                          decoration: pw.BoxDecoration(
                            color: _parseColor(category.categoryColor),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${category.count} mouvement${category.count > 1 ? 's' : ''}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Construit le tableau détaillé des catégories
  static pw.Widget _buildCategoryTable(List<CategorySummary> categories) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DÉTAIL PAR CATÉGORIE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              // En-tête
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Catégorie', isHeader: true),
                  _buildTableCell('Montant', isHeader: true),
                  _buildTableCell('Nombre', isHeader: true),
                  _buildTableCell('Pourcentage', isHeader: true),
                ],
              ),
              // Lignes de données
              ...categories.map((category) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(category.categoryDisplayName),
                    _buildTableCell(category.amountFormatted),
                    _buildTableCell('${category.count}'),
                    _buildTableCell(category.percentageFormatted),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une cellule de tableau
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Construit la section évolution quotidienne
  static pw.Widget _buildDailyEvolutionSection(List<DailySummary> dailySummaries) {
    // Prendre les 10 derniers jours
    final recentDays = dailySummaries.take(10).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ÉVOLUTION QUOTIDIENNE (10 derniers jours)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              // En-tête
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Date', isHeader: true),
                  _buildTableCell('Montant', isHeader: true),
                  _buildTableCell('Nombre', isHeader: true),
                ],
              ),
              // Lignes de données
              ...recentDays.map((day) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(_formatDate(day.date)),
                    _buildTableCell(day.amountFormatted),
                    _buildTableCell('${day.count}'),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit le pied de page
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '- Ce rapport presente l\'ensemble des mouvements financiers (depenses) pour la periode selectionnee.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            '- Les montants sont exprimes en FCFA (Franc CFA).',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            '- Document genere automatiquement par le systeme LOGESCO.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Sauvegarde et ouvre le PDF
  static Future<String> _saveAndOpenPDF(Uint8List pdfBytes, DateTime startDate, DateTime endDate) async {
    final fileName = 'Rapport_Financier_${_formatDateForFile(startDate)}_${_formatDateForFile(endDate)}.pdf';
    return savePdfAndOpen(pdfBytes, fileName);
  }

  /// Formate une date pour l'affichage
  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  /// Formate une date et heure pour l'affichage
  static String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }

  /// Formate une date pour le nom de fichier
  static String _formatDateForFile(DateTime date) {
    return DateFormat('yyyyMMdd').format(date);
  }

  /// Formate un montant
  static String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return formatter.format(amount).replaceAll(',', ' ');
  }

  /// Parse une couleur depuis une chaîne hexadécimale
  static PdfColor _parseColor(String colorString) {
    try {
      final hex = colorString.replaceFirst('#', '');
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return PdfColor(r / 255, g / 255, b / 255);
    } catch (e) {
      return PdfColors.grey;
    }
  }

  /// Méthode legacy pour compatibilité (utilise la nouvelle méthode)
  static Future<void> printFinancialReport({
    required DateTime startDate,
    required DateTime endDate,
    required MovementSummary summary,
    required List<CategorySummary> categorySummaries,
    required List<DailySummary> dailySummaries,
  }) async {
    await generateAndOpenFinancialReport(
      startDate: startDate,
      endDate: endDate,
      summary: summary,
      categorySummaries: categorySummaries,
      dailySummaries: dailySummaries,
    );
  }
}
