import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import 'receipt_template_base.dart';

/// Template de reçu pour imprimante thermique (80mm)
class ReceiptTemplateThermal extends ReceiptTemplateBase {
  const ReceiptTemplateThermal({
    Key? key,
    required Receipt receipt,
    required print_models.PrintTemplate template,
    bool showPreview = false,
  }) : super(
          key: key,
          receipt: receipt,
          template: template,
          showPreview: showPreview,
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: template.format.widthPoints,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          template.margins.left,
          template.margins.top,
          template.margins.right,
          template.margins.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête thermique
            _buildThermalHeader(context),

            _buildSeparator(),

            // Informations de la vente
            _buildThermalSaleInfo(context),

            _buildSeparator(),

            // Liste des articles (version thermique)
            _buildThermalItemsList(context),

            _buildSeparator(),

            // Totaux
            _buildThermalTotals(context),

            _buildSeparator(),

            // Pied de page thermique
            _buildThermalFooter(context),

            // Espace final pour la coupe
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Construit un en-tête optimisé pour imprimante thermique
  Widget _buildThermalHeader(BuildContext context) {
    final company = receipt.companyInfo;
    final titleStyle = TextStyle(
      fontSize: template.titleFontSize,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final subtitleStyle = TextStyle(
      fontSize: template.fontSize + 1,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final textStyle = TextStyle(
      fontSize: template.fontSize,
      color: Colors.black,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo placeholder (optionnel)
        // SizedBox(height: 20, child: Placeholder()),

        // Nom de l'entreprise (centré et en gras)
        Text(
          company.name.toUpperCase(),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        // Adresse
        if (company.address.isNotEmpty)
          Text(
            company.address,
            style: textStyle,
            textAlign: TextAlign.center,
          ),

        // Localisation
        if (company.location?.isNotEmpty == true)
          Text(
            company.location!,
            style: textStyle,
            textAlign: TextAlign.center,
          ),

        // Téléphone
        if (company.phone?.isNotEmpty == true)
          Text(
            'Tel: ${company.phone}',
            style: textStyle,
            textAlign: TextAlign.center,
          ),

        // NUI RCCM
        if (company.nuiRccm?.isNotEmpty == true)
          Text(
            'NUI: ${company.nuiRccm}',
            style: textStyle,
            textAlign: TextAlign.center,
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  /// Construit les informations de vente pour thermique
  Widget _buildThermalSaleInfo(BuildContext context) {
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Titre du reçu
        Text(
          'Recu de vente',
          style: headerStyle,
          textAlign: TextAlign.center,
        ),

        // Indicateur de réimpression
        if (receipt.isReprint && receipt.reprintIndicator.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              receipt.reprintIndicator,
              style: TextStyle(
                fontSize: template.fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 8),

        // Informations de base (alignées à gauche)
        Container(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('N° Vente: ${receipt.saleNumber}', style: textStyle),
              Text('Date: ${receipt.saleDate.day.toString().padLeft(2, '0')}/${receipt.saleDate.month.toString().padLeft(2, '0')}/${receipt.saleDate.year}', style: textStyle),
              Text('Heure: ${receipt.saleDate.hour.toString().padLeft(2, '0')}:${receipt.saleDate.minute.toString().padLeft(2, '0')}', style: textStyle),
              if (receipt.customer != null) Text('Client: ${_truncateText(receipt.customer!.nom, 15)}', style: textStyle),
              Text('Paiement: ${receipt.paymentMethod}', style: textStyle),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit la liste d'articles pour thermique
  Widget _buildThermalItemsList(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: template.fontSize,
      color: Colors.black,
    );
    final smallStyle = TextStyle(
      fontSize: template.fontSize - 1,
      color: Colors.black87,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête simple
        Text(
          'ARTICLES:',
          style: TextStyle(
            fontSize: template.fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 4),

        // Articles (format vertical compact)
        ...receipt.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final ref = item.productReference.isNotEmpty ? ' (${item.productReference})' : '';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom du produit avec référence sur la même ligne
                Text(
                  '${index + 1}. ${_truncateText(item.productName, 20)}$ref',
                  style: textStyle,
                ),

                // Affichage avec prix original si remise appliquée
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.hasDiscount) ...[
                        // Prix original
                        Text(
                          '${item.quantity} x ${item.displayPrice.toStringAsFixed(0)} FCFA = ${(item.displayPrice * item.quantity).toStringAsFixed(0)} FCFA',
                          style: smallStyle,
                        ),
                        // Remise appliquée
                        Text(
                          'Remise: -${item.totalDiscountAmount.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: template.fontSize - 1,
                            color: Colors.green[600],
                          ),
                        ),
                        // Prix payé
                        Text(
                          'Prix payé: ${item.formattedTotalPrice}',
                          style: TextStyle(
                            fontSize: template.fontSize - 1,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ] else ...[
                        // Pas de remise, affichage normal
                        Text(
                          '${item.quantity} x ${item.formattedUnitPrice} = ${item.formattedTotalPrice}',
                          style: smallStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Construit les totaux pour thermique - AMÉLIORÉ
  Widget _buildThermalTotals(BuildContext context) {
    // Calculer la remise totale depuis les items
    double totalDiscountFromItems = 0.0;
    for (var item in receipt.items) {
      // Calculer la remise de cet item
      double expectedTotal = item.quantity * item.unitPrice;
      double actualTotal = item.totalPrice;
      double itemDiscount = expectedTotal - actualTotal;

      if (itemDiscount > 0) {
        totalDiscountFromItems += itemDiscount;
      }
    }

    // Utiliser la remise calculée si receipt.discountAmount est 0
    double actualDiscountAmount = receipt.discountAmount;
    if (actualDiscountAmount == 0 && totalDiscountFromItems > 0) {
      actualDiscountAmount = totalDiscountFromItems;
    }

    // Calculer le sous-total correct
    double correctSubtotal = receipt.totalAmount + actualDiscountAmount;

    final textStyle = TextStyle(
      fontSize: template.fontSize,
      color: Colors.black,
    );
    final boldStyle = TextStyle(
      fontSize: template.fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    // DEBUG - Afficher les valeurs pour diagnostic
    print('🖨️ [THERMAL_TOTALS] Calcul des totaux:');
    print('🖨️ [THERMAL_TOTALS] Total: ${receipt.totalAmount}');
    print('🖨️ [THERMAL_TOTALS] Payé: ${receipt.paidAmount}');
    print('🖨️ [THERMAL_TOTALS] Reste: ${receipt.remainingAmount}');
    print('🖨️ [THERMAL_TOTALS] Monnaie calculée: ${receipt.paidAmount > receipt.totalAmount ? (receipt.paidAmount - receipt.totalAmount) : 0}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sous-total (aligné à gauche)
        Text('Sous-total: ${correctSubtotal.toStringAsFixed(0)} FCFA', style: textStyle),

        // Remise si applicable
        if (actualDiscountAmount > 0) Text('Remise: -${actualDiscountAmount.toStringAsFixed(0)} FCFA', style: TextStyle(fontSize: template.fontSize, color: Colors.green[600])),

        // Ligne de séparation
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '--------------------------------',
            style: TextStyle(fontSize: template.fontSize - 1),
          ),
        ),

        // Total
        Text('TOTAL: ${receipt.totalAmount.toStringAsFixed(0)} FCFA', style: boldStyle),

        // Montant payé - TOUJOURS afficher avec formatage amélioré
        Text('Paye: ${receipt.paidAmount.toStringAsFixed(0)} FCFA', style: textStyle),

        // Monnaie (change) si applicable - CORRECTION LOGIQUE
        if (receipt.paidAmount > receipt.totalAmount) ...[
          Text(
            'Monnaie: ${(receipt.paidAmount - receipt.totalAmount).toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: template.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],

        // Reste à payer / Dette si applicable - CORRECTION LOGIQUE
        if (receipt.remainingAmount > 0) ...[
          Text(
            'Reste: ${receipt.remainingAmount.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: template.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
        ],
      ],
    );
  }

  /// Construit le pied de page pour thermique
  Widget _buildThermalFooter(BuildContext context) {
    final smallStyle = TextStyle(
      fontSize: template.fontSize - 0.5,
      color: Colors.black87,
    );

    return Column(
      children: [
        const SizedBox(height: 6),

        // Informations de réimpression si applicable
        if (receipt.isReprint && receipt.lastReprintDate != null) ...[
          Text(
            'Reimprime le ${receipt.lastReprintDate!.day.toString().padLeft(2, '0')}/'
            '${receipt.lastReprintDate!.month.toString().padLeft(2, '0')}/'
            '${receipt.lastReprintDate!.year}',
            style: smallStyle,
            textAlign: TextAlign.center,
          ),
          if (receipt.reprintBy?.isNotEmpty == true)
            Text(
              'par ${receipt.reprintBy}',
              style: smallStyle,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),
        ],

        // Message de remerciement personnalisé
        Text(
          'Merci pour votre confiance !',
          style: TextStyle(
            fontSize: template.fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Construit un séparateur pour thermique
  Widget _buildSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '================================',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: template.fontSize - 1),
      ),
    );
  }

  /// Tronque le texte si trop long
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
