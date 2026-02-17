import 'package:json_annotation/json_annotation.dart';
import '../../company_settings/models/company_profile.dart';
import '../../sales/models/sale.dart';
import '../../customers/models/customer.dart';
import 'print_format.dart';

part 'receipt_model.g.dart';

/// Modèle pour un reçu avec informations d'entreprise
@JsonSerializable()
class Receipt {
  final String id;
  final String saleId;
  final String saleNumber;
  final CompanyProfile companyInfo;
  final List<ReceiptItem> items;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentMethod;
  final DateTime saleDate;
  final Customer? customer;
  final PrintFormat format;
  final bool isReprint;
  final int reprintCount;
  final DateTime? lastReprintDate;
  final String? reprintBy;

  const Receipt({
    required this.id,
    required this.saleId,
    required this.saleNumber,
    required this.companyInfo,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    required this.saleDate,
    this.customer,
    required this.format,
    this.isReprint = false,
    this.reprintCount = 0,
    this.lastReprintDate,
    this.reprintBy,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptToJson(this);

  /// Crée un reçu à partir d'une vente
  factory Receipt.fromSale({
    required Sale sale,
    required CompanyProfile companyInfo,
    PrintFormat format = PrintFormat.a4,
    bool isReprint = false,
    int reprintCount = 0,
    DateTime? lastReprintDate,
    String? reprintBy,
  }) {
    // Créer les articles du reçu
    final items = sale.details.map((detail) => ReceiptItem.fromSaleDetail(detail)).toList();

    // Calculer le total des remises à partir des détails
    final totalDiscountFromItems = items.fold<double>(0.0, (sum, item) => sum + item.totalDiscountAmount);

    // Debug: Afficher les valeurs pour diagnostic
    print('🔍 DEBUG REMISES RECEIPT:');
    print('  sale.montantRemise: ${sale.montantRemise}');
    print('  totalDiscountFromItems: $totalDiscountFromItems');
    print('  sale.sousTotal: ${sale.sousTotal}');
    print('  sale.montantTotal: ${sale.montantTotal}');
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      print('  Item $i: ${item.productName}');
      print('    displayPrice: ${item.displayPrice}');
      print('    discountAmount: ${item.discountAmount}');
      print('    unitPrice: ${item.unitPrice}');
      print('    totalDiscountAmount: ${item.totalDiscountAmount}');
    }

    // Utiliser le plus grand entre sale.montantRemise et le calcul des détails
    final actualDiscountAmount = totalDiscountFromItems > 0 ? totalDiscountFromItems : sale.montantRemise;
    print('  actualDiscountAmount FINAL: $actualDiscountAmount');

    // Calculer le vrai sous-total (prix originaux) si des remises existent
    double correctSubtotal = sale.sousTotal;
    double finalDiscountAmount = actualDiscountAmount;

    if (totalDiscountFromItems > 0) {
      // Recalculer le sous-total en ajoutant les remises
      correctSubtotal = items.fold<double>(0.0, (sum, item) {
        return sum + (item.displayPrice > 0 ? item.displayPrice * item.quantity : item.totalPrice);
      });
      print('  correctSubtotal calculé: $correctSubtotal');
    } else if (sale.sousTotal > sale.montantTotal) {
      // Solution de secours: si sous-total > total, il y a forcément une remise
      finalDiscountAmount = sale.sousTotal - sale.montantTotal;
      correctSubtotal = sale.sousTotal;
      print('  SOLUTION DE SECOURS: remise calculée = $finalDiscountAmount');
    }

    print('  FINAL - subtotal: $correctSubtotal, discount: $finalDiscountAmount');

    return Receipt(
      id: 'receipt_${sale.id}_${DateTime.now().millisecondsSinceEpoch}',
      saleId: sale.id.toString(),
      saleNumber: sale.numeroVente,
      companyInfo: companyInfo,
      items: items,
      subtotal: correctSubtotal,
      discountAmount: finalDiscountAmount,
      totalAmount: sale.montantTotal,
      paidAmount: sale.montantPaye,
      remainingAmount: sale.montantRestant,
      paymentMethod: sale.modePaiement,
      saleDate: sale.dateCreation,
      customer: sale.client,
      format: format,
      isReprint: isReprint,
      reprintCount: reprintCount,
      lastReprintDate: lastReprintDate,
      reprintBy: reprintBy,
    );
  }

  /// Crée une copie pour réimpression
  Receipt copyForReprint({
    required String reprintBy,
    PrintFormat? newFormat,
  }) {
    return Receipt(
      id: 'reprint_${saleId}_${DateTime.now().millisecondsSinceEpoch}',
      saleId: saleId,
      saleNumber: saleNumber,
      companyInfo: companyInfo,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      paymentMethod: paymentMethod,
      saleDate: saleDate,
      customer: customer,
      format: newFormat ?? format,
      isReprint: true,
      reprintCount: reprintCount + 1,
      lastReprintDate: DateTime.now(),
      reprintBy: reprintBy,
    );
  }

  /// Indique si la vente est complètement payée
  bool get isFullyPaid => remainingAmount <= 0;

  /// Indique si c'est une vente à crédit
  bool get isCreditSale => paymentMethod.toLowerCase() == 'credit';

  /// Texte du statut de paiement
  String get paymentStatus {
    if (isFullyPaid) return 'Payé';
    if (paidAmount > 0) return 'Partiellement payé';
    return 'Non payé';
  }

  /// Texte d'indication de réimpression
  String get reprintIndicator {
    if (!isReprint) return '';
    return 'COPIE ${reprintCount > 1 ? '($reprintCount)' : ''}';
  }

  /// Crée une copie avec des modifications
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
    PrintFormat? format,
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

/// Élément d'un reçu
@JsonSerializable()
class ReceiptItem {
  final String productId;
  final String productName;
  final String productReference;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double displayPrice; // Prix affiché (avant remise)
  final double discountAmount; // Montant de la remise appliquée
  final String? discountJustification; // Justification de la remise

  const ReceiptItem({
    required this.productId,
    required this.productName,
    required this.productReference,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.displayPrice = 0.0,
    this.discountAmount = 0.0,
    this.discountJustification,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => _$ReceiptItemFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptItemToJson(this);

  /// Crée un élément de reçu à partir d'un détail de vente
  factory ReceiptItem.fromSaleDetail(SaleDetail detail) {
    print('🔍 DEBUG SALE DETAIL: ${detail.produit?.nom ?? 'Produit inconnu'}');
    print('  prixUnitaire: ${detail.prixUnitaire}');
    print('  prixAffiche: ${detail.prixAffiche}');
    print('  remiseAppliquee: ${detail.remiseAppliquee}');
    print('  montantLigne: ${detail.montantLigne}');

    return ReceiptItem(
      productId: detail.produitId.toString(),
      productName: detail.produit?.nom ?? 'Produit inconnu',
      productReference: detail.produit?.reference ?? '',
      quantity: detail.quantite,
      unitPrice: detail.prixUnitaire,
      totalPrice: detail.montantLigne,
      displayPrice: detail.prixAffiche,
      discountAmount: detail.remiseAppliquee,
      discountJustification: detail.justificationRemise,
    );
  }

  /// Prix unitaire formaté
  String get formattedUnitPrice => '${unitPrice.toStringAsFixed(0)} FCFA';

  /// Prix total formaté
  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(0)} FCFA';

  /// Prix affiché formaté
  String get formattedDisplayPrice => '${displayPrice.toStringAsFixed(0)} FCFA';

  /// Montant de remise formaté
  String get formattedDiscountAmount => '${discountAmount.toStringAsFixed(0)} FCFA';

  /// Vérifie si cet article a une remise
  bool get hasDiscount => discountAmount > 0;

  /// Calcule le total de la remise pour cet article (remise unitaire × quantité)
  double get totalDiscountAmount => discountAmount * quantity;
}

/// Requête pour générer un reçu
@JsonSerializable()
class GenerateReceiptRequest {
  final String saleId;
  final PrintFormat format;
  final bool includeCompanyInfo;

  const GenerateReceiptRequest({
    required this.saleId,
    required this.format,
    this.includeCompanyInfo = true,
  });

  factory GenerateReceiptRequest.fromJson(Map<String, dynamic> json) => _$GenerateReceiptRequestFromJson(json);
  Map<String, dynamic> toJson() => _$GenerateReceiptRequestToJson(this);
}

/// Requête pour réimprimer un reçu
@JsonSerializable()
class ReprintReceiptRequest {
  final String receiptId;
  final String saleId;
  final PrintFormat? newFormat;
  final String reprintBy;
  final String? reason;

  const ReprintReceiptRequest({
    required this.receiptId,
    required this.saleId,
    this.newFormat,
    required this.reprintBy,
    this.reason,
  });

  factory ReprintReceiptRequest.fromJson(Map<String, dynamic> json) => _$ReprintReceiptRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReprintReceiptRequestToJson(this);
}

/// Réponse de génération de reçu
@JsonSerializable()
class ReceiptGenerationResponse {
  final Receipt receipt;
  final String? pdfUrl;
  final String? thermalData;
  final bool success;
  final String? error;

  const ReceiptGenerationResponse({
    required this.receipt,
    this.pdfUrl,
    this.thermalData,
    required this.success,
    this.error,
  });

  factory ReceiptGenerationResponse.fromJson(Map<String, dynamic> json) => _$ReceiptGenerationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptGenerationResponseToJson(this);

  /// Crée une réponse de succès
  factory ReceiptGenerationResponse.success({
    required Receipt receipt,
    String? pdfUrl,
    String? thermalData,
  }) {
    return ReceiptGenerationResponse(
      receipt: receipt,
      pdfUrl: pdfUrl,
      thermalData: thermalData,
      success: true,
    );
  }

  /// Crée une réponse d'erreur
  factory ReceiptGenerationResponse.error({
    required Receipt receipt,
    required String error,
  }) {
    return ReceiptGenerationResponse(
      receipt: receipt,
      success: false,
      error: error,
    );
  }
}
