import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/printing_controller.dart';
import '../models/models.dart';
import '../widgets/receipt_template_factory.dart';

// Imports pour l'impression réelle
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Page de prévisualisation des reçus
class ReceiptPreviewPage extends StatelessWidget {
  const ReceiptPreviewPage({super.key});

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
                onPressed: controller.isGenerating ? null : () => _showPrintDialog(context, controller, receipt),
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

  void _showPrintDialog(BuildContext context, PrintingController controller, Receipt receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimer le reçu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reçu: ${receipt.saleNumber}'),
            const SizedBox(height: 8),
            Obx(() => Text('Format: ${_getFormatName(controller.selectedFormat)}')),
            const SizedBox(height: 16),
            const Text(
              'Voulez-vous imprimer ce reçu?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _printReceipt(controller, receipt);
            },
            child: const Text('Imprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(PrintingController controller, Receipt receipt) async {
    try {
      // S'assurer que le reçu est défini dans le contrôleur
      controller.selectReceipt(receipt);

      // Afficher un dialogue de progression
      Get.dialog(
        AlertDialog(
          title: const Text('Impression en cours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Impression du reçu en format ${controller.selectedFormat.displayName}...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Lancer l'impression directement
      await _simulatePrinting(controller.selectedFormat, receipt);

      // Fermer le dialogue de progression
      Get.back();

      // Afficher un message de succès
      Get.snackbar(
        '✅ Impression terminée',
        'Le reçu a été envoyé vers votre imprimante !',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      // Fermer le dialogue de progression en cas d'erreur
      if (Get.isDialogOpen == true) {
        Get.back();
      }

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

  Future<void> _simulatePrinting(PrintFormat format, Receipt receipt) async {
    // Créer le document PDF
    final pdfDoc = pw.Document();

    // Ajouter une page avec le contenu du reçu
    pdfDoc.addPage(
      pw.Page(
        pageFormat: format == PrintFormat.a4
            ? PdfPageFormat.a4
            : format == PrintFormat.a5
                ? PdfPageFormat.a5
                : const PdfPageFormat(226.77, 841.89), // 80mm pour thermique
        build: (pw.Context context) {
          return _buildPdfContent(receipt);
        },
      ),
    );

    // Lancer l'impression
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat pageFormat) async => pdfDoc.save(),
      name: 'Reçu ${receipt.saleNumber}',
    );
  }

  String _getFormatName(PrintFormat format) {
    switch (format) {
      case PrintFormat.thermal:
        return 'Thermique 80mm';
      case PrintFormat.a5:
        return 'A5';
      case PrintFormat.a4:
        return 'A4';
    }
  }

  // Méthodes pour l'impression réelle
  pw.Widget _buildPdfContent(Receipt receipt) {
    // Définir les marges selon le format
    final isTherm = receipt.format == PrintFormat.thermal;
    final fontSize = isTherm ? 8.5 : 10.0;
    final titleSize = isTherm ? 11.5 : 16.0;

    return pw.Padding(
      padding: pw.EdgeInsets.all(isTherm ? 8.0 : 20.0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
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
                if (receipt.companyInfo.phone?.isNotEmpty == true) pw.Text('Tel: ${receipt.companyInfo.phone}', style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center),
                if (receipt.companyInfo.nuiRccm?.isNotEmpty == true) pw.Text('NUI: ${receipt.companyInfo.nuiRccm}', style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center),
              ],
            ),
          ),

          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('================================', style: pw.TextStyle(fontSize: fontSize - 1))),
          pw.SizedBox(height: 10),

          // Titre du reçu
          pw.Center(
            child: pw.Text(
              'RECU DE VENTE',
              style: pw.TextStyle(fontSize: titleSize - 2, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),

          pw.SizedBox(height: 8),

          // Informations de vente (format compact sans espace après :)
          pw.Text('N° Vente:  ${receipt.saleNumber}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: fontSize)),
          pw.Text(
              'Date:  ${receipt.saleDate.day.toString().padLeft(2, '0')}/'
              '${receipt.saleDate.month.toString().padLeft(2, '0')}/'
              '${receipt.saleDate.year}',
              style: pw.TextStyle(fontSize: fontSize)),
          pw.Text(
              'Heure:  ${receipt.saleDate.hour.toString().padLeft(2, '0')}:  '
              '${receipt.saleDate.minute.toString().padLeft(2, '0')}',
              style: pw.TextStyle(fontSize: fontSize)),
          if (receipt.customer != null) pw.Text('Client:  ${_truncateText(receipt.customer!.nom, 15)}', style: pw.TextStyle(fontSize: fontSize)),
          pw.Text('Paiement:  ${receipt.paymentMethod}', style: pw.TextStyle(fontSize: fontSize)),

          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('================================', style: pw.TextStyle(fontSize: fontSize - 1))),
          pw.SizedBox(height: 10),

          // Articles
          pw.Container(margin: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2), child: pw.Text('ARTICLES:', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 4),

          ...receipt.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${index + 1}. ${_truncateText(item.productName, 22)}', style: pw.TextStyle(fontSize: fontSize)),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, top: 1),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (item.hasDiscount) ...[
                          // Prix original
                          pw.Text(
                            '${item.quantity} x ${item.displayPrice.toStringAsFixed(0)} FCFA = ${(item.displayPrice * item.quantity).toStringAsFixed(0)} FCFA',
                            style: pw.TextStyle(fontSize: fontSize - 0.5),
                          ),
                          // Remise appliquée
                          pw.Text(
                            'Remise: -${item.totalDiscountAmount.toStringAsFixed(0)} FCFA',
                            style: pw.TextStyle(fontSize: fontSize - 1, color: PdfColors.green),
                          ),
                          // Prix payé
                          pw.Text(
                            'Prix payé: ${item.formattedTotalPrice}',
                            style: pw.TextStyle(fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold),
                          ),
                        ] else ...[
                          // Pas de remise, affichage normal
                          pw.Text(
                            '${item.quantity} x ${item.formattedUnitPrice} = ${item.formattedTotalPrice}',
                            style: pw.TextStyle(fontSize: fontSize - 0.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item.productReference.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 8),
                      child: pw.Text('Ref: ${_truncateText(item.productReference, 18)}', style: pw.TextStyle(fontSize: fontSize - 1)),
                    ),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('================================', style: pw.TextStyle(fontSize: fontSize - 1))),
          pw.SizedBox(height: 5),

          // Totaux (valeur directement après le label)
          pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2), child: pw.Text('Sous-total: ${receipt.subtotal.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize))),
          if (receipt.discountAmount > 0) pw.Text('Remise: -${receipt.discountAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize)),
          pw.SizedBox(height: 4),
          pw.Center(child: pw.Text('--------------------------------', style: pw.TextStyle(fontSize: fontSize - 1))),
          pw.SizedBox(height: 4),
          pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              child: pw.Text('TOTAL: ${receipt.totalAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize))),
          pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2), child: pw.Text('Paye: ${receipt.paidAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize))),
          if (receipt.remainingAmount > 0)
            pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: pw.Text('Reste: ${receipt.remainingAmount.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),

          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('================================', style: pw.TextStyle(fontSize: fontSize - 1))),
          pw.SizedBox(height: 10),

          // Pied de page
          pw.Center(
            child: pw.Column(
              children: [
                // pw.Text('Merci pour votre confiance !', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)),
                // pw.SizedBox(height: 6),
                if (receipt.isReprint && receipt.lastReprintDate != null) ...[
                  pw.Text(
                    'Reimprime le ${receipt.lastReprintDate!.day.toString().padLeft(2, '0')}/'
                    '${receipt.lastReprintDate!.month.toString().padLeft(2, '0')}/'
                    '${receipt.lastReprintDate!.year}',
                    style: pw.TextStyle(fontSize: fontSize - 0.5),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (receipt.reprintBy?.isNotEmpty == true) pw.Text('par ${receipt.reprintBy}', style: pw.TextStyle(fontSize: fontSize - 0.5), textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 4),
                ],
                pw.Text('Merci pour votre visite,', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                pw.Text('A bientot!', style: pw.TextStyle(fontSize: fontSize - 0.5), textAlign: pw.TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
