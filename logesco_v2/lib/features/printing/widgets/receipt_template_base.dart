import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import '../utils/receipt_translations.dart';
import '../../company_settings/models/company_profile.dart';

/// Widget de base pour tous les templates de reçu
abstract class ReceiptTemplateBase extends StatelessWidget {
  final Receipt receipt;
  final print_models.PrintTemplate template;
  final bool showPreview;

  const ReceiptTemplateBase({
    Key? key,
    required this.receipt,
    required this.template,
    this.showPreview = false,
  }) : super(key: key);

  String t(String key) => ReceiptTranslations.get(key, language: receipt.language);

  // ─── Couleurs de la charte ────────────────────────────────────────────────
  // Couleur d'accent utilisée en texte/bordures fines uniquement — pas
  // d'aplats pleins (bandeau, encart total) : trop gourmand en encre pour
  // les clients qui impriment beaucoup de factures.
  static const Color _accent = Color(0xFF1565C0); // bleu principal
  static const Color _rowOdd = Color(0xFFF5F7FA);
  static const Color _rowEven = Colors.white;

  // ─── En-tête ─────────────────────────────────────────────────────────────

  /// Bandeau coloré avec logo (encart blanc) ou initiales
  Widget buildHeader(BuildContext context, {String? logoPath, String? serverUrl}) {
    final company = receipt.companyInfo;
    final hasLogo = logoPath != null && logoPath.isNotEmpty && serverUrl != null && serverUrl.isNotEmpty;

    // Extraire les initiales du nom de l'entreprise
    final initials = company.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    // Construire l'URL complète du logo
    String? fullLogoUrl;
    if (hasLogo) {
      // Nettoyer le serverUrl des "/api/v1" potentiels
      final cleanServerUrl = serverUrl.replaceAll('/api/v1', '');
      // Construire l'URL complète
      if (logoPath.startsWith('http')) {
        fullLogoUrl = logoPath;
      } else if (logoPath.startsWith('uploads/')) {
        fullLogoUrl = '$cleanServerUrl/$logoPath';
      } else {
        fullLogoUrl = '$cleanServerUrl/uploads/$logoPath';
      }

      // Debug: afficher l'URL du logo
      if (kDebugMode) {
        print('🖼️ Logo URL: $fullLogoUrl');
      }
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _accent, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Ligne 1: Logo/Initiales + Nom de l'entreprise
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Encart logo/initiales (contour fin, pas d'aplat)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: _accent, width: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: fullLogoUrl != null
                    ? Image.network(
                        fullLogoUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          // Pendant le chargement, afficher les initiales
                          return Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: template.fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: _accent,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // En cas d'erreur, afficher les initiales
                          if (kDebugMode) {
                            print('⚠️ Erreur chargement logo: $error');
                          }
                          return Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: template.fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: _accent,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: template.fontSize + 4,
                            fontWeight: FontWeight.bold,
                            color: _accent,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Nom de l'entreprise
              Expanded(
                child: Text(
                  company.name,
                  style: TextStyle(
                    fontSize: template.fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),

          // Ligne 2: Informations de contact en ligne
          const SizedBox(height: 8),
          _buildCompanyInfoLine(company),
        ],
      ),
    );
  }

  /// Construit la ligne d'informations de contact de l'entreprise
  Widget _buildCompanyInfoLine(CompanyProfile company) {
    final infoStyle = TextStyle(
      fontSize: template.fontSize - 1,
      color: Colors.grey[800],
      fontWeight: FontWeight.w400,
    );

    final infoParts = <String>[];

    if (company.location?.isNotEmpty == true) {
      infoParts.add('${t('location')}: ${company.location}');
    }
    if (company.address.isNotEmpty) {
      infoParts.add('${t('address')}: ${company.address}');
    }
    if (company.phone?.isNotEmpty == true) {
      infoParts.add('${t('phone')}: ${company.phone}');
    }
    if (company.email?.isNotEmpty == true) {
      infoParts.add('${t('email')}: ${company.email}');
    }
    if (company.nuiRccm?.isNotEmpty == true) {
      infoParts.add('${t('nuiRccm')}: ${company.nuiRccm}');
    }

    return Text(
      infoParts.join(' • '),
      style: infoStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Informations de l'entreprise (nom, adresse, contacts, identifiants légaux)
  /// Utilisé dans les cartes Émetteur/Client — texte sombre sur fond blanc
  Widget buildCompanyHeader(
    BuildContext context, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    TextAlign textAlign = TextAlign.left,
  }) {
    final company = receipt.companyInfo;
    final infoStyle = TextStyle(
      fontSize: template.fontSize - 1,
      color: Colors.black87,
      fontWeight: FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        // Nom de l'entreprise
        Text(
          company.name,
          style: TextStyle(
            fontSize: template.fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: textAlign,
        ),
        // Adresse
        if (company.address.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(company.address, style: infoStyle, textAlign: textAlign),
        ],
        // Localisation
        if (company.location?.isNotEmpty == true) ...[
          const SizedBox(height: 3),
          Text(company.location!, style: infoStyle, textAlign: textAlign),
        ],
        // Téléphone
        if (company.phone?.isNotEmpty == true) ...[
          const SizedBox(height: 3),
          Text('${t('phone')}: ${company.phone}', style: infoStyle),
        ],
        // Email
        if (company.email?.isNotEmpty == true) ...[
          const SizedBox(height: 3),
          Text('${t('email')}: ${company.email}', style: infoStyle, textAlign: textAlign),
        ],
        // NUI / RCCM
        if (company.nuiRccm?.isNotEmpty == true) ...[
          const SizedBox(height: 3),
          Text('${t('nuiRccm')}: ${company.nuiRccm}', style: infoStyle, textAlign: textAlign),
        ],
      ],
    );
  }

  /// Titre "FACTURE" / "Facture Proforma" + badge de statut de paiement
  Widget buildTitleAndStatus(BuildContext context) {
    final isPaid = receipt.isFullyPaid;
    final badgeColor = isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    final badgeLabel = isPaid ? ReceiptTranslations.get('paid', language: receipt.language) : ReceiptTranslations.get('remaining', language: receipt.language);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                receipt.isProforma ? t('proformaInvoice') : t('invoice'),
                style: TextStyle(
                  fontSize: template.fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                receipt.saleNumber,
                style: TextStyle(
                  fontSize: template.fontSize,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              // Date et heure
              Text(
                '${t('date')}: ${receipt.saleDate.day.toString().padLeft(2, '0')}/'
                '${receipt.saleDate.month.toString().padLeft(2, '0')}/'
                '${receipt.saleDate.year}',
                style: TextStyle(
                  fontSize: template.fontSize - 1,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${t('time')}: ${receipt.saleDate.hour.toString().padLeft(2, '0')}:'
                '${receipt.saleDate.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: template.fontSize - 1,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: badgeColor, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: template.fontSize - 1,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Deux cartes côte à côte : Émetteur (gauche) et Client (droite)
  Widget buildClientVendorCards(BuildContext context) {
    // Si pas de client, ne rien afficher
    if (receipt.customer == null) {
      return const SizedBox.shrink();
    }

    final labelStyle = TextStyle(
      fontSize: template.fontSize + 1,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    final cardDecoration = BoxDecoration(
      color: const Color(0xFFFAFAFA),
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    );
    final infoStyle = TextStyle(fontSize: template.fontSize - 1, color: Colors.black87);

    Widget clientCard() {
      final c = receipt.customer!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.nom, style: infoStyle.copyWith(fontWeight: FontWeight.bold)),
          if (c.adresse?.isNotEmpty == true) ...[
            const SizedBox(height: 3),
            Text(c.adresse!, style: infoStyle),
          ],
          if (c.nui?.isNotEmpty == true) ...[
            const SizedBox(height: 3),
            Text('NUI: ${c.nui}', style: infoStyle),
          ],
          if (c.rccm?.isNotEmpty == true) ...[
            const SizedBox(height: 3),
            Text('RCCM: ${c.rccm}', style: infoStyle),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte Client uniquement (les infos émetteur sont dans l'en-tête)
          Expanded(
            child: Container(
              decoration: cardDecoration,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('customer'), style: labelStyle),
                  const SizedBox(height: 6),
                  clientCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit les informations de la vente
  Widget buildSaleInfo(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: template.headerFontSize,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final textStyle = TextStyle(
      fontSize: template.fontSize,
      color: Colors.black,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre du reçu
        Center(
          child: Text(
            receipt.isProforma ? t('proformaInvoice') : t('invoice'),
            style: headerStyle,
          ),
        ),

        // Indicateur de réimpression
        if (receipt.isReprint && receipt.reprintIndicator.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t('reprint'),
                style: TextStyle(
                  fontSize: template.fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Informations de base
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${t('saleNumber')}:', style: textStyle),
            Text(receipt.saleNumber, style: textStyle),
          ],
        ),
        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${t('date')}:', style: textStyle),
            Text(
              '${receipt.saleDate.day.toString().padLeft(2, '0')}/'
              '${receipt.saleDate.month.toString().padLeft(2, '0')}/'
              '${receipt.saleDate.year} '
              '${receipt.saleDate.hour.toString().padLeft(2, '0')}:'
              '${receipt.saleDate.minute.toString().padLeft(2, '0')}',
              style: textStyle,
            ),
          ],
        ),

        // Informations client si disponibles
        if (receipt.customer != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t('customer')}:', style: textStyle),
              Flexible(
                child: Text(
                  receipt.customer!.nom,
                  style: textStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          // Afficher NUI si renseigné
          if (receipt.customer!.nui?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NUI:', style: textStyle),
                Flexible(
                  child: Text(
                    receipt.customer!.nui!,
                    style: textStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
          // Afficher RCCM si renseigné
          if (receipt.customer!.rccm?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RCCM:', style: textStyle),
                Flexible(
                  child: Text(
                    receipt.customer!.rccm!,
                    style: textStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ],

        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${t('paymentMethod')}:', style: textStyle),
            Text(receipt.paymentMethod, style: textStyle),
          ],
        ),
      ],
    );
  }

  /// Construit la liste des articles
  Widget buildItemsList(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: template.fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final textStyle = TextStyle(
      fontSize: template.fontSize,
      color: Colors.black,
    );

    return Table(
      border: TableBorder.all(color: Colors.grey.shade400, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      children: [
        // En-tête du tableau
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(t('article'), style: headerStyle),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(t('quantity'), style: headerStyle, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(t('unitPrice'), style: headerStyle, textAlign: TextAlign.right),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(t('total'), style: headerStyle, textAlign: TextAlign.right),
            ),
          ],
        ),
        // Lignes articles avec zébrage
        ...receipt.items.asMap().entries.map((entry) => TableRow(
              decoration: BoxDecoration(
                color: entry.key.isEven ? _rowEven : _rowOdd,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.value.productName, style: textStyle),
                      if (entry.value.productReference.isNotEmpty)
                        Text(
                          '${t('reference')}: ${entry.value.productReference}',
                          style: TextStyle(
                            fontSize: template.fontSize - 1,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(entry.value.quantity.toString(), style: textStyle, textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(entry.value.formattedUnitPrice, style: textStyle, textAlign: TextAlign.right),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(entry.value.formattedTotalPrice, style: textStyle, textAlign: TextAlign.right),
                ),
              ],
            )),
      ],
    );
  }

  /// Construit le résumé des totaux
  Widget buildTotals(BuildContext context) {
    print('À [BUILD_TOTALS] tvaAmount=${receipt.tvaAmount}, tvaRate=${receipt.tvaRate}, subtotal=${receipt.subtotal}, total=${receipt.totalAmount}');
    final textStyle = TextStyle(
      fontSize: template.fontSize,
      color: Colors.black,
    );

    // Totaux alignés à droite dans un bloc de largeur fixe — identique au PDF imprimé
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 220,
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Sous-total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t('subtotal')}:', style: textStyle),
                Text('${receipt.subtotal.toStringAsFixed(0)} FCFA', style: textStyle),
              ],
            ),

            // Remise
            if (receipt.discountAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${t('discount')}:', style: textStyle),
                  Text('-${receipt.discountAmount.toStringAsFixed(0)} FCFA', style: textStyle),
                ],
              ),
            ],

            // TVA
            if (receipt.tvaAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TVA (${receipt.tvaRate % 1 == 0 ? receipt.tvaRate.toStringAsFixed(0) : receipt.tvaRate.toStringAsFixed(2)}%):', style: textStyle),
                  Text('+${receipt.tvaAmount.toStringAsFixed(0)} FCFA', style: textStyle),
                ],
              ),
            ],

            const Divider(thickness: 1, color: Colors.black),

            const SizedBox(height: 8),
            // Total — mis en valeur par un contour, pas un aplat plein
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _accent, width: 1.25),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${receipt.tvaAmount > 0 ? 'Total TTC' : t('totalAmount')}:',
                    style: TextStyle(
                      fontSize: template.fontSize + 3,
                      fontWeight: FontWeight.bold,
                      color: _accent,
                    ),
                  ),
                  Text(
                    '${receipt.totalAmount.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: template.fontSize + 3,
                      fontWeight: FontWeight.bold,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Payé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t('paid')}:', style: textStyle),
                Text('${receipt.paidAmount.toStringAsFixed(0)} FCFA', style: textStyle),
              ],
            ),

            // Monnaie rendue
            if (receipt.paidAmount > receipt.totalAmount) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${t('change')}:', style: textStyle),
                  Text(
                    '${(receipt.paidAmount - receipt.totalAmount).toStringAsFixed(0)} FCFA',
                    style: TextStyle(fontSize: template.fontSize, fontWeight: FontWeight.bold, color: Colors.green[700]),
                  ),
                ],
              ),
            ],

            // Reste à payer
            if (receipt.remainingAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${t('remaining')}:', style: textStyle),
                  Text(
                    '${receipt.remainingAmount.toStringAsFixed(0)} FCFA',
                    style: TextStyle(fontSize: template.fontSize, fontWeight: FontWeight.bold, color: Colors.red[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit le pied de page
  Widget buildFooter(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: template.fontSize - 1,
      color: Colors.black87,
    );

    return Column(
      children: [
        const SizedBox(height: 16),

        // Message de remerciement
        Center(
          child: Text(
            t('thankYou'),
            style: TextStyle(
              fontSize: template.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Informations de réimpression si applicable
        if (receipt.isReprint && receipt.lastReprintDate != null) ...[
          Center(
            child: Text(
              '${t('reprintedOn')} ${receipt.lastReprintDate!.day.toString().padLeft(2, '0')}/'
              '${receipt.lastReprintDate!.month.toString().padLeft(2, '0')}/'
              '${receipt.lastReprintDate!.year} à '
              '${receipt.lastReprintDate!.hour.toString().padLeft(2, '0')}:'
              '${receipt.lastReprintDate!.minute.toString().padLeft(2, '0')}',
              style: textStyle,
            ),
          ),
          if (receipt.reprintBy?.isNotEmpty == true)
            Center(
              child: Text(
                '${t('by')} ${receipt.reprintBy}',
                style: textStyle,
              ),
            ),
        ],
      ],
    );
  }
}
