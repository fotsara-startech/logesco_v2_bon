import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/printing_controller.dart';
import '../models/models.dart';
import '../widgets/receipt_template_factory.dart';
import '../utils/receipt_translations.dart';
import '../../../core/config/api_config.dart';

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
          title: const Text('Prévisualisation'),
        ),
        body: const Center(
          child: Text('Aucun reçu à prévisualiser'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prévisualisation du reçu'),
        actions: [
          // Bouton d'impression
          Obx(() => IconButton(
                onPressed: controller.isGenerating ? null : () => _printReceipt(controller, receipt),
                icon: controller.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                tooltip: 'Imprimer',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Format d\'impression:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() => SegmentedButton<PrintFormat>(
                  segments: const [
                    ButtonSegment(
                      value: PrintFormat.thermal,
                      label: Text('Thermique'),
                      icon: Icon(Icons.receipt),
                    ),
                    ButtonSegment(
                      value: PrintFormat.a5,
                      label: Text('A5'),
                      icon: Icon(Icons.description),
                    ),
                    ButtonSegment(
                      value: PrintFormat.a4,
                      label: Text('A4'),
                      icon: Icon(Icons.article),
                    ),
                  ],
                  selected: {controller.selectedFormat},
                  onSelectionChanged: (Set<PrintFormat> selection) {
                    if (selection.isNotEmpty) {
                      controller.setSelectedFormat(selection.first);
                    }
                  },
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(PrintingController controller, Receipt receipt) {
    return Obx(() {
      final format = controller.selectedFormat;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: _getPreviewWidth(format),
              maxHeight: double.infinity,
            ),
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
              padding: const EdgeInsets.all(16),
              child: ReceiptTemplateFactory.createPreview(
                receipt: receipt,
                format: format,
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
        return 300; // 80mm approximatif
      case PrintFormat.a5:
        return 400;
      case PrintFormat.a4:
        return 500;
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
                  'Reçu ${receipt.saleNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Total: ${receipt.totalAmount.toStringAsFixed(2)} FCFA',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Boutons d'action
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
            label: const Text('Fermer'),
          ),
          const SizedBox(width: 8),
          Obx(() => ElevatedButton.icon(
                onPressed: controller.isGenerating ? null : () => _printReceipt(controller, receipt),
                icon: controller.isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                label: Text(controller.isGenerating ? 'Impression...' : 'Imprimer'),
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

      Get.snackbar(
        '✅ Impression lancée',
        'Le reçu a été envoyé vers votre imprimante',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        '❌ Erreur d\'impression',
        'Impossible d\'imprimer le reçu: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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
    }

    // Ajouter une page avec le contenu
    pdfDoc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(format == PrintFormat.thermal ? 8.0 : 40.0),
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
        // C'est un chemin complet, essayer de le charger localement
        final file = File(logoPath);
        if (file.existsSync()) {
          return file.readAsBytesSync();
        }
      } else {
        // C'est juste un nom de fichier, le télécharger depuis le backend
        print('🖼️ Téléchargement du logo depuis le backend: $logoPath');

        final baseUrl = ApiConfig.currentBaseUrl;
        final serverUrl = baseUrl.replaceAll('/api/v1', '');
        final logoUrl = '$serverUrl/uploads/$logoPath';

        print('   URL du logo: $logoUrl');

        final response = await http.get(Uri.parse(logoUrl)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Timeout lors du chargement du logo');
            throw Exception('Timeout');
          },
        );

        if (response.statusCode == 200) {
          print('✅ Logo téléchargé (${response.bodyBytes.length} bytes)');
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
            _t('invoice', receipt).toUpperCase(),
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
        if (receipt.customer != null) pw.Text('${_t('customer', receipt)}:  ${receipt.customer!.nom}', style: pw.TextStyle(fontSize: fontSize)),
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
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text('--------------------------------', style: pw.TextStyle(fontSize: fontSize - 1))),
        pw.SizedBox(height: 4),
        pw.Text('${_t('totalAmount', receipt)}: ${receipt.totalAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)),
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

  // Format A4/A5 (nouveau format qui correspond à l'aperçu)
  pw.Widget _buildA4A5Content(Receipt receipt, PrintFormat format, Uint8List? logoBytes) {
    final company = receipt.companyInfo;
    final fontSize = 10.0;
    final titleSize = 16.0;
    final headerSize = 14.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // En-tête avec logo à gauche et infos entreprise à droite
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo à gauche (si disponible)
              if (logoBytes != null)
                pw.Container(
                  width: 100,
                  height: 100,
                  margin: const pw.EdgeInsets.only(right: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(
                      pw.MemoryImage(logoBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                )
              else
                // Placeholder si pas de logo
                pw.Container(
                  width: 100,
                  height: 100,
                  margin: const pw.EdgeInsets.only(right: 20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'LOGO',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                  ),
                ),

              // Informations de l'entreprise à droite
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Nom de l'entreprise
                    pw.Text(
                      company.name.toUpperCase(),
                      style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 4),
                    // Adresse
                    if (receipt.companyInfo.address.isNotEmpty)
                      pw.Text(
                        receipt.companyInfo.address,
                        style: pw.TextStyle(fontSize: fontSize),
                        textAlign: pw.TextAlign.right,
                      ),
                    // Localisation
                    if (receipt.companyInfo.location?.isNotEmpty == true)
                      pw.Text(
                        receipt.companyInfo.location!,
                        style: pw.TextStyle(fontSize: fontSize),
                        textAlign: pw.TextAlign.right,
                      ),
                    // Téléphone
                    if (receipt.companyInfo.phone?.isNotEmpty == true)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                          '${_t('phone', receipt)}: ${receipt.companyInfo.phone}',
                          style: pw.TextStyle(fontSize: fontSize),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    // NUI RCCM
                    if (receipt.companyInfo.nuiRccm?.isNotEmpty == true)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                          '${_t('nuiRccm', receipt)}: ${receipt.companyInfo.nuiRccm}',
                          style: pw.TextStyle(fontSize: fontSize),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 24),

        // Titre "FACTURE"
        pw.Center(
          child: pw.Text(
            _t('invoice', receipt).toUpperCase(),
            style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold),
          ),
        ),

        pw.SizedBox(height: 12),

        // Informations de la vente
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${_t('saleNumber', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
            pw.Text(receipt.saleNumber, style: pw.TextStyle(fontSize: fontSize)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${_t('date', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
            pw.Text(
              '${receipt.saleDate.day.toString().padLeft(2, '0')}/'
              '${receipt.saleDate.month.toString().padLeft(2, '0')}/'
              '${receipt.saleDate.year} '
              '${receipt.saleDate.hour.toString().padLeft(2, '0')}:'
              '${receipt.saleDate.minute.toString().padLeft(2, '0')}',
              style: pw.TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        if (receipt.customer != null) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${_t('customer', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
              pw.Text(receipt.customer!.nom, style: pw.TextStyle(fontSize: fontSize)),
            ],
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${_t('paymentMethod', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
            pw.Text(receipt.paymentMethod, style: pw.TextStyle(fontSize: fontSize)),
          ],
        ),

        pw.SizedBox(height: 20),

        // Tableau des articles
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Article
            1: const pw.FlexColumnWidth(1), // Qté
            2: const pw.FlexColumnWidth(1.5), // P.U.
            3: const pw.FlexColumnWidth(1.5), // Total
          },
          children: [
            // En-tête du tableau
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(_t('article', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(_t('quantity', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(_t('unitPrice', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(_t('total', receipt), style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
            // Lignes des articles
            ...receipt.items.map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item.productName, style: pw.TextStyle(fontSize: fontSize)),
                        if (item.productReference.isNotEmpty) pw.Text('${_t('reference', receipt)}: ${item.productReference}', style: pw.TextStyle(fontSize: fontSize - 2, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(item.formattedUnitPrice, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(item.formattedTotalPrice, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.right),
                  ),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 16),

        // Totaux (alignés à droite)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${_t('subtotal', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
                      pw.Text('${receipt.subtotal.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
                    ],
                  ),
                  if (receipt.discountAmount > 0) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${_t('discount', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
                        pw.Text('-${receipt.discountAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
                      ],
                    ),
                  ],
                  pw.Divider(thickness: 1),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${_t('totalAmount', receipt)}:', style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${receipt.totalAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize + 2, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${_t('paid', receipt)}:', style: pw.TextStyle(fontSize: fontSize)),
                      pw.Text('${receipt.paidAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
                    ],
                  ),
                  if (receipt.remainingAmount > 0) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${_t('remaining', receipt)}:', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${receipt.remainingAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        pw.Spacer(),

        // Pied de page
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 1)),
          ),
          child: pw.Column(
            children: [
              // Slogan si disponible
              if (company.slogan != null && company.slogan!.isNotEmpty) ...[
                pw.Center(
                  child: pw.Text(
                    company.slogan!,
                    style: pw.TextStyle(
                      fontSize: fontSize,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
              pw.Center(
                child: pw.Text(
                  _t('thankYou', receipt),
                  style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Document généré par Logesco V2 - ${DateTime.now().day.toString().padLeft(2, '0')}/'
                  '${DateTime.now().month.toString().padLeft(2, '0')}/'
                  '${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: fontSize - 2, color: PdfColors.grey700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
