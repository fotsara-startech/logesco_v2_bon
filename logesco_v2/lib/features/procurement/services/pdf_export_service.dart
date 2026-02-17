/**
 * Service pour l'export PDF des commandes d'approvisionnement
 */

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../models/procurement_models.dart';
import '../../company_settings/models/company_profile.dart';
import '../../company_settings/services/company_settings_service.dart';
import '../../../core/services/auth_service.dart';

class ProcurementPdfExportService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  // Couleurs pour le PDF
  static final PdfColor _primaryColor = PdfColor.fromHex('#1e40af');
  static final PdfColor _greyBorder = PdfColor.fromHex('#d1d5db');
  static final PdfColor _greyBackground = PdfColor.fromHex('#f3f4f6');
  static final PdfColor _greyText = PdfColor.fromHex('#6b7280');
  static final PdfColor _orangeColor = PdfColor.fromHex('#ea580c');
  static final PdfColor _blueColor = PdfColor.fromHex('#2563eb');
  static final PdfColor _greenColor = PdfColor.fromHex('#16a34a');
  static final PdfColor _redColor = PdfColor.fromHex('#dc2626');

  /// Exporte une commande d'approvisionnement en PDF
  static Future<String> exportCommandeToPdf(CommandeApprovisionnement commande) async {
    final pdf = pw.Document();

    // Récupérer les informations de l'entreprise
    CompanyProfile? companyProfile;
    try {
      final companyService = CompanySettingsService(AuthService());
      final response = await companyService.getCompanyProfile();
      if (response.isSuccess && response.data != null) {
        companyProfile = response.data;
      }
    } catch (e) {
      print('Erreur lors de la récupération des paramètres entreprise: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(commande, companyProfile),
            pw.SizedBox(height: 20),
            _buildCommandeInfo(commande),
            pw.SizedBox(height: 20),
            _buildFournisseurInfo(commande),
            pw.SizedBox(height: 20),
            _buildDetailsTable(commande),
            pw.SizedBox(height: 20),
            _buildTotaux(commande),
            pw.SizedBox(height: 20),
            _buildFooter(commande, companyProfile),
          ];
        },
      ),
    );

    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/commande_${commande.numeroCommande}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Construit l'en-tête du document
  static pw.Widget _buildHeader(CommandeApprovisionnement commande, CompanyProfile? companyProfile) {
    return pw.Column(
      children: [
        // En-tête avec informations de l'entreprise
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyProfile?.name ?? 'LOGESCO',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  if (companyProfile?.address != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      companyProfile!.address,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  if (companyProfile?.phone != null) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Tél: ${companyProfile!.phone}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  if (companyProfile?.email != null) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Email: ${companyProfile!.email}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'COMMANDE D\'APPROVISIONNEMENT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'N° ${commande.numeroCommande}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: _primaryColor, thickness: 2),
      ],
    );
  }

  /// Construit les informations de la commande
  static pw.Widget _buildCommandeInfo(CommandeApprovisionnement commande) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _greyBorder),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Date de commande: ${_dateFormat.format(commande.dateCommande)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                if (commande.dateLivraisonPrevue != null)
                  pw.Text(
                    'Livraison prévue: ${_dateFormat.format(commande.dateLivraisonPrevue!)}',
                  ),
                pw.Text('Mode de paiement: ${commande.modePaiement.label}'),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Statut: ${commande.statut.label}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: _getStatutColor(commande.statut),
                  ),
                ),
                if (commande.statistiques != null) ...[
                  pw.Text(
                    'Progression: ${commande.statistiques!.pourcentageReception}%',
                  ),
                  pw.Text(
                    'Produits reçus: ${commande.statistiques!.produitsCompletsRecus}/${commande.statistiques!.nombreProduits}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit les informations du fournisseur
  static pw.Widget _buildFournisseurInfo(CommandeApprovisionnement commande) {
    if (commande.fournisseur == null) {
      return pw.Container();
    }

    final fournisseur = commande.fournisseur!;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _greyBorder),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FOURNISSEUR',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            fournisseur.nom,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (fournisseur.telephone != null) pw.Text('Téléphone: ${fournisseur.telephone}'),
          if (fournisseur.email != null) pw.Text('Email: ${fournisseur.email}'),
          if (fournisseur.adresse != null) pw.Text('Adresse: ${fournisseur.adresse}'),
        ],
      ),
    );
  }

  /// Construit le tableau des détails
  static pw.Widget _buildDetailsTable(CommandeApprovisionnement commande) {
    return pw.Table(
      border: pw.TableBorder.all(color: _greyBorder),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _greyBackground),
          children: [
            _buildTableCell('Produit', isHeader: true),
            _buildTableCell('Qté Cmd', isHeader: true),
            _buildTableCell('Qté Reçue', isHeader: true),
            _buildTableCell('Restant', isHeader: true),
            _buildTableCell('Prix Unit.', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Lignes de détails
        ...commande.details.map((detail) => pw.TableRow(
              children: [
                _buildTableCell(detail.produit?.nom ?? 'Produit inconnu'),
                _buildTableCell(detail.quantiteCommandee.toString()),
                _buildTableCell(detail.quantiteRecue.toString()),
                _buildTableCell(detail.quantiteRestante.toString()),
                _buildTableCell(_currencyFormat.format(detail.coutUnitaire)),
                _buildTableCell(_currencyFormat.format(detail.coutTotal)),
              ],
            )),
      ],
    );
  }

  /// Construit une cellule de tableau
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Construit la section des totaux
  static pw.Widget _buildTotaux(CommandeApprovisionnement commande) {
    final montantTotal = commande.montantTotal ?? commande.details.fold<double>(0.0, (sum, detail) => sum + detail.coutTotal);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _greyBorder),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nombre d\'articles:'),
                  pw.Text('${commande.details.length}'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Quantité totale:'),
                  pw.Text('${commande.details.fold<int>(0, (sum, detail) => sum + detail.quantiteCommandee)}'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _currencyFormat.format(montantTotal),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit le pied de page
  static pw.Widget _buildFooter(CommandeApprovisionnement commande, CompanyProfile? companyProfile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (commande.notes != null && commande.notes!.isNotEmpty) ...[
          pw.Text(
            'Notes:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(commande.notes!),
          pw.SizedBox(height: 10),
        ],
        pw.Divider(color: _primaryColor),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Document généré le ${_dateFormat.format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 8, color: _greyText),
            ),
            pw.Text(
              'LOGESCO - Système de Gestion Commerciale',
              style: pw.TextStyle(fontSize: 8, color: _greyText),
            ),
          ],
        ),
      ],
    );
  }

  /// Retourne la couleur selon le statut
  static PdfColor _getStatutColor(CommandeStatut statut) {
    switch (statut) {
      case CommandeStatut.enAttente:
        return _orangeColor;
      case CommandeStatut.partielle:
        return _blueColor;
      case CommandeStatut.terminee:
        return _greenColor;
      case CommandeStatut.annulee:
        return _redColor;
    }
  }
}
