import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../models/print_format.dart' as print_models;
import '../widgets/receipt_template_factory.dart';
import '../../company_settings/models/company_profile.dart';
import '../../customers/models/customer.dart';

/// Service pour la prévisualisation des reçus
class ReceiptPreviewService {
  /// Crée un widget de prévisualisation pour un reçu
  Widget createPreviewWidget({
    required Receipt receipt,
    print_models.PrintTemplate? customTemplate,
    double? scale,
    bool showFormatInfo = true,
  }) {
    final template = customTemplate ?? print_models.PrintTemplate.defaultFor(receipt.format);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Informations du format si demandées
          if (showFormatInfo) _buildFormatHeader(receipt.format),

          // Template du reçu
          ReceiptTemplateFactory.createPreview(
            receipt: receipt,
            template: template,
            scale: scale,
          ),
        ],
      ),
    );
  }

  /// Crée un widget de comparaison entre plusieurs formats
  Widget createFormatComparisonWidget({
    required Receipt receipt,
    List<print_models.PrintFormat>? formats,
    Map<print_models.PrintFormat, print_models.PrintTemplate>? customTemplates,
    double scale = 0.5,
  }) {
    final formatsToShow = formats ?? print_models.PrintFormat.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: formatsToShow.map((format) {
          final template = customTemplates?[format] ?? print_models.PrintTemplate.defaultFor(format);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                // Nom du format
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    format.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Aperçu du reçu
                createPreviewWidget(
                  receipt: receipt.copyWith(format: format),
                  customTemplate: template,
                  scale: scale,
                  showFormatInfo: false,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Construit l'en-tête avec les informations du format
  Widget _buildFormatHeader(print_models.PrintFormat format) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFormatIcon(format),
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Text(
            format.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
          ),
          const Spacer(),
          Text(
            '${format.widthMm.toInt()} x ${format.heightMm > 0 ? format.heightMm.toInt() : '∞'} mm',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Obtient l'icône appropriée pour un format
  IconData _getFormatIcon(print_models.PrintFormat format) {
    switch (format) {
      case print_models.PrintFormat.a4:
        return Icons.description;
      case print_models.PrintFormat.a5:
        return Icons.note;
      case print_models.PrintFormat.thermal:
        return Icons.receipt;
    }
  }

  /// Calcule les dimensions d'affichage optimales
  Size calculateOptimalDisplaySize({
    required print_models.PrintFormat format,
    required Size containerSize,
    double maxScale = 1.0,
  }) {
    return ReceiptTemplateFactory.getTemplateDimensions(format);
  }

  /// Valide qu'un reçu peut être prévisualisé
  bool canPreviewReceipt(Receipt receipt) {
    return ReceiptTemplateFactory.validateReceiptForFormat(
      receipt: receipt,
      format: receipt.format,
    );
  }

  /// Obtient les informations de prévisualisation pour un format
  PreviewInfo getPreviewInfo(print_models.PrintFormat format) {
    return PreviewInfo(
      format: format,
      dimensions: ReceiptTemplateFactory.getTemplateDimensions(format),
      requiresPdf: ReceiptTemplateFactory.requiresPdfGeneration(format),
      estimatedHeight: format == print_models.PrintFormat.thermal ? null : format.heightPoints,
    );
  }
}

/// Informations de prévisualisation pour un format
class PreviewInfo {
  final print_models.PrintFormat format;
  final Size dimensions;
  final bool requiresPdf;
  final double? estimatedHeight;

  const PreviewInfo({
    required this.format,
    required this.dimensions,
    required this.requiresPdf,
    this.estimatedHeight,
  });
}

/// Extension pour faciliter la copie des reçus avec nouveau format
extension ReceiptCopyExtension on Receipt {
  Receipt copyWith({
    String? id,
    String? saleId,
    String? saleNumber,
    CompanyProfile? companyInfo,
    List<ReceiptItem>? items,
    double? subtotal,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? paymentMethod,
    DateTime? saleDate,
    Customer? customer,
    print_models.PrintFormat? format,
    bool? isReprint,
    int? reprintCount,
    DateTime? lastReprintDate,
    String? reprintBy,
  }) {
    return Receipt(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      saleNumber: saleNumber ?? this.saleNumber,
      companyInfo: companyInfo ?? this.companyInfo,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleDate: saleDate ?? this.saleDate,
      customer: customer ?? this.customer,
      format: format ?? this.format,
      isReprint: isReprint ?? this.isReprint,
      reprintCount: reprintCount ?? this.reprintCount,
      lastReprintDate: lastReprintDate ?? this.lastReprintDate,
      reprintBy: reprintBy ?? this.reprintBy,
    );
  }
}
