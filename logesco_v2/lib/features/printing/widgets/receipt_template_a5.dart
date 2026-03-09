import 'dart:io';
import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import 'receipt_template_base.dart';

/// Template de reçu pour format A5
class ReceiptTemplateA5 extends ReceiptTemplateBase {
  const ReceiptTemplateA5({
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
            // En-tête compact
            _buildCompactHeader(context),

            const SizedBox(height: 16),

            // Informations de la vente
            buildSaleInfo(context),

            const SizedBox(height: 12),

            // Liste des articles
            buildItemsList(context),

            const SizedBox(height: 12),

            // Totaux
            buildTotals(context),

            // Spacer pour pousser le footer vers le bas
            if (!showPreview) const Spacer(),

            // Pied de page
            buildFooter(context),

            // Informations légales compactes
            _buildCompactLegalInfo(context),
          ],
        ),
      ),
    );
  }

  /// Construit un en-tête compact pour A5
  Widget _buildCompactHeader(BuildContext context) {
    final company = receipt.companyInfo;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: template.showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Column(
        children: [
          // Logo plus petit si activé et disponible
          if (template.showLogo && company.logo != null && company.logo!.isNotEmpty) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(company.logo!),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.business,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else if (template.showLogo) ...[
            // Placeholder si pas de logo configuré
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.business,
                size: 30,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Informations de l'entreprise
          buildCompanyHeader(context),
        ],
      ),
    );
  }

  /// Construit les informations légales compactes
  Widget _buildCompactLegalInfo(BuildContext context) {
    final company = receipt.companyInfo;
    final textStyle = TextStyle(
      fontSize: template.fontSize - 2,
      color: Colors.grey[600],
    );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(top: 8),
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
                fontSize: template.fontSize - 1,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          // Informations du système
          Center(
            child: Text(
              'Logesco V2 - ${DateTime.now().day.toString().padLeft(2, '0')}/'
              '${DateTime.now().month.toString().padLeft(2, '0')}/'
              '${DateTime.now().year}',
              style: textStyle,
            ),
          ),

          // Code QR plus petit si activé
          if (template.customSettings['showQrCode'] == true) ...[
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: const Icon(
                Icons.qr_code,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
