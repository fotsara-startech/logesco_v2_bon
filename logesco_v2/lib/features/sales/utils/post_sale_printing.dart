import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../controllers/sales_controller.dart';
import '../../printing/controllers/printing_controller.dart';
import '../../printing/models/print_format.dart';
import '../../printing/views/receipt_preview_page.dart';

/// Applique le mode d'impression configuré dans les préférences de vente
/// (paramètres > ventes) juste après la validation d'une facture — utilisé
/// par FinalizeSaleDialog (vue classique) et QuickBillingView (vue rapide),
/// pour ne pas dupliquer cette logique à chaque nouvel écran de paiement.
void handlePostSalePrinting(SalesController salesController) {
  switch (salesController.printMode) {
    case PrintMode.none:
      // Sans impression, sans aperçu : retour direct.
      break;
    case PrintMode.direct:
      printReceiptSilently();
      break;
    case PrintMode.preview:
      showPrintReceiptDialog();
      break;
  }
}

void showPrintReceiptDialog() {
  Get.dialog(
    AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(width: 12),
          Text('sales_sale_created'.tr),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('sales_receipt_printing'.tr),
        ],
      ),
    ),
  );

  // Imprimer automatiquement
  Future.delayed(const Duration(milliseconds: 300), () {
    printReceiptDirect();
  });
}

Future<void> printReceiptDirect() async {
  try {
    final salesController = Get.find<SalesController>();

    if (salesController.lastCreatedSale == null) {
      Get.back();
      SnackbarHelper.error('sales_no_sale_for_print'.tr, title: 'error'.tr);
      return;
    }

    if (!Get.isRegistered<PrintingController>()) {
      Get.put(PrintingController());
    }

    final printingController = Get.find<PrintingController>();
    final format = salesController.selectedReceiptFormat;

    printingController.setSelectedFormat(format);
    final success = await printingController.generateReceiptForSale(
      salesController.lastCreatedSale!.id.toString(),
      format: format,
      companyProfile: salesController.companyProfile,
    );

    if (success && printingController.currentReceipt != null) {
      final receipt = printingController.currentReceipt!;

      Get.back(); // Fermer le dialog

      // Naviguer vers la prévisualisation
      Get.to(
        () => const ReceiptPreviewPage(),
        arguments: receipt,
      );
    } else {
      Get.back();
      SnackbarHelper.error('sales_cannot_generate_receipt'.tr, title: 'error'.tr);
    }
  } catch (e) {
    Get.back();
    SnackbarHelper.error('${'error'.tr}: $e', title: 'error'.tr);
  }
}

/// Mode "impression directe" : génère le reçu et l'envoie tout de suite à
/// l'imprimante par défaut, sans passer par l'aperçu — pour gagner du temps.
Future<void> printReceiptSilently() async {
  try {
    final salesController = Get.find<SalesController>();

    if (salesController.lastCreatedSale == null) {
      SnackbarHelper.error('sales_no_sale_for_print'.tr, title: 'error'.tr);
      return;
    }

    if (!Get.isRegistered<PrintingController>()) {
      Get.put(PrintingController());
    }

    final printingController = Get.find<PrintingController>();
    final format = salesController.selectedReceiptFormat;

    printingController.setSelectedFormat(format);
    final success = await printingController.generateReceiptForSale(
      salesController.lastCreatedSale!.id.toString(),
      format: format,
      companyProfile: salesController.companyProfile,
    );

    if (success && printingController.currentReceipt != null) {
      final receipt = printingController.currentReceipt!;
      final pdfBytes = await ReceiptPreviewPage.generatePdfBytes(format, receipt);

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Reçu_${receipt.saleNumber}.pdf',
      );

      SnackbarHelper.success('preview_print_success_msg'.tr, title: 'preview_print_success_title'.tr, duration: const Duration(seconds: 2));
    } else {
      SnackbarHelper.error('sales_cannot_generate_receipt'.tr, title: 'error'.tr);
    }
  } catch (e) {
    SnackbarHelper.error('${'error'.tr}: $e', title: 'error'.tr);
  }
}
