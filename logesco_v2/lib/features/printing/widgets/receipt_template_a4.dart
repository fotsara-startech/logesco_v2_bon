import 'dart:io';
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
    final company = receipt.companyInfo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: template.showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo à gauche (si disponible)
          if (template.showLogo && company.logo != null && company.logo!.isNotEmpty)
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(company.logo!),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Si l'image ne peut pas être chargée, afficher un placeholder
                    return const Center(
                      child: Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            )
          else if (template.showLogo)
            // Placeholder si pas de logo configuré
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'LOGO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),

          // Informations de l'entreprise à droite
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                buildCompanyHeader(context),
              ],
            ),
          ),
        ],
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
                if (company.email?.isNotEmpty == true && company.phone?.isNotEmpty == true) Text(' • ', style: textStyle),
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
