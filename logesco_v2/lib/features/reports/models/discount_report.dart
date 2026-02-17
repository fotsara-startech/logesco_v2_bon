import 'package:json_annotation/json_annotation.dart';

part 'discount_report.g.dart';

/// Modèle pour les rapports de remises
@JsonSerializable()
class DiscountReport {
  final String groupBy;
  final DiscountPeriod? periode;
  final List<DiscountGroup> groupes;
  final DiscountTotals totaux;

  const DiscountReport({
    required this.groupBy,
    this.periode,
    required this.groupes,
    required this.totaux,
  });

  factory DiscountReport.fromJson(Map<String, dynamic> json) => _$DiscountReportFromJson(json);
  Map<String, dynamic> toJson() => _$DiscountReportToJson(this);
}

@JsonSerializable()
class DiscountPeriod {
  final String? debut;
  final String? fin;

  const DiscountPeriod({
    this.debut,
    this.fin,
  });

  factory DiscountPeriod.fromJson(Map<String, dynamic> json) => _$DiscountPeriodFromJson(json);
  Map<String, dynamic> toJson() => _$DiscountPeriodToJson(this);
}

@JsonSerializable()
class DiscountGroup {
  final String groupe;
  final double totalRemises;
  final int nombreRemises;
  final double remiseMoyenne;
  final double remiseMin;
  final double remiseMax;

  const DiscountGroup({
    required this.groupe,
    required this.totalRemises,
    required this.nombreRemises,
    required this.remiseMoyenne,
    required this.remiseMin,
    required this.remiseMax,
  });

  factory DiscountGroup.fromJson(Map<String, dynamic> json) => _$DiscountGroupFromJson(json);
  Map<String, dynamic> toJson() => _$DiscountGroupToJson(this);
}

@JsonSerializable()
class DiscountTotals {
  final double totalRemises;
  final int nombreRemises;
  final double remiseMoyenneGlobale;

  const DiscountTotals({
    required this.totalRemises,
    required this.nombreRemises,
    required this.remiseMoyenneGlobale,
  });

  factory DiscountTotals.fromJson(Map<String, dynamic> json) => _$DiscountTotalsFromJson(json);
  Map<String, dynamic> toJson() => _$DiscountTotalsToJson(this);
}

/// Modèle pour les ventes avec remises par vendeur
@JsonSerializable()
class VendorDiscountReport {
  final List<SaleWithDiscount> ventes;
  final List<VendorDiscountStats> statistiques;
  final DiscountPagination pagination;

  const VendorDiscountReport({
    required this.ventes,
    required this.statistiques,
    required this.pagination,
  });

  factory VendorDiscountReport.fromJson(Map<String, dynamic> json) => _$VendorDiscountReportFromJson(json);
  Map<String, dynamic> toJson() => _$VendorDiscountReportToJson(this);
}

@JsonSerializable()
class SaleWithDiscount {
  final int id;
  final String numeroVente;
  final DateTime dateVente;
  final VendorInfo? vendeur;
  final CustomerInfo? client;
  final List<DiscountDetail> details;

  const SaleWithDiscount({
    required this.id,
    required this.numeroVente,
    required this.dateVente,
    this.vendeur,
    this.client,
    required this.details,
  });

  factory SaleWithDiscount.fromJson(Map<String, dynamic> json) => _$SaleWithDiscountFromJson(json);
  Map<String, dynamic> toJson() => _$SaleWithDiscountToJson(this);
}

@JsonSerializable()
class VendorInfo {
  final int id;
  final String nomUtilisateur;
  final String? email;

  const VendorInfo({
    required this.id,
    required this.nomUtilisateur,
    this.email,
  });

  factory VendorInfo.fromJson(Map<String, dynamic> json) {
    return VendorInfo(
      id: json['id'] as int? ?? 0,
      nomUtilisateur: json['nomUtilisateur'] as String? ?? '',
      email: json['email'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$VendorInfoToJson(this);
}

@JsonSerializable()
class CustomerInfo {
  final int id;
  final String nom;
  final String? prenom;

  const CustomerInfo({
    required this.id,
    required this.nom,
    this.prenom,
  });

  String get nomComplet => prenom != null ? '$nom $prenom' : nom;

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] as int? ?? 0,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$CustomerInfoToJson(this);
}

@JsonSerializable()
class DiscountDetail {
  final int id;
  final ProductInfo produit;
  final int quantite;
  final double prixAffiche;
  final double remiseAppliquee;
  final String? justificationRemise;
  final double prixUnitaire;

  const DiscountDetail({
    required this.id,
    required this.produit,
    required this.quantite,
    required this.prixAffiche,
    required this.remiseAppliquee,
    this.justificationRemise,
    required this.prixUnitaire,
  });

  double get economieClient => remiseAppliquee * quantite;
  double get pourcentageRemise => prixAffiche > 0 ? (remiseAppliquee / prixAffiche * 100) : 0;

  factory DiscountDetail.fromJson(Map<String, dynamic> json) {
    return DiscountDetail(
      id: json['id'] as int? ?? 0,
      produit: ProductInfo.fromJson(json['produit'] as Map<String, dynamic>? ?? {}),
      quantite: json['quantite'] as int? ?? 0,
      prixAffiche: (json['prixAffiche'] as num?)?.toDouble() ?? 0.0,
      remiseAppliquee: (json['remiseAppliquee'] as num?)?.toDouble() ?? 0.0,
      justificationRemise: json['justificationRemise'] as String?,
      prixUnitaire: (json['prixUnitaire'] as num?)?.toDouble() ?? 0.0,
    );
  }
  Map<String, dynamic> toJson() => _$DiscountDetailToJson(this);
}

@JsonSerializable()
class ProductInfo {
  final int id;
  final String nom;
  final String reference;
  final double? remiseMaxAutorisee;

  const ProductInfo({
    required this.id,
    required this.nom,
    required this.reference,
    this.remiseMaxAutorisee,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] as int? ?? 0,
      nom: json['nom'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      remiseMaxAutorisee: (json['remiseMaxAutorisee'] as num?)?.toDouble(),
    );
  }
  Map<String, dynamic> toJson() => _$ProductInfoToJson(this);
}

@JsonSerializable()
class VendorDiscountStats {
  final VendorInfo vendeur;
  final double totalRemises;
  final int nombreVentes;
  final int nombreProduits;
  final double remiseMoyenne;

  const VendorDiscountStats({
    required this.vendeur,
    required this.totalRemises,
    required this.nombreVentes,
    required this.nombreProduits,
    required this.remiseMoyenne,
  });

  factory VendorDiscountStats.fromJson(Map<String, dynamic> json) => _$VendorDiscountStatsFromJson(json);
  Map<String, dynamic> toJson() => _$VendorDiscountStatsToJson(this);
}

@JsonSerializable()
class DiscountPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const DiscountPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory DiscountPagination.fromJson(Map<String, dynamic> json) => _$DiscountPaginationFromJson(json);
  Map<String, dynamic> toJson() => _$DiscountPaginationToJson(this);
}

/// Modèle pour le top des remises
@JsonSerializable()
class TopDiscount {
  final int id;
  final double remiseAppliquee;
  final double remiseMaxAutorisee;
  final double pourcentageUtilise;
  final String? justification;
  final ProductInfo produit;
  final SaleInfo vente;
  final double prixOriginal;
  final double prixFinal;
  final double economieClient;

  const TopDiscount({
    required this.id,
    required this.remiseAppliquee,
    required this.remiseMaxAutorisee,
    required this.pourcentageUtilise,
    this.justification,
    required this.produit,
    required this.vente,
    required this.prixOriginal,
    required this.prixFinal,
    required this.economieClient,
  });

  factory TopDiscount.fromJson(Map<String, dynamic> json) {
    return TopDiscount(
      id: json['id'] as int? ?? 0,
      remiseAppliquee: (json['remiseAppliquee'] as num?)?.toDouble() ?? 0.0,
      remiseMaxAutorisee: (json['remiseMaxAutorisee'] as num?)?.toDouble() ?? 0.0,
      pourcentageUtilise: (json['pourcentageUtilise'] as num?)?.toDouble() ?? 0.0,
      justification: json['justification'] as String?,
      produit: ProductInfo.fromJson(json['produit'] as Map<String, dynamic>? ?? {}),
      vente: SaleInfo.fromJson(json['vente'] as Map<String, dynamic>? ?? {}),
      prixOriginal: (json['prixOriginal'] as num?)?.toDouble() ?? 0.0,
      prixFinal: (json['prixFinal'] as num?)?.toDouble() ?? 0.0,
      economieClient: (json['economieClient'] as num?)?.toDouble() ?? 0.0,
    );
  }
  Map<String, dynamic> toJson() => _$TopDiscountToJson(this);
}

@JsonSerializable()
class SaleInfo {
  final int id;
  final String numeroVente;
  final DateTime dateVente;
  final VendorInfo? vendeur;
  final CustomerInfo? client;

  const SaleInfo({
    required this.id,
    required this.numeroVente,
    required this.dateVente,
    this.vendeur,
    this.client,
  });

  factory SaleInfo.fromJson(Map<String, dynamic> json) {
    return SaleInfo(
      id: json['id'] as int? ?? 0,
      numeroVente: json['numeroVente'] as String? ?? '',
      dateVente: json['dateVente'] != null ? DateTime.tryParse(json['dateVente'] as String) ?? DateTime.now() : DateTime.now(),
      vendeur: json['vendeur'] != null ? VendorInfo.fromJson(json['vendeur'] as Map<String, dynamic>) : null,
      client: json['client'] != null ? CustomerInfo.fromJson(json['client'] as Map<String, dynamic>) : null,
    );
  }
  Map<String, dynamic> toJson() => _$SaleInfoToJson(this);
}
