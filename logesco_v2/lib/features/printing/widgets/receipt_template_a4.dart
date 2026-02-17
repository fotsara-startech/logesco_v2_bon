import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import 'receipt_template_base.dart';

/// Template de reçu pour format A4
class ReceiptTemplateA4 extends ReceiptTemplateBase {
  const ReceiptTemplateA4({
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
      height: showPreview ? null : template.format.heightPoints,
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
          children: [
            // En-tête avec logo et informations entreprise
            _buildHeader(context),

            const SizedBox(height: 24),

            // Informations de la vente
            buildSaleInfo(context),

            const SizedBox(height: 20),

            // Liste des articles
            buildItemsList(context),

            const SizedBox(height: 16),

            // Totaux
            buildTotals(context),

            // Spacer pour pousser le footer vers le bas
            if (!showPreview) const Spacer(),

            // Pied de page
            buildFooter(context),

            // Informations légales et contact
            _buildLegalInfo(context),
          ],
        ),
      ),
    );
  }

  /// Construit l'en-tête avec logo et bordure décorative
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: template.showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        children: [
          // Logo placeholder (si activé)
          if (template.showLogo) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Informations de l'entreprise
          buildCompanyHeader(context),
        ],
      ),
    );
  }

  /// Construit les informations légales en bas de page
  Widget _buildLegalInfo(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: template.fontSize - 2,
      color: Colors.grey[600],
    );

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Informations de contact supplémentaires
          if (receipt.companyInfo.email?.isNotEmpty == true || receipt.companyInfo.phone?.isNotEmpty == true)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (receipt.companyInfo.phone?.isNotEmpty == true) Text('Tél: ${receipt.companyInfo.phone}', style: textStyle),
                if (receipt.companyInfo.email?.isNotEmpty == true && receipt.companyInfo.phone?.isNotEmpty == true) Text(' • ', style: textStyle),
                if (receipt.companyInfo.email?.isNotEmpty == true) Text('Email: ${receipt.companyInfo.email}', style: textStyle),
              ],
            ),

          const SizedBox(height: 8),

          // Informations du système
          Center(
            child: Text(
              'Document généré par Logesco V2 - ${DateTime.now().day.toString().padLeft(2, '0')}/'
              '${DateTime.now().month.toString().padLeft(2, '0')}/'
              '${DateTime.now().year}',
              style: textStyle,
            ),
          ),

          // Code QR placeholder pour version future
          if (template.customSettings['showQrCode'] == true) ...[
            const SizedBox(height: 12),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: const Icon(
                Icons.qr_code,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
