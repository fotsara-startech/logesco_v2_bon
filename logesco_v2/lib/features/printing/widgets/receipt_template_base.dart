import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import '../utils/receipt_translations.dart';

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

  /// Obtient une traduction pour la langue du reçu
  String t(String key) {
    return ReceiptTranslations.get(key, language: receipt.language);
  }

  /// Construit l'en-tête avec les informations de l'entreprise
  Widget buildCompanyHeader(BuildContext context) {
    final company = receipt.companyInfo;
    final textStyle = TextStyle(
      fontSize: template.titleFontSize,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    final subtitleStyle = TextStyle(
      fontSize: template.fontSize,
      color: Colors.black87,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Nom de l'entreprise
        Text(
          company.name.toUpperCase(),
          style: textStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Adresse
        if (company.address.isNotEmpty)
          Text(
            company.address,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),

        // Localisation
        if (company.location?.isNotEmpty == true)
          Text(
            company.location!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),

        // Téléphone et Email sur la même ligne
        if (company.phone?.isNotEmpty == true || company.email?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (company.phone?.isNotEmpty == true) ...[
                  Text('${t('phone')}: ${company.phone}', style: subtitleStyle),
                  if (company.email?.isNotEmpty == true) Text(' | ', style: subtitleStyle),
                ],
                if (company.email?.isNotEmpty == true) Text('${t('email')}: ${company.email}', style: subtitleStyle),
              ],
            ),
          ),

        // NUI RCCM
        if (company.nuiRccm?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${t('nuiRccm')}: ${company.nuiRccm}',
              style: subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ),
      ],
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
            t('invoice'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du tableau
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black, width: 1),
              bottom: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(t('article'), style: headerStyle)),
              Expanded(flex: 1, child: Text(t('quantity'), style: headerStyle, textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text(t('unitPrice'), style: headerStyle, textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text(t('total'), style: headerStyle, textAlign: TextAlign.right)),
            ],
          ),
        ),

        // Articles
        ...receipt.items
            .map((item) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: textStyle),
                            if (item.productReference.isNotEmpty)
                              Text(
                                '${t('reference')}: ${item.productReference}',
                                style: TextStyle(
                                  fontSize: template.fontSize - 1,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item.quantity.toString(),
                          style: textStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.formattedUnitPrice,
                          style: textStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.formattedTotalPrice,
                          style: textStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),

        // Ligne de séparation
        Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  /// Construit le résumé des totaux
  Widget buildTotals(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: template.fontSize,
      color: Colors.black,
    );
    final boldStyle = TextStyle(
      fontSize: template.fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return Column(
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

        // Remise si applicable
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

        const SizedBox(height: 4),

        // Total avec ligne de séparation
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black, width: 1),
              bottom: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t('totalAmount')}:', style: boldStyle),
              Text('${receipt.totalAmount.toStringAsFixed(0)} FCFA', style: boldStyle),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Montant payé - TOUJOURS afficher
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${t('paid')}:', style: textStyle),
            Text('${receipt.paidAmount.toStringAsFixed(0)} FCFA', style: textStyle),
          ],
        ),

        // Monnaie (change) si applicable
        if (receipt.paidAmount > receipt.totalAmount) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t('change')}:', style: textStyle),
              Text(
                '${(receipt.paidAmount - receipt.totalAmount).toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: template.fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],

        // Reste à payer / Dette si applicable
        if (receipt.remainingAmount > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t('remaining')}:', style: textStyle),
              Text(
                '${receipt.remainingAmount.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: template.fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ],
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
