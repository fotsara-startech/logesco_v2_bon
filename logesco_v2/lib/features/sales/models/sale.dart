import 'package:json_annotation/json_annotation.dart';
import '../../customers/models/customer.dart';

part 'sale.g.dart';

/// Modèle de vente - SOLUTION 2: Système de compte client centralisé
///
/// IMPORTANT: Le statut de la vente est toujours "terminee" dès sa création.
/// Les dettes sont gérées au niveau du compte client, pas au niveau de la vente.
///
/// - montantPaye: Montant versé lors de cette vente spécifique
/// - montantRestant: Reste à payer pour CETTE vente uniquement (info historique)
/// - statut: Toujours "terminee" (sauf si annulée)
///
/// Pour connaître la dette globale d'un client, consulter son compte client.
@JsonSerializable()
class Sale {
  final int id;
  final String numeroVente;
  final int? clientId;
  final Customer? client;
  final String modePaiement;
  @JsonKey(defaultValue: 0.0)
  final double sousTotal;
  @JsonKey(defaultValue: 0.0)
  final double montantTotal;
  @JsonKey(defaultValue: 0.0)
  final double montantRemise;
  @JsonKey(defaultValue: 0.0)
  final double montantPaye;
  @JsonKey(defaultValue: 0.0)
  final double montantRestant;
  final String statut;
  @JsonKey(name: 'dateVente')
  final DateTime dateCreation;
  final DateTime? dateModification;
  @JsonKey(defaultValue: <SaleDetail>[])
  final List<SaleDetail> details;

  const Sale({
    required this.id,
    required this.numeroVente,
    this.clientId,
    this.client,
    required this.modePaiement,
    required this.sousTotal,
    required this.montantTotal,
    required this.montantRemise,
    required this.montantPaye,
    required this.montantRestant,
    required this.statut,
    required this.dateCreation,
    this.dateModification,
    this.details = const <SaleDetail>[],
  });

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
  Map<String, dynamic> toJson() => _$SaleToJson(this);

  double get montantFinal => montantTotal;

  /// SOLUTION 2: Cette propriété indique si cette vente spécifique a été payée
  /// Pour la dette globale du client, consulter le compte client
  bool get isCompletelyPaid => montantRestant <= 0;

  bool get isCancelled => statut == 'annulee';
  bool get isCredit => modePaiement == 'credit';

  /// Indique si c'était un paiement partiel pour cette vente
  bool get isPartialPayment => montantPaye > 0 && montantRestant > 0;
}

@JsonSerializable()
class SaleDetail {
  final int id;
  final int venteId;
  final int produitId;
  final ProductSummary? produit;
  @JsonKey(defaultValue: 0)
  final int quantite;
  @JsonKey(defaultValue: 0.0)
  final double prixUnitaire;
  @JsonKey(defaultValue: 0.0)
  final double prixAffiche;
  @JsonKey(defaultValue: 0.0)
  final double remiseAppliquee;
  final String? justificationRemise;
  @JsonKey(name: 'prixTotal', defaultValue: 0.0)
  final double montantLigne;

  const SaleDetail({
    required this.id,
    required this.venteId,
    required this.produitId,
    this.produit,
    required this.quantite,
    required this.prixUnitaire,
    this.prixAffiche = 0.0,
    this.remiseAppliquee = 0.0,
    this.justificationRemise,
    required this.montantLigne,
  });

  factory SaleDetail.fromJson(Map<String, dynamic> json) => _$SaleDetailFromJson(json);
  Map<String, dynamic> toJson() => _$SaleDetailToJson(this);

  /// Calcule l'économie réalisée par le client
  double get economieClient => remiseAppliquee * quantite;

  /// Calcule le pourcentage de remise appliquée
  double get pourcentageRemise => prixAffiche > 0 ? (remiseAppliquee / prixAffiche * 100) : 0;
}

@JsonSerializable()
class CreateSaleRequest {
  final int? clientId;
  final String modePaiement;
  final double montantRemise;
  final double montantPaye;
  final List<CreateSaleDetailRequest> details;
  final DateTime? dateVente; // Date personnalisée pour l'antidatage

  const CreateSaleRequest({
    this.clientId,
    required this.modePaiement,
    required this.montantRemise,
    required this.montantPaye,
    required this.details,
    this.dateVente,
  });

  factory CreateSaleRequest.fromJson(Map<String, dynamic> json) => _$CreateSaleRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateSaleRequestToJson(this);
}

@JsonSerializable()
class CreateSaleDetailRequest {
  final int produitId;
  final int quantite;
  final double prixUnitaire;
  final double prixAffiche;
  @JsonKey(defaultValue: 0.0)
  final double remiseAppliquee;
  final String? justificationRemise;

  const CreateSaleDetailRequest({
    required this.produitId,
    required this.quantite,
    required this.prixUnitaire,
    required this.prixAffiche,
    this.remiseAppliquee = 0.0,
    this.justificationRemise,
  });

  factory CreateSaleDetailRequest.fromJson(Map<String, dynamic> json) => _$CreateSaleDetailRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateSaleDetailRequestToJson(this);
}

@JsonSerializable()
class SalePaymentRequest {
  final double montantPaye;
  final String? description;

  const SalePaymentRequest({
    required this.montantPaye,
    this.description,
  });

  factory SalePaymentRequest.fromJson(Map<String, dynamic> json) => _$SalePaymentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SalePaymentRequestToJson(this);
}

@JsonSerializable()
class ProductSummary {
  final int id;
  final String nom;
  final String reference;
  @JsonKey(defaultValue: null)
  final double? prixAchat; // Prix d'achat pour calculer les coûts réels

  const ProductSummary({
    required this.id,
    required this.nom,
    required this.reference,
    this.prixAchat,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) => _$ProductSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ProductSummaryToJson(this);
}

// Classe pour le panier de vente (interface utilisateur)
class CartItem {
  final int productId;
  final String productName;
  final String productReference;
  int quantity;
  double unitPrice;
  final double originalPrice; // Prix affiché original
  final double maxDiscountAllowed; // Remise maximale autorisée
  double discountApplied; // Remise appliquée
  String? discountJustification; // Justification de la remise

  CartItem({
    required this.productId,
    required this.productName,
    required this.productReference,
    required this.quantity,
    required this.unitPrice,
    required this.originalPrice,
    this.maxDiscountAllowed = 0.0,
    this.discountApplied = 0.0,
    this.discountJustification,
  });

  double get totalPrice => quantity * unitPrice;
  double get totalSavings => quantity * discountApplied;
  double get finalUnitPrice => originalPrice - discountApplied;
  bool get hasDiscount => discountApplied > 0;
  bool get isDiscountValid => discountApplied <= maxDiscountAllowed;

  CartItem copyWith({
    int? productId,
    String? productName,
    String? productReference,
    int? quantity,
    double? unitPrice,
    double? originalPrice,
    double? maxDiscountAllowed,
    double? discountApplied,
    String? discountJustification,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productReference: productReference ?? this.productReference,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      maxDiscountAllowed: maxDiscountAllowed ?? this.maxDiscountAllowed,
      discountApplied: discountApplied ?? this.discountApplied,
      discountJustification: discountJustification ?? this.discountJustification,
    );
  }
}
