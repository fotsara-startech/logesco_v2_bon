import 'package:flutter/material.dart';
import '../../company_settings/models/company_profile.dart';
import '../../sales/models/sale.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import '../services/receipt_generation_service.dart';
import '../services/receipt_preview_service.dart';

/// Utilitaires pour l'intégration des templates avec les données d'entreprise
class TemplateIntegration {
  static final ReceiptGenerationService _generationService = ReceiptGenerationService();
  static final ReceiptPreviewService _previewService = ReceiptPreviewService();

  /// Crée un reçu avec les informations d'entreprise intégrées
  static Receipt createReceiptWithCompanyInfo({
    required Sale sale,
    required CompanyProfile companyInfo,
    print_models.PrintFormat format = print_models.PrintFormat.a4,
    bool isReprint = false,
    int reprintCount = 0,
    DateTime? lastReprintDate,
    String? reprintBy,
  }) {
    return Receipt.fromSale(
      sale: sale,
      companyInfo: companyInfo,
      format: format,
      isReprint: isReprint,
      reprintCount: reprintCount,
      lastReprintDate: lastReprintDate,
      reprintBy: reprintBy,
    );
  }

  /// Génère un reçu complet avec template personnalisé
  static Future<ReceiptGenerationResponse> generateReceiptWithTemplate({
    required Sale sale,
    required CompanyProfile companyInfo,
    print_models.PrintFormat format = print_models.PrintFormat.a4,
    print_models.PrintTemplate? customTemplate,
  }) async {
    final receipt = createReceiptWithCompanyInfo(
      sale: sale,
      companyInfo: companyInfo,
      format: format,
    );

    return await _generationService.generateReceipt(
      receipt: receipt,
      customTemplate: customTemplate,
    );
  }

  /// Crée un aperçu de reçu avec les informations d'entreprise
  static Widget createReceiptPreview({
    required Sale sale,
    required CompanyProfile companyInfo,
    print_models.PrintFormat format = print_models.PrintFormat.a4,
    print_models.PrintTemplate? customTemplate,
    double? scale,
    bool showFormatInfo = true,
  }) {
    final receipt = createReceiptWithCompanyInfo(
      sale: sale,
      companyInfo: companyInfo,
      format: format,
    );

    return _previewService.createPreviewWidget(
      receipt: receipt,
      customTemplate: customTemplate,
      scale: scale,
      showFormatInfo: showFormatInfo,
    );
  }

  /// Crée une comparaison de formats pour une vente
  static Widget createFormatComparison({
    required Sale sale,
    required CompanyProfile companyInfo,
    List<print_models.PrintFormat>? formats,
    Map<print_models.PrintFormat, print_models.PrintTemplate>? customTemplates,
    double scale = 0.5,
  }) {
    final receipt = createReceiptWithCompanyInfo(
      sale: sale,
      companyInfo: companyInfo,
      format: print_models.PrintFormat.a4, // Format par défaut pour la base
    );

    return _previewService.createFormatComparisonWidget(
      receipt: receipt,
      formats: formats,
      customTemplates: customTemplates,
      scale: scale,
    );
  }

  /// Valide qu'une vente peut être utilisée pour générer un reçu
  static bool validateSaleForReceipt(Sale sale) {
    if (sale.details.isEmpty) return false;
    if (sale.numeroVente.isEmpty) return false;
    if (sale.montantTotal <= 0) return false;
    return true;
  }

  /// Valide qu'un profil d'entreprise est complet pour les reçus
  static bool validateCompanyProfileForReceipt(CompanyProfile company) {
    if (company.name.isEmpty) return false;
    if (company.address.isEmpty) return false;
    return true;
  }

  /// Obtient les templates par défaut optimisés pour une entreprise
  static Map<print_models.PrintFormat, print_models.PrintTemplate> getOptimizedTemplatesForCompany(
    CompanyProfile company,
  ) {
    final templates = <print_models.PrintFormat, print_models.PrintTemplate>{};

    for (final format in print_models.PrintFormat.values) {
      var template = print_models.PrintTemplate.defaultFor(format);

      // Optimisations basées sur les informations de l'entreprise
      if (format == print_models.PrintFormat.thermal) {
        // Pour le thermique, on ajuste la taille de police selon la longueur du nom
        if (company.name.length > 20) {
          template = template.copyWith(fontSize: template.fontSize - 1);
        }
      }

      // Désactiver le logo si pas d'informations complètes
      if (company.location?.isEmpty == true && company.phone?.isEmpty == true) {
        template = template.copyWith(showLogo: false);
      }

      templates[format] = template;
    }

    return templates;
  }

  /// Estime le temps de génération pour un reçu
  static Duration estimateGenerationTime({
    required Sale sale,
    required print_models.PrintFormat format,
  }) {
    final baseTime = Duration(milliseconds: 100);
    final itemTime = Duration(milliseconds: 10 * sale.details.length);

    double formatMultiplier;
    switch (format) {
      case print_models.PrintFormat.thermal:
        formatMultiplier = 1.0;
        break;
      case print_models.PrintFormat.a5:
        formatMultiplier = 1.5;
        break;
      case print_models.PrintFormat.a4:
        formatMultiplier = 2.0;
        break;
    }

    return Duration(
      milliseconds: ((baseTime.inMilliseconds + itemTime.inMilliseconds) * formatMultiplier).round(),
    );
  }

  /// Obtient les informations de compatibilité pour un format
  static FormatCompatibilityInfo getFormatCompatibility({
    required Sale sale,
    required CompanyProfile company,
    required print_models.PrintFormat format,
  }) {
    final warnings = <String>[];
    final errors = <String>[];

    // Vérifications pour le format thermique
    if (format == print_models.PrintFormat.thermal) {
      // Vérifier la longueur des noms de produits
      for (final detail in sale.details) {
        if ((detail.produit?.nom.length ?? 0) > 25) {
          warnings.add('Le nom du produit "${detail.produit?.nom}" sera tronqué');
        }
      }

      // Vérifier la longueur du nom de l'entreprise
      if (company.name.length > 30) {
        warnings.add('Le nom de l\'entreprise sera affiché sur plusieurs lignes');
      }
    }

    // Vérifications générales
    if (!validateSaleForReceipt(sale)) {
      errors.add('Données de vente invalides');
    }

    if (!validateCompanyProfileForReceipt(company)) {
      errors.add('Profil d\'entreprise incomplet');
    }

    return FormatCompatibilityInfo(
      format: format,
      isCompatible: errors.isEmpty,
      warnings: warnings,
      errors: errors,
    );
  }
}

/// Informations de compatibilité pour un format
class FormatCompatibilityInfo {
  final print_models.PrintFormat format;
  final bool isCompatible;
  final List<String> warnings;
  final List<String> errors;

  const FormatCompatibilityInfo({
    required this.format,
    required this.isCompatible,
    required this.warnings,
    required this.errors,
  });

  /// Indique s'il y a des avertissements
  bool get hasWarnings => warnings.isNotEmpty;

  /// Indique s'il y a des erreurs
  bool get hasErrors => errors.isNotEmpty;

  /// Obtient tous les messages (erreurs + avertissements)
  List<String> get allMessages => [...errors, ...warnings];
}
