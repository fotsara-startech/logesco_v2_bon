import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/inventory_model.dart';
import '../../company_settings/models/company_profile.dart';
import '../../company_settings/services/company_settings_service.dart';
import '../../../core/services/auth_service.dart';
import 'package:get/get.dart';

/// Service d'impression pour les feuilles d'inventaire
class InventoryPrintService {
  /// Générer et imprimer une feuille de comptage d'inventaire
  static Future<void> printCountingSheet(
    StockInventory inventory,
    List<InventoryItem> items,
  ) async {
    // Récupérer les informations de l'entreprise
    final companyProfile = await _getCompanyProfile();

    final pdf = pw.Document();

    // Générer le contenu PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(inventory, companyProfile),
            pw.SizedBox(height: 20),
            _buildInventoryInfo(inventory),
            pw.SizedBox(height: 20),
            _buildItemsTable(items),
            pw.SizedBox(height: 20),
            _buildFooter(companyProfile),
          ];
        },
      ),
    );

    // Imprimer le PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Feuille_Comptage_${inventory.nom.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Générer et imprimer un rapport d'inventaire terminé
  static Future<void> printInventoryReport(
    StockInventory inventory,
    List<InventoryItem> items,
  ) async {
    // Récupérer les informations de l'entreprise
    final companyProfile = await _getCompanyProfile();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(inventory, companyProfile, isReport: true),
            pw.SizedBox(height: 20),
            _buildInventoryInfo(inventory),
            pw.SizedBox(height: 20),
            _buildStatistics(inventory, items),
            pw.SizedBox(height: 20),
            _buildDetailedItemsTable(items),
            pw.SizedBox(height: 20),
            _buildFooter(companyProfile),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rapport_Inventaire_${inventory.nom.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Récupérer le profil de l'entreprise
  static Future<CompanyProfile?> _getCompanyProfile() async {
    try {
      // Essayer de récupérer le profil depuis l'API
      if (Get.isRegistered<AuthService>()) {
        final authService = Get.find<AuthService>();
        final companyService = CompanySettingsService(authService);
        final response = await companyService.getCompanyProfile();

        if (response.isSuccess && response.data != null) {
          return response.data;
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération du profil d\'entreprise: $e');
    }

    // Retourner un profil par défaut si échec
    return CompanyProfile(
      name: 'VOTRE ENTREPRISE',
      address: 'Adresse de votre entreprise',
      location: 'Ville, Pays',
      phone: '+XXX XX XX XX XX',
      email: 'contact@votre-entreprise.com',
    );
  }

  /// En-tête du document
  static pw.Widget _buildHeader(StockInventory inventory, CompanyProfile? companyProfile, {bool isReport = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyProfile?.name ?? 'Mon Entreprise',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (companyProfile?.address != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      companyProfile!.address,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  if (companyProfile?.location != null) ...[
                    pw.Text(
                      companyProfile!.location!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  if (companyProfile?.phone != null) ...[
                    pw.Text(
                      'Tél: ${companyProfile!.phone}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  if (companyProfile?.email != null) ...[
                    pw.Text(
                      'Email: ${companyProfile!.email}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  isReport ? 'RAPPORT D\'INVENTAIRE' : 'FEUILLE DE COMPTAGE',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Date: ${_formatDate(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  /// Informations sur l'inventaire
  static pw.Widget _buildInventoryInfo(StockInventory inventory) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS INVENTAIRE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Nom:', inventory.nom),
              ),
              pw.Expanded(
                child: _buildInfoRow('ID:', '#${inventory.id}'),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Type:', inventory.type.displayName),
              ),
              pw.Expanded(
                child: _buildInfoRow('Statut:', inventory.status.displayName),
              ),
            ],
          ),
          if (inventory.description.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _buildInfoRow('Description:', inventory.description),
          ],
          if (inventory.nomCategorie != null) ...[
            pw.SizedBox(height: 4),
            _buildInfoRow('Catégorie:', inventory.nomCategorie!),
          ],
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoRow('Créé par:', inventory.nomUtilisateur),
              ),
              pw.Expanded(
                child: _buildInfoRow('Date création:', _formatDate(inventory.dateCreation)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ligne d'information
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  /// Statistiques de l'inventaire
  static pw.Widget _buildStatistics(StockInventory inventory, List<InventoryItem> items) {
    final totalItems = items.length;
    final countedItems = items.where((item) => item.isCounted).length;
    final itemsWithVariance = items.where((item) => item.hasVariance).length;
    final progress = totalItems > 0 ? (countedItems / totalItems * 100) : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'STATISTIQUES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildStatItem('Articles total:', '$totalItems')),
              pw.Expanded(child: _buildStatItem('Articles comptés:', '$countedItems')),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _buildStatItem('Écarts détectés:', '$itemsWithVariance')),
              pw.Expanded(child: _buildStatItem('Progression:', '${progress.toStringAsFixed(1)}%')),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'VALORISATION',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _buildStatItem('Valeur système:', '${_calculateTotalSystemValue(items).toStringAsFixed(0)} FCFA')),
              pw.Expanded(child: _buildStatItem('Valeur comptée:', '${_calculateTotalCountedValue(items).toStringAsFixed(0)} FCFA')),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(child: _buildStatItem('Écart de valeur:', '${_calculateTotalValueVariance(items).toStringAsFixed(0)} FCFA')),
              pw.Expanded(child: pw.Container()),
            ],
          ),
        ],
      ),
    );
  }

  /// Item de statistique
  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  /// Table des articles pour feuille de comptage
  static pw.Widget _buildItemsTable(List<InventoryItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ARTICLES À COMPTER',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Produit
            1: const pw.FlexColumnWidth(2), // Code
            2: const pw.FlexColumnWidth(1), // Qté Système
            3: const pw.FlexColumnWidth(1), // Qté Comptée
            4: const pw.FlexColumnWidth(2), // Observations
          },
          children: [
            // En-tête
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Produit', isHeader: true),
                _buildTableCell('Code', isHeader: true),
                _buildTableCell('Qté Sys.', isHeader: true),
                _buildTableCell('Qté Comptée', isHeader: true),
                _buildTableCell('Observations', isHeader: true),
              ],
            ),
            // Lignes des articles
            ...items.map((item) => pw.TableRow(
                  children: [
                    _buildTableCell(item.nomProduit),
                    _buildTableCell(item.codeProduit ?? ''),
                    _buildTableCell(item.quantiteSysteme.toStringAsFixed(0)),
                    _buildTableCell(''), // Champ vide pour saisie manuelle
                    _buildTableCell(''), // Champ vide pour observations
                  ],
                )),
          ],
        ),
      ],
    );
  }

  /// Table détaillée des articles pour rapport
  static pw.Widget _buildDetailedItemsTable(List<InventoryItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉTAIL DES ARTICLES',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2), // Produit
            1: const pw.FlexColumnWidth(1), // Code
            2: const pw.FlexColumnWidth(1), // Qté Système
            3: const pw.FlexColumnWidth(1), // Qté Comptée
            4: const pw.FlexColumnWidth(1), // Écart
            5: const pw.FlexColumnWidth(1), // Valeur Sys.
            6: const pw.FlexColumnWidth(1), // Écart Val.
            7: const pw.FlexColumnWidth(1), // Statut
          },
          children: [
            // En-tête
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Produit', isHeader: true),
                _buildTableCell('Code', isHeader: true),
                _buildTableCell('Qté Sys.', isHeader: true),
                _buildTableCell('Qté Comptée', isHeader: true),
                _buildTableCell('Écart', isHeader: true),
                _buildTableCell('Valeur Sys.', isHeader: true),
                _buildTableCell('Écart Val.', isHeader: true),
                _buildTableCell('Statut', isHeader: true),
              ],
            ),
            // Lignes des articles
            ...items.map((item) => pw.TableRow(
                  children: [
                    _buildTableCell(item.nomProduit),
                    _buildTableCell(item.codeProduit ?? ''),
                    _buildTableCell(item.quantiteSysteme.toStringAsFixed(0)),
                    _buildTableCell(item.isCounted ? item.quantiteComptee!.toStringAsFixed(0) : '-'),
                    _buildTableCell(item.isCounted ? item.calculatedEcart.toStringAsFixed(0) : '-'),
                    _buildTableCell(item.valeurSysteme.toStringAsFixed(0)),
                    _buildTableCell(item.isCounted ? item.ecartValeur.toStringAsFixed(0) : '-'),
                    _buildTableCell(item.isCounted ? (item.hasVariance ? 'ÉCART' : 'OK') : 'À COMPTER'),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  /// Cellule de table
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Pied de page
  static pw.Widget _buildFooter(CompanyProfile? companyProfile) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Signature responsable: ____________________',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Date: ____________________',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Document généré automatiquement par ${companyProfile?.name ?? 'Mon Entreprise'}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Formater une date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Calculer la valeur système totale
  static double _calculateTotalSystemValue(List<InventoryItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.valeurSysteme);
  }

  /// Calculer la valeur comptée totale
  static double _calculateTotalCountedValue(List<InventoryItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.valeurComptee);
  }

  /// Calculer l'écart de valeur total
  static double _calculateTotalValueVariance(List<InventoryItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.ecartValeur);
  }
}
