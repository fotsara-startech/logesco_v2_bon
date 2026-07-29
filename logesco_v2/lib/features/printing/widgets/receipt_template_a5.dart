import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import 'receipt_template_base.dart';
import '../../../core/config/app_config.dart';

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
            // Bandeau en-tête coloré (logo 48x48 adapté A5)
            buildHeader(context, logoPath: logoPath, serverUrl: serverUrl),

            // Titre + badge statut
            buildTitleAndStatus(context),

            // Cartes Émetteur / Client (empilées verticalement pour A5)
            _buildCompactClientVendorCards(context),

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

  /// Cartes Émetteur/Client empilées verticalement pour le format A5
  Widget _buildCompactClientVendorCards(BuildContext context) {
    // Si pas de client, ne rien afficher
    if (receipt.customer == null) {
      return const SizedBox.shrink();
    }

    final labelStyle = TextStyle(
      fontSize: template.fontSize,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    final cardDecoration = BoxDecoration(
      color: const Color(0xFFFAFAFA),
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(6),
    );

    Widget clientInfo() {
      final c = receipt.customer!;
      final infoStyle = TextStyle(fontSize: template.fontSize - 1, color: Colors.black87);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.nom, style: infoStyle.copyWith(fontWeight: FontWeight.bold)),
          if (c.adresse?.isNotEmpty == true) ...[const SizedBox(height: 2), Text(c.adresse!, style: infoStyle)],
          if (c.nui?.isNotEmpty == true) ...[const SizedBox(height: 2), Text('NUI: ${c.nui}', style: infoStyle)],
          if (c.rccm?.isNotEmpty == true) ...[const SizedBox(height: 2), Text('RCCM: ${c.rccm}', style: infoStyle)],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: cardDecoration,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('customer'), style: labelStyle),
            const SizedBox(height: 4),
            clientInfo(),
          ],
        ),
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
