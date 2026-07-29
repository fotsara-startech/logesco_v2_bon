import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import 'receipt_template_base.dart';
import '../../../core/config/app_config.dart';

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
    final serverUrl = AppConfig.currentBaseUrl.replaceAll('/api/v1', '');
    final logoPath = receipt.companyInfo.logo;

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
            // Bandeau en-tête coloré avec logo ou initiales
            buildHeader(context, logoPath: logoPath, serverUrl: serverUrl),

            // Titre + badge de statut de paiement
            buildTitleAndStatus(context),

            // Cartes Émetteur / Client
            buildClientVendorCards(context),

            const SizedBox(height: 16),

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

  /// Construit les informations légales en bas de page
  Widget _buildLegalInfo(BuildContext context) {
    final company = receipt.companyInfo;
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
          // Slogan de l'entreprise (si disponible)
          if (company.slogan != null && company.slogan!.isNotEmpty) ...[
            Text(
              company.slogan!,
              style: TextStyle(
                fontSize: template.fontSize,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          // Informations de contact supplémentaires
          if (company.email?.isNotEmpty == true || company.phone?.isNotEmpty == true)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (company.phone?.isNotEmpty == true) Text('Tél: ${company.phone}', style: textStyle),
                if (company.email?.isNotEmpty == true && company.phone?.isNotEmpty == true) Text(' À ', style: textStyle),
                if (company.email?.isNotEmpty == true) Text('Email: ${company.email}', style: textStyle),
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
