import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import 'receipt_template_base.dart';
import 'receipt_template_a4.dart';
import 'receipt_template_a5.dart';
import 'receipt_template_thermal.dart';

/// Factory pour créer les templates de reçu selon le format
class ReceiptTemplateFactory {
  /// Crée un template de reçu selon le format spécifié
  static ReceiptTemplateBase createTemplate({
    required Receipt receipt,
    print_models.PrintTemplate? template,
    bool showPreview = false,
  }) {
    final printTemplate = template ?? print_models.PrintTemplate.defaultFor(receipt.format);

    switch (receipt.format) {
      case print_models.PrintFormat.a4:
        return ReceiptTemplateA4(
          receipt: receipt,
          template: printTemplate,
          showPreview: showPreview,
        );

      case print_models.PrintFormat.a5:
        return ReceiptTemplateA5(
          receipt: receipt,
          template: printTemplate,
          showPreview: showPreview,
        );

      case print_models.PrintFormat.thermal:
        return ReceiptTemplateThermal(
          receipt: receipt,
          template: printTemplate,
          showPreview: showPreview,
        );
    }
  }

  /// Crée un widget de prévisualisation pour un format donné
  static Widget createPreview({
    required Receipt receipt,
    print_models.PrintFormat? format,
    print_models.PrintTemplate? template,
    double? scale,
  }) {
    final receiptWithFormat = format != null
        ? Receipt(
            id: receipt.id,
            saleId: receipt.saleId,
            saleNumber: receipt.saleNumber,
            companyInfo: receipt.companyInfo,
            items: receipt.items,
            subtotal: receipt.subtotal,
            discountAmount: receipt.discountAmount,
            totalAmount: receipt.totalAmount,
            paidAmount: receipt.paidAmount,
            remainingAmount: receipt.remainingAmount,
            paymentMethod: receipt.paymentMethod,
            saleDate: receipt.saleDate,
            customer: receipt.customer,
            format: format,
            isReprint: receipt.isReprint,
            reprintCount: receipt.reprintCount,
            lastReprintDate: receipt.lastReprintDate,
            reprintBy: receipt.reprintBy,
          )
        : receipt;

    final templateWidget = createTemplate(
      receipt: receiptWithFormat,
      template: template,
      showPreview: true,
    );

    if (scale != null && scale != 1.0) {
      return Transform.scale(
        scale: scale,
        child: templateWidget,
      );
    }

    return templateWidget;
  }

  /// Obtient les dimensions d'un template pour un format donné
  static Size getTemplateDimensions(print_models.PrintFormat format) {
    switch (format) {
      case print_models.PrintFormat.a4:
        return Size(format.widthPoints, format.heightPoints);
      case print_models.PrintFormat.a5:
        return Size(format.widthPoints, format.heightPoints);
      case print_models.PrintFormat.thermal:
        return Size(format.widthPoints, 0); // Hauteur variable
    }
  }

  /// Calcule l'échelle optimale pour l'affichage dans un conteneur
  static double calculateOptimalScale({
    required print_models.PrintFormat format,
    required Size containerSize,
    double maxScale = 1.0,
  }) {
    final templateSize = getTemplateDimensions(format);

    if (templateSize.height == 0) {
      // Pour le format thermique, on se base uniquement sur la largeur
      final scaleX = containerSize.width / templateSize.width;
      return (scaleX * 0.9).clamp(0.1, maxScale); // 90% pour les marges
    }

    final scaleX = containerSize.width / templateSize.width;
    final scaleY = containerSize.height / templateSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    return (scale * 0.9).clamp(0.1, maxScale); // 90% pour les marges
  }

  /// Vérifie si un format nécessite une génération PDF
  static bool requiresPdfGeneration(print_models.PrintFormat format) {
    return format.requiresPdf;
  }

  /// Obtient la liste des formats supportés
  static List<print_models.PrintFormat> getSupportedFormats() {
    return print_models.PrintFormat.values;
  }

  /// Obtient les templates par défaut pour tous les formats
  static Map<print_models.PrintFormat, print_models.PrintTemplate> getDefaultTemplates() {
    return {
      for (final format in print_models.PrintFormat.values) format: print_models.PrintTemplate.defaultFor(format),
    };
  }

  /// Valide qu'un reçu peut être rendu avec un format donné
  static bool validateReceiptForFormat({
    required Receipt receipt,
    required print_models.PrintFormat format,
  }) {
    // Vérifications de base
    if (receipt.items.isEmpty) return false;
    if (receipt.companyInfo.name.isEmpty) return false;

    // Vérifications spécifiques au format
    switch (format) {
      case print_models.PrintFormat.thermal:
        // Pour le thermique, on vérifie que les noms de produits ne sont pas trop longs
        final hasLongProductNames = receipt.items.any(
          (item) => item.productName.length > 25,
        );
        if (hasLongProductNames) {
          // On peut toujours rendre, mais avec troncature
        }
        break;

      case print_models.PrintFormat.a4:
      case print_models.PrintFormat.a5:
        // Pas de restrictions particulières pour les formats PDF
        break;
    }

    return true;
  }

  /// Estime la hauteur d'un reçu thermique
  static double estimateThermalHeight({
    required Receipt receipt,
    required print_models.PrintTemplate template,
  }) {
    if (receipt.format != print_models.PrintFormat.thermal) return 0;

    // Estimation basée sur le contenu
    double height = 0;

    // En-tête entreprise (environ 6-8 lignes)
    height += template.fontSize * 8;

    // Informations de vente (environ 6 lignes)
    height += template.fontSize * 6;

    // Articles (2-3 lignes par article)
    height += receipt.items.length * template.fontSize * 2.5;

    // Totaux (environ 5 lignes)
    height += template.fontSize * 5;

    // Pied de page (environ 4 lignes)
    height += template.fontSize * 4;

    // Marges et espacements
    height += template.margins.vertical;
    height += 40; // Espace pour la coupe

    return height;
  }
}
