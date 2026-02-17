class ProductAnalytics {
  final ProductInfo produit;
  final ProductStatistics statistiques;
  final String? recommandation;

  ProductAnalytics({
    required this.produit,
    required this.statistiques,
    this.recommandation,
  });

  factory ProductAnalytics.fromJson(Map<String, dynamic> json) {
    return ProductAnalytics(
      produit: ProductInfo.fromJson(json['produit']),
      statistiques: ProductStatistics.fromJson(json['statistiques']),
      recommandation: json['recommandation'],
    );
  }
}

class ProductInfo {
  final int id;
  final String nom;
  final String reference;
  final double prixUnitaire;
  final double? prixAchat;
  final bool estService;
  final CategoryInfo? categorie;

  ProductInfo({
    required this.id,
    required this.nom,
    required this.reference,
    required this.prixUnitaire,
    this.prixAchat,
    required this.estService,
    this.categorie,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'],
      nom: json['nom'],
      reference: json['reference'],
      prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
      prixAchat: json['prixAchat'] != null ? (json['prixAchat'] as num).toDouble() : null,
      estService: json['estService'] ?? false,
      categorie: json['categorie'] != null ? CategoryInfo.fromJson(json['categorie']) : null,
    );
  }
}

class CategoryInfo {
  final int id;
  final String nom;

  CategoryInfo({
    required this.id,
    required this.nom,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'],
      nom: json['nom'],
    );
  }
}

class ProductStatistics {
  final int quantiteVendue;
  final double chiffreAffaires;
  final int nombreTransactions;
  final double prixMoyenVente;
  final double margeUnitaire;
  final double pourcentageMarge;

  ProductStatistics({
    required this.quantiteVendue,
    required this.chiffreAffaires,
    required this.nombreTransactions,
    required this.prixMoyenVente,
    required this.margeUnitaire,
    required this.pourcentageMarge,
  });

  factory ProductStatistics.fromJson(Map<String, dynamic> json) {
    return ProductStatistics(
      quantiteVendue: json['quantiteVendue'] ?? 0,
      chiffreAffaires: (json['chiffreAffaires'] as num).toDouble(),
      nombreTransactions: json['nombreTransactions'] ?? 0,
      prixMoyenVente: (json['prixMoyenVente'] as num).toDouble(),
      margeUnitaire: (json['margeUnitaire'] as num).toDouble(),
      pourcentageMarge: (json['pourcentageMarge'] as num).toDouble(),
    );
  }
}

class GlobalStatistics {
  final int nombreProduitsVendus;
  final double chiffreAffairesTotal;
  final int quantiteTotaleVendue;
  final int nombreTransactionsTotal;

  GlobalStatistics({
    required this.nombreProduitsVendus,
    required this.chiffreAffairesTotal,
    required this.quantiteTotaleVendue,
    required this.nombreTransactionsTotal,
  });

  factory GlobalStatistics.fromJson(Map<String, dynamic> json) {
    return GlobalStatistics(
      nombreProduitsVendus: json['nombreProduitsVendus'] ?? 0,
      chiffreAffairesTotal: (json['chiffreAffairesTotal'] as num).toDouble(),
      quantiteTotaleVendue: json['quantiteTotaleVendue'] ?? 0,
      nombreTransactionsTotal: json['nombreTransactionsTotal'] ?? 0,
    );
  }
}

class ProductAnalyticsResponse {
  final PeriodInfo periode;
  final FilterInfo filtres;
  final GlobalStatistics statistiquesGlobales;
  final List<ProductAnalytics> produits;
  final List<ProductAnalytics> produitsAFaiblePerformance;

  ProductAnalyticsResponse({
    required this.periode,
    required this.filtres,
    required this.statistiquesGlobales,
    required this.produits,
    required this.produitsAFaiblePerformance,
  });

  factory ProductAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return ProductAnalyticsResponse(
      periode: PeriodInfo.fromJson(json['periode']),
      filtres: FilterInfo.fromJson(json['filtres']),
      statistiquesGlobales: GlobalStatistics.fromJson(json['statistiquesGlobales']),
      produits: (json['produits'] as List)
          .map((item) => ProductAnalytics.fromJson(item))
          .toList(),
      produitsAFaiblePerformance: (json['produitsAFaiblePerformance'] as List)
          .map((item) => ProductAnalytics.fromJson(item))
          .toList(),
    );
  }
}

class PeriodInfo {
  final String? dateDebut;
  final String? dateFin;

  PeriodInfo({
    this.dateDebut,
    this.dateFin,
  });

  factory PeriodInfo.fromJson(Map<String, dynamic> json) {
    return PeriodInfo(
      dateDebut: json['dateDebut'],
      dateFin: json['dateFin'],
    );
  }
}

class FilterInfo {
  final int? categorieId;
  final bool includeServices;

  FilterInfo({
    this.categorieId,
    required this.includeServices,
  });

  factory FilterInfo.fromJson(Map<String, dynamic> json) {
    return FilterInfo(
      categorieId: json['categorieId'],
      includeServices: json['includeServices'] ?? true,
    );
  }
}