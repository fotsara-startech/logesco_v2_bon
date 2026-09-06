import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;
import '../controllers/printing_controller.dart';
import '../models/models.dart';
import '../widgets/receipt_template_factory.dart';
import '../utils/receipt_translations.dart';
import '../utils/amount_in_words.dart';
import '../../../core/config/app_config.dart';

// Imports pour l'impression réelle
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

/// Page de prévisualisation des reçus
class ReceiptPreviewPage extends StatelessWidget {
  const ReceiptPreviewPage({super.key});

  /// Helper pour obtenir les traductions selon la langue du reçu
  String _t(String key, Receipt receipt) {
    return ReceiptTranslations.get(key, language: receipt.language);
  }

  @override
  Widget build(BuildContext context) {
    final PrintingController controller = Get.find<PrintingController>();

    // Récupérer le reçu depuis les arguments
    final Receipt? receipt = Get.arguments as Receipt?;

    if (receipt == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('preview_title'.tr),
        ),
        body: Center(
          child: Text('preview_no_receipt'.tr),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('preview_title'.tr),
        actions: [
          Obx(() => IconButton(
                onPressed: controller.isGenerating ? null : () => _printReceipt(controller, receipt),
                icon: controller.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                tooltip: 'preview_tooltip_print'.tr,
              )),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de format
          _buildFormatSelector(controller),

          // Prévisualisation
          Expanded(
            child: _buildPreview(controller, receipt),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, controller, receipt),
    );
  }

  Widget _buildFormatSelector(PrintingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('preview_print_format'.tr, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Obx(() => SegmentedButton<PrintFormat>(
                segments: [
                  ButtonSegment(value: PrintFormat.thermal, label: Text('preview_format_thermal'.tr), icon: const Icon(Icons.receipt, size: 18)),
                  ButtonSegment(value: PrintFormat.a5, label: Text('preview_format_a5'.tr), icon: const Icon(Icons.description, size: 18)),
                  ButtonSegment(value: PrintFormat.a4, label: Text('preview_format_a4'.tr), icon: const Icon(Icons.article, size: 18)),
                  ButtonSegment(value: PrintFormat.matriciel, label: Text('preview_format_matriciel'.tr), icon: const Icon(Icons.print, size: 18)),
                ],
                selected: {controller.selectedFormat},
                onSelectionChanged: (Set<PrintFormat> selection) {
                  if (selection.isNotEmpty) controller.setSelectedFormat(selection.first);
                },
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPreview(PrintingController controller, Receipt receipt) {
    return Obx(() {
      final format = controller.selectedFormat;
      final previewWidth = _getPreviewWidth(format);

      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: previewWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final templateWidth = format == PrintFormat.thermal
                      ? 226.77
                      : format == PrintFormat.a5
                          ? 421.0
                          : 595.0; // points PDF

                  final scale = constraints.maxWidth / templateWidth;

                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: templateWidth,
                      child: ReceiptTemplateFactory.createPreview(
                        receipt: receipt,
                        format: format,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  double _getPreviewWidth(PrintFormat format) {
    switch (format) {
      case PrintFormat.thermal:
        return 300;
      case PrintFormat.a5:
        return 380;
      case PrintFormat.a4:
        return 480;
      case PrintFormat.matriciel:
        return 520;
    }
  }

  Widget _buildBottomBar(BuildContext context, PrintingController controller, Receipt receipt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // Informations du reçu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${'preview_receipt_label'.tr} ${receipt.saleNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${'preview_total_label'.tr}: ${receipt.totalAmount.toStringAsFixed(2)} FCFA',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),

          // Boutons d'action
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
            label: Text('preview_close'.tr),
          ),
          const SizedBox(width: 8),
          Obx(() => ElevatedButton.icon(
                onPressed: controller.isGenerating ? null : () => _printReceipt(controller, receipt),
                icon: controller.isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.print),
                label: Text(controller.isGenerating ? 'preview_printing'.tr : 'preview_print'.tr),
              )),
        ],
      ),
    );
  }

  Future<void> _printReceipt(PrintingController controller, Receipt receipt) async {
    try {
      // S'assurer que le reçu est défini dans le contrôleur
      controller.selectReceipt(receipt);

      // Imprimer directement
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return await _generatePdf(controller.selectedFormat, receipt);
        },
        name: 'Reçu_${receipt.saleNumber}.pdf',
      );

      SnackbarHelper.success('preview_print_success_msg'.tr, title: 'preview_print_success_title'.tr, duration: const Duration(seconds: 2));
    } catch (e) {
      SnackbarHelper.error('${'preview_print_error_msg'.tr}: $e', duration: const Duration(seconds: 4));
    }
  }

  Future<Uint8List> _generatePdf(PrintFormat format, Receipt receipt) async {
    final pdfDoc = pw.Document();

    // Télécharger le logo si disponible
    Uint8List? logoBytes;
    if (receipt.companyInfo.logo != null && receipt.companyInfo.logo!.isNotEmpty) {
      logoBytes = await _downloadLogo(receipt.companyInfo.logo!);
    }

    // Définir le format de page exact
    PdfPageFormat pageFormat;
    switch (format) {
      case PrintFormat.a4:
        pageFormat = PdfPageFormat.a4;
        break;
      case PrintFormat.a5:
        pageFormat = PdfPageFormat.a5;
        break;
      case PrintFormat.thermal:
        pageFormat = const PdfPageFormat(226.77, 841.89); // 80mm x 297mm
        break;
      case PrintFormat.matriciel:
        // Papier continu à picots, largeur "A4" (~210mm / 80 colonnes à 10 cpi).
        // Hauteur généreuse et fixe (comme pour le thermique ci-dessus) plutôt
        // que multi-pages : suffisant pour une facture classique.
        pageFormat = const PdfPageFormat(595.28, 2834.65); // 210mm x 1000mm
        break;
    }

    // Marges : les imprimantes (matricielles en particulier) ont une zone
    // non imprimable réelle près des bords, souvent plus large que ce
    // qu'indique la taille de page nominale — d'où un bord droit rogné si
    // la marge logique est trop fine. On garde une marge généreuse pour
    // le matriciel plutôt que la marge très fine du thermique (qui, lui,
    // imprime sur un rouleau sans cette contrainte de picots/traction).
    final pw.EdgeInsets margin;
    if (format == PrintFormat.thermal) {
      margin = const pw.EdgeInsets.all(8.0);
    } else if (format == PrintFormat.matriciel) {
      margin = const pw.EdgeInsets.all(20.0);
    } else {
      margin = const pw.EdgeInsets.all(40.0);
    }

    // Ajouter une page avec le contenu
    pdfDoc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: margin,
        build: (pw.Context context) {
          return _buildPdfContent(receipt, format, logoBytes); // Passer le logo
        },
      ),
    );

    return pdfDoc.save();
  }

  /// Télécharge le logo depuis le backend
  Future<Uint8List?> _downloadLogo(String logoPath) async {
    try {
      // Vérifier si c'est un chemin complet ou juste un nom de fichier
      if (logoPath.contains('\\') || logoPath.contains('/') || logoPath.contains(':')) {
        // Si c'est une URL complète
        if (logoPath.startsWith('http')) {
          print('️ Téléchargement du logo depuis URL: $logoPath');
          final response = await http.get(Uri.parse(logoPath)).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⚠️ Timeout lors du chargement du logo');
              throw Exception('Timeout');
            },
          );

          if (response.statusCode == 200) {
            print(' Logo téléchargé (${response.bodyBytes.length} bytes)');
            return response.bodyBytes;
          } else {
            print('⚠️ Erreur HTTP ${response.statusCode} lors du chargement du logo');
          }
        } else {
          // C'est un chemin complet local, essayer de le charger
          final file = File(logoPath);
          if (file.existsSync()) {
            return file.readAsBytesSync();
          }
        }
      } else {
        // C'est juste un nom de fichier, le télécharger depuis le backend
        print('️ Téléchargement du logo depuis le backend: $logoPath');

        final baseUrl = AppConfig.currentBaseUrl;
        final serverUrl = baseUrl.replaceAll('/api/v1', '');

        // Construire l'URL en fonction du format du logoPath
        String logoUrl;
        if (logoPath.startsWith('uploads/')) {
          logoUrl = '$serverUrl/$logoPath';
        } else {
          logoUrl = '$serverUrl/uploads/$logoPath';
        }

        print('   URL du logo: $logoUrl');

        final response = await http.get(Uri.parse(logoUrl)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Timeout lors du chargement du logo');
            throw Exception('Timeout');
          },
        );

        if (response.statusCode == 200) {
          print(' Logo téléchargé (${response.bodyBytes.length} bytes)');
          return response.bodyBytes;
        } else {
          print('⚠️ Erreur HTTP ${response.statusCode} lors du chargement du logo');
        }
      }
    } catch (e) {
      print('⚠️ Erreur téléchargement logo: $e');
    }
    return null;
  }

  // Méthodes pour l'impression réelle
  pw.Widget _buildPdfContent(Receipt receipt, PrintFormat selectedFormat, Uint8List? logoBytes) {
    // Utiliser le format sélectionné par l'utilisateur, pas celui du reçu
    final isTherm = selectedFormat == PrintFormat.thermal;

    // Si c'est thermique, utiliser l'ancien format
    if (isTherm) {
      return _buildThermalContent(receipt, logoBytes);
    }

    if (selectedFormat == PrintFormat.matriciel) {
      return _buildMatricielContent(receipt);
    }

    // Pour A4/A5, utiliser le nouveau format qui correspond à l'aperçu
    return _buildA4A5Content(receipt, selectedFormat, logoBytes);
  }

  // Format thermique (ancien format)
  pw.Widget _buildThermalContent(Receipt receipt, Uint8List? logoBytes) {
    final fontSize = 8.5;
    final titleSize = 11.5;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo si disponible
        if (logoBytes != null)
          pw.Center(
            child: pw.Container(
              width: 60,
              height: 60,
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Image(
                pw.MemoryImage(logoBytes),
                fit: pw.BoxFit.contain,
              ),
            ),
          ),

        // En-tête entreprise
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                receipt.companyInfo.name.toUpperCase(),
                style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              if (receipt.companyInfo.address.isNotEmpty) pw.Text(receipt.companyInfo.address, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center),
              if (receipt.companyInfo.location?.isNotEmpty == true) pw.Text(receipt.companyInfo.location!, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center),
              if (receipt.companyInfo.phone?.isNotEmpty == true)
                pw.Text('${_t('phone', receipt)}: ${receipt.companyInfo.phone}', style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center),
              if (receipt.companyInfo.nuiRccm?.isNotEmpty == true)
                pw.Text('${_t('nuiRccm', receipt)}: ${receipt.companyInfo.nuiRccm}', style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('================================', style: pw.TextStyle(fontSize: fontSize - 1))),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            receipt.isProforma ? _t('proformaInvoice', receipt).toUpperCase() : _t('invoice', receipt).toUpperCase(),
            style: pw.TextStyle(fontSize: titleSize - 2, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('${_t('saleNumber', receipt)}:  ${receipt.saleNumber}', style: pw.TextStyle(fontSize: fontSize)),
        pw.Text(
            '${_t('date', receipt)}:  ${receipt.saleDate.day.toString().padLeft(2, '0')}/'
            '${receipt.saleDate.month.toString().padLeft(2, '0')}/'
            '${receipt.saleDate.year}',
            style: pw.TextStyle(fontSize: fontSize)),
        pw.Text(
            'Heure:  ${receipt.saleDate.hour.toString().padLeft(2, '0')}:'
            '${receipt.saleDate.minute.toString().padLeft(2, '0')}',
            style: pw.TextStyle(fontSize: fontSize)),
        if (receipt.customer != null) ...[
          pw.Text('${_t('customer', receipt)}:  ${receipt.customer!.nom}', style: pw.TextStyle(fontSize: fontSize)),
          // Afficher NUI si renseigné
          if (receipt.customer!.nui?.isNotEmpty == true) pw.Text('NUI:  ${receipt.customer!.nui}', style: pw.TextStyle(fontSize: fontSize)),
          // Afficher RCCM si renseigné
          if (receipt.customer!.rccm?.isNotEmpty == true) pw.Text('RCCM:  ${receipt.customer!.rccm}', style: pw.TextStyle(fontSize: fontSize)),
        ],
        pw.Text('${_t('paymentMethod', receipt)}:  ${receipt.paymentMethod}', style: pw.TextStyle(fontSize: fontSize)),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('================================', style: pw.TextStyle(fontSize: fontSize - 1))),
        pw.SizedBox(height: 10),
        pw.Text('${_t('article', receipt).toUpperCase()}S:', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        ...receipt.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${index + 1}. ${item.productName}', style: pw.TextStyle(fontSize: fontSize)),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8),
                  child: pw.Text(
                    '${item.quantity} x ${item.formattedUnitPrice} = ${item.formattedTotalPrice}',
                    style: pw.TextStyle(fontSize: fontSize - 0.5),
                  ),
                ),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('================================', style: pw.TextStyle(fontSize: fontSize - 1))),
        pw.SizedBox(height: 5),
        pw.Text('${_t('subtotal', receipt)}: ${receipt.subtotal.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
        if (receipt.discountAmount > 0) pw.Text('${_t('discount', receipt)}: -${receipt.discountAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
        if (receipt.tvaAmount > 0)
          pw.Text('TVA (${receipt.tvaRate % 1 == 0 ? receipt.tvaRate.toStringAsFixed(0) : receipt.tvaRate.toStringAsFixed(2)}%): +${receipt.tvaAmount.toStringAsFixed(0)} FCFA',
              style: pw.TextStyle(fontSize: fontSize)),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text('--------------------------------', style: pw.TextStyle(fontSize: fontSize - 1))),
        pw.SizedBox(height: 4),
        pw.Text('${receipt.tvaAmount > 0 ? 'Total TTC' : _t('totalAmount', receipt)}: ${receipt.totalAmount.toStringAsFixed(0)} FCFA',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)),
        pw.Text('${_t('paid', receipt)}: ${receipt.paidAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
        if (receipt.remainingAmount > 0)
          pw.Text('${_t('remaining', receipt)}: ${receipt.remainingAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('================================', style: pw.TextStyle(fontSize: fontSize - 1))),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              // Slogan si disponible
              if (receipt.companyInfo.slogan != null && receipt.companyInfo.slogan!.isNotEmpty) ...[
                pw.Text(
                  receipt.companyInfo.slogan!,
                  style: pw.TextStyle(fontSize: fontSize, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
                pw.SizedBox(height: 6),
              ],
              pw.Text('${_t('thankYou', receipt)}', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }

  // Format A4/A5 - aligné sur le design de l'aperçu Flutter
  pw.Widget _buildA4A5Content(Receipt receipt, PrintFormat format, Uint8List? logoBytes) {
    final company = receipt.companyInfo;
    final fontSize = format == PrintFormat.a5 ? 9.0 : 10.0;
    // Couleur d'accent utilisée en texte/bordures fines — plus d'aplats pleins
    // (bandeau, encart total) : certains clients impriment beaucoup de
    // factures et les gros blocs de couleur pleine consommaient trop d'encre.
    const accent = PdfColor.fromInt(0xFF1565C0);
    const rowOdd = PdfColor.fromInt(0xFFF5F7FA);

    // Initiales de l'entreprise (repli si pas de logo)
    final initials = company.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    // ── 1. Bandeau en-tête coloré avec ligne d'infos ──────────────────────
    // Créer la ligne d'informations
    final infoParts = <String>[];
    if (company.location?.isNotEmpty == true) infoParts.add('${_t('location', receipt)}: ${company.location}');
    if (company.address.isNotEmpty) infoParts.add('${_t('address', receipt)}: ${company.address}');
    if (company.phone?.isNotEmpty == true) infoParts.add('${_t('phone', receipt)}: ${company.phone}');
    if (company.email?.isNotEmpty == true) infoParts.add('${_t('email', receipt)}: ${company.email}');
    if (company.nuiRccm?.isNotEmpty == true) infoParts.add('${_t('nuiRccm', receipt)}: ${company.nuiRccm}');

    final header = pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accent, width: 1.5)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: pw.Column(
        children: [
          // Ligne 1: Logo + Nom
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Encart logo/initiales (contour fin, pas d'aplat)
              pw.Container(
                width: 48,
                height: 48,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: accent, width: 0.75),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                alignment: pw.Alignment.center,
                child: logoBytes != null
                    ? pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain, width: 44, height: 44)
                    : pw.Text(
                        initials,
                        style: pw.TextStyle(fontSize: fontSize + 4, fontWeight: pw.FontWeight.bold, color: accent),
                      ),
              ),
              pw.SizedBox(width: 12),
              // Nom de l'entreprise
              pw.Expanded(
                child: pw.Text(
                  company.name,
                  style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold, color: accent),
                ),
              ),
            ],
          ),
          // Ligne 2: Informations de contact avec séparateur pipe
          if (infoParts.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 6,
              runSpacing: 2,
              children: infoParts.asMap().entries.map((entry) {
                final isLast = entry.key == infoParts.length - 1;
                return pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      entry.value,
                      style: pw.TextStyle(fontSize: fontSize - 1, color: PdfColors.grey800),
                    ),
                    if (!isLast)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 3),
                        child: pw.Text(
                          '|',
                          style: pw.TextStyle(fontSize: fontSize - 1, color: PdfColors.grey400),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

    // ── 2. Titre + badge statut + date/heure ──────────────────────────────────────────────
    final isPaid = receipt.isFullyPaid;
    final badgeColor = isPaid ? const PdfColor.fromInt(0xFF4CAF50) : const PdfColor.fromInt(0xFFFF9800);
    final badgeLabel = isPaid ? _t('paid', receipt) : _t('remaining', receipt);

    final titleRow = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                receipt.isProforma ? _t('proformaInvoice', receipt) : _t('invoice', receipt),
                style: pw.TextStyle(fontSize: fontSize + 4, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              ),
              pw.SizedBox(height: 2),
              pw.Text(receipt.saleNumber, style: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              // Date
              pw.Text(
                '${_t('date', receipt)}: ${receipt.saleDate.day.toString().padLeft(2, '0')}/${receipt.saleDate.month.toString().padLeft(2, '0')}/${receipt.saleDate.year}',
                style: pw.TextStyle(fontSize: fontSize - 1, color: PdfColors.black),
              ),
              pw.SizedBox(height: 1),
              // Heure
              pw.Text(
                '${_t('time', receipt)}: ${receipt.saleDate.hour.toString().padLeft(2, '0')}:${receipt.saleDate.minute.toString().padLeft(2, '0')}',
                style: pw.TextStyle(fontSize: fontSize - 1, color: PdfColors.black),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: badgeColor, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Text(badgeLabel, style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold, color: badgeColor)),
          ),
        ],
      ),
    );

    // ── 3. Carte Client uniquement (masquée si pas de client) ────────────────────────────────────────
    final cardBg = const PdfColor.fromInt(0xFFFAFAFA);
    final borderColor = PdfColors.grey300;

    pw.Widget? cardsRow;

    // Ne créer la carte que s'il y a un client
    if (receipt.customer != null) {
      final clientCard = pw.Container(
        decoration: pw.BoxDecoration(
          color: cardBg,
          border: pw.Border.all(color: borderColor),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_t('customer', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(receipt.customer!.nom, style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold)),
            if (receipt.customer!.adresse?.isNotEmpty == true) ...[
              pw.SizedBox(height: 2),
              pw.Text(receipt.customer!.adresse!, style: pw.TextStyle(fontSize: fontSize - 1)),
            ],
            if (receipt.customer!.nui?.isNotEmpty == true) ...[
              pw.SizedBox(height: 2),
              pw.Text('NUI: ${receipt.customer!.nui}', style: pw.TextStyle(fontSize: fontSize - 1)),
            ],
            if (receipt.customer!.rccm?.isNotEmpty == true) ...[
              pw.SizedBox(height: 2),
              pw.Text('RCCM: ${receipt.customer!.rccm}', style: pw.TextStyle(fontSize: fontSize - 1)),
            ],
          ],
        ),
      );

      cardsRow = pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: clientCard),
          ],
        ),
      );
    }

    // ── 4. Tableau des articles avec zébrage ──────────────────────────────
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_t('article', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6), child: pw.Text(_t('quantity', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6), child: pw.Text(_t('unitPrice', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_t('total', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
        ],
      ),
      ...receipt.items.asMap().entries.map((entry) {
        final isEven = entry.key.isEven;
        final item = entry.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : rowOdd),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(item.productName, style: pw.TextStyle(fontSize: fontSize)),
                if (item.productReference.isNotEmpty) pw.Text('${_t('reference', receipt)}: ${item.productReference}', style: pw.TextStyle(fontSize: fontSize - 2, color: PdfColors.grey700)),
              ]),
            ),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.formattedUnitPrice, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.right)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.formattedTotalPrice, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.right)),
          ],
        );
      }),
    ];

    final itemsTable = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1.5),
        },
        children: tableRows,
      ),
    );

    // ── 5. Totaux avec TOTAL mis en valeur ────────────────────────────────
    final totals = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 220,
            child: pw.Column(
              children: [
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${_t('subtotal', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
                    pw.Text('${receipt.subtotal.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
                  ],
                ),
                if (receipt.discountAmount > 0) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${_t('discount', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
                      pw.Text('-${receipt.discountAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
                    ],
                  ),
                ],
                if (receipt.tvaAmount > 0) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TVA (${receipt.tvaRate % 1 == 0 ? receipt.tvaRate.toStringAsFixed(0) : receipt.tvaRate.toStringAsFixed(2)}%):', style: pw.TextStyle(fontSize: fontSize)),
                      pw.Text('+${receipt.tvaAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
                    ],
                  ),
                ],
                pw.Divider(thickness: 0.5),
                // Bloc TOTAL coloré
                pw.SizedBox(height: 4),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: accent, width: 1.25),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${receipt.tvaAmount > 0 ? 'Total TTC' : _t('totalAmount', receipt)}:',
                        style: pw.TextStyle(fontSize: fontSize + 3, fontWeight: pw.FontWeight.bold, color: accent),
                      ),
                      pw.Text(
                        '${receipt.totalAmount.toStringAsFixed(0)} FCFA',
                        style: pw.TextStyle(fontSize: fontSize + 3, fontWeight: pw.FontWeight.bold, color: accent),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${_t('paid', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
                    pw.Text('${receipt.paidAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
                  ],
                ),
                if (receipt.paidAmount > receipt.totalAmount) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${_t('change', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
                      pw.Text('${(receipt.paidAmount - receipt.totalAmount).toStringAsFixed(0)} FCFA',
                          style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                    ],
                  ),
                ],
                if (receipt.remainingAmount > 0) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${_t('remaining', receipt)}:', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${receipt.remainingAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // ── 6. Pied de page ───────────────────────────────────────────────────
    final footer = pw.Container(
      margin: const pw.EdgeInsets.only(top: 16, left: 16, right: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 0.5))),
      child: pw.Column(
        children: [
          if (company.slogan != null && company.slogan!.isNotEmpty) ...[
            pw.Center(child: pw.Text(company.slogan!, style: pw.TextStyle(fontSize: fontSize - 1, fontStyle: pw.FontStyle.italic), textAlign: pw.TextAlign.center, maxLines: 2)),
            pw.SizedBox(height: 6),
          ],
          pw.Center(child: pw.Text(_t('thankYou', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
          if (receipt.isReprint && receipt.lastReprintDate != null) ...[
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                '${_t('reprintedOn', receipt)} ${receipt.lastReprintDate!.day.toString().padLeft(2, '0')}/${receipt.lastReprintDate!.month.toString().padLeft(2, '0')}/${receipt.lastReprintDate!.year}'
                '${receipt.reprintBy?.isNotEmpty == true ? ' ${_t('by', receipt)} ${receipt.reprintBy}' : ''}',
                style: pw.TextStyle(fontSize: fontSize - 2, color: PdfColors.grey700),
              ),
            ),
          ],
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Document généré par Logesco V2 - ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
              style: pw.TextStyle(fontSize: fontSize - 2, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        header,
        titleRow,
        if (cardsRow != null) cardsRow,
        pw.SizedBox(height: 8),
        itemsTable,
        pw.SizedBox(height: 12),
        totals,
        pw.Spacer(),
        footer,
      ],
    );
  }

  // ── Format Matriciel : facture en texte pur, colonnes alignées, pour
  // imprimante à aiguilles sur papier continu (pas de couleurs, pas
  // d'images, pas de bordures — tout est du texte monospace, comme le
  // rendu natif ESC/P d'une imprimante matricielle). ────────────────────
  static const int _matricielCols = 80;

  // Retrait supplémentaire (au-delà de la marge de page) pour les blocs
  // alignés à droite qui touchent pile le bord de la zone imprimable —
  // n° de facture/date, et le récapitulatif des totaux (Net à payer).
  // Confirmé sur impression réelle : la marge de page seule ne suffisait
  // pas pour ces éléments collés au bord droit.
  static const double _rightInset = 16.0;

  pw.Font get _mono => pw.Font.courier();
  pw.Font get _monoBold => pw.Font.courierBold();

  pw.Widget _buildMatricielContent(Receipt receipt) {
    final company = receipt.companyInfo;
    const fs = 9.0; // taille de police, cohérente avec PrintFormat.matriciel.defaultFontSize

    final normal = pw.TextStyle(font: _mono, fontSize: fs);
    final bold = pw.TextStyle(font: _monoBold, fontSize: fs, fontWeight: pw.FontWeight.bold);
    final title = pw.TextStyle(font: _monoBold, fontSize: fs + 3, fontWeight: pw.FontWeight.bold);

    final separator = '-' * _matricielCols;

    // ── En-tête entreprise ────────────────────────────────────────────
    final headerLines = <String>[
      company.name.toUpperCase(),
      if (company.address.isNotEmpty) company.address,
      if (company.location?.isNotEmpty == true) company.location!,
      if (company.phone?.isNotEmpty == true) '${_t('phone', receipt)}: ${company.phone}',
      if (company.email?.isNotEmpty == true) '${_t('email', receipt)}: ${company.email}',
      if (company.nuiRccm?.isNotEmpty == true) '${_t('nuiRccm', receipt)}: ${company.nuiRccm}',
    ];

    // ── Ligne de colonnes du tableau (80 colonnes) ────────────────────
    // Référence(9) Désignation(22) Qté(4) PU(9) Remise(7) PU Net(9) Total(11)
    String row(String ref, String desig, String qte, String pu, String remise, String puNet, String total) {
      return '${_fit(ref, 9)} ${_fit(desig, 22)} ${_fitRight(qte, 4)} ${_fitRight(pu, 9)} ${_fitRight(remise, 7)} ${_fitRight(puNet, 9)} ${_fitRight(total, 11)}';
    }

    final tableHeader = row(
      _t('reference', receipt),
      _t('designation', receipt),
      _t('quantity', receipt),
      _t('unitPrice', receipt),
      _t('discount', receipt),
      _t('netUnitPrice', receipt),
      _t('total', receipt),
    );

    final itemRows = receipt.items.map((item) {
      final puGross = item.hasDiscount ? item.displayPrice : item.unitPrice;
      return row(
        item.productReference,
        item.productName,
        item.quantity.toString(),
        puGross.toStringAsFixed(0),
        item.hasDiscount ? item.discountAmount.toStringAsFixed(0) : '',
        item.unitPrice.toStringAsFixed(0),
        item.totalPrice.toStringAsFixed(0),
      );
    }).toList();

    final montantEnLettres = amountInWordsFcfa(receipt.totalAmount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Entête entreprise (centré)
        ...headerLines.map((l) => pw.Center(child: pw.Text(l, style: l == headerLines.first ? bold : normal))),
        pw.SizedBox(height: 6),
        pw.Text(separator, style: normal),

        // Titre + numéro/date sur la même bande
        // (padding droit supplémentaire : ce bloc collait pile au bord de
        // la zone imprimable et était rogné à l'impression réelle malgré
        // la marge de page — voir _rightInset)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(receipt.isProforma ? _t('proformaInvoice', receipt) : _t('invoice', receipt), style: title),
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: _rightInset),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('${_t('saleNumber', receipt)}: ${receipt.saleNumber}', style: normal),
                  pw.Text(
                    '${_t('date', receipt)}: ${receipt.saleDate.day.toString().padLeft(2, '0')}/${receipt.saleDate.month.toString().padLeft(2, '0')}/${receipt.saleDate.year}',
                    style: normal,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.Text(separator, style: normal),
        pw.SizedBox(height: 4),

        // Client
        if (receipt.customer != null) ...[
          pw.Text('${_t('billedTo', receipt)}: ${receipt.customer!.nom}', style: bold),
          if (receipt.customer!.nui?.isNotEmpty == true) pw.Text('NUI: ${receipt.customer!.nui}', style: normal),
          if (receipt.customer!.rccm?.isNotEmpty == true) pw.Text('RCCM: ${receipt.customer!.rccm}', style: normal),
          pw.SizedBox(height: 4),
        ],

        // Tableau des articles (texte aligné, pas de grille dessinée)
        pw.Text(separator, style: normal),
        pw.Text(tableHeader, style: bold),
        pw.Text(separator, style: normal),
        ...itemRows.map((r) => pw.Text(r, style: normal)),
        pw.Text(separator, style: normal),
        pw.SizedBox(height: 6),

        // Totaux (alignés à droite, avec le même retrait que le n° facture)
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(right: _rightInset),
            child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (receipt.discountAmount > 0) pw.Text('${_t('subtotal', receipt)}: ${receipt.subtotal.toStringAsFixed(0)}', style: normal),
              if (receipt.discountAmount > 0) pw.Text('${_t('discount', receipt)}: -${receipt.discountAmount.toStringAsFixed(0)}', style: normal),
              if (receipt.tvaAmount > 0)
                pw.Text(
                  'TVA (${receipt.tvaRate % 1 == 0 ? receipt.tvaRate.toStringAsFixed(0) : receipt.tvaRate.toStringAsFixed(2)}%): +${receipt.tvaAmount.toStringAsFixed(0)}',
                  style: normal,
                ),
              pw.Text('${_t('netToPay', receipt)}: ${receipt.totalAmount.toStringAsFixed(0)}', style: pw.TextStyle(font: _monoBold, fontSize: fs + 1, fontWeight: pw.FontWeight.bold)),
              pw.Text('${_t('paid', receipt)}: ${receipt.paidAmount.toStringAsFixed(0)}', style: normal),
              if (receipt.paidAmount > receipt.totalAmount)
                pw.Text('${_t('change', receipt)}: ${(receipt.paidAmount - receipt.totalAmount).toStringAsFixed(0)}', style: bold),
              if (receipt.remainingAmount > 0) pw.Text('${_t('remaining', receipt)}: ${receipt.remainingAmount.toStringAsFixed(0)}', style: bold),
            ],
            ),
          ),
        ),
        pw.SizedBox(height: 8),

        // Montant en lettres
        pw.Text('${_t('amountInWordsLabel', receipt)}:', style: normal),
        pw.Text(montantEnLettres, style: bold),
        pw.SizedBox(height: 4),
        pw.Text(separator, style: normal),
        pw.SizedBox(height: 20),

        // Signatures
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_t('seller', receipt), style: normal),
            pw.Text(_t('clientSignature', receipt), style: normal),
            pw.Text(_t('cashier', receipt), style: normal),
          ],
        ),
        pw.SizedBox(height: 24),
      ],
    );
  }

  /// Tronque/complète une chaîne à une largeur fixe (alignement gauche)
  String _fit(String text, int width) {
    final t = text.length > width ? text.substring(0, width) : text;
    return t.padRight(width);
  }

  /// Tronque/complète une chaîne à une largeur fixe (alignement droite)
  String _fitRight(String text, int width) {
    final t = text.length > width ? text.substring(text.length - width) : text;
    return t.padLeft(width);
  }
}
