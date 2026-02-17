/// Modèle pour l'inventaire de stock
class StockInventory {
  final int? id;
  final String nom;
  final String description;
  final InventoryType type; // PARTIEL ou TOTAL
  final InventoryStatus status;
  final int? categorieId;
  final String? nomCategorie;
  final int utilisateurId;
  final String nomUtilisateur;
  final DateTime dateCreation;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final List<InventoryItem> items;
  final InventoryStats? stats;

  StockInventory({
    this.id,
    required this.nom,
    this.description = '',
    required this.type,
    this.status = InventoryStatus.BROUILLON,
    this.categorieId,
    this.nomCategorie,
    required this.utilisateurId,
    required this.nomUtilisateur,
    required this.dateCreation,
    this.dateDebut,
    this.dateFin,
    this.items = const [],
    this.stats,
  });

  factory StockInventory.fromJson(Map<String, dynamic> json) {
    return StockInventory(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      type: InventoryType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => InventoryType.TOTAL,
      ),
      status: InventoryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InventoryStatus.BROUILLON,
      ),
      categorieId: json['categorieId'],
      nomCategorie: json['nomCategorie'],
      utilisateurId: json['utilisateurId'],
      nomUtilisateur: json['nomUtilisateur'] ?? '',
      dateCreation: DateTime.parse(json['dateCreation']),
      dateDebut: json['dateDebut'] != null ? DateTime.parse(json['dateDebut']) : null,
      dateFin: json['dateFin'] != null ? DateTime.parse(json['dateFin']) : null,
      items: (json['items'] as List<dynamic>?)?.map((item) => InventoryItem.fromJson(item)).toList() ?? [],
      stats: json['stats'] != null ? InventoryStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'categorieId': categorieId,
      'nomCategorie': nomCategorie,
      'utilisateurId': utilisateurId,
      'nomUtilisateur': nomUtilisateur,
      'dateCreation': dateCreation.toIso8601String(),
      'dateDebut': dateDebut?.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'stats': stats?.toJson(),
    };
  }

  StockInventory copyWith({
    int? id,
    String? nom,
    String? description,
    InventoryType? type,
    InventoryStatus? status,
    int? categorieId,
    String? nomCategorie,
    int? utilisateurId,
    String? nomUtilisateur,
    DateTime? dateCreation,
    DateTime? dateDebut,
    DateTime? dateFin,
    List<InventoryItem>? items,
    InventoryStats? stats,
  }) {
    return StockInventory(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      categorieId: categorieId ?? this.categorieId,
      nomCategorie: nomCategorie ?? this.nomCategorie,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      dateCreation: dateCreation ?? this.dateCreation,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      items: items ?? this.items,
      stats: stats ?? this.stats,
    );
  }

  /// Vérifie si l'inventaire peut être modifié
  bool get canBeModified => status == InventoryStatus.BROUILLON || status == InventoryStatus.EN_COURS;

  /// Vérifie si l'inventaire peut être démarré
  bool get canBeStarted => status == InventoryStatus.BROUILLON;

  /// Vérifie si l'inventaire peut être clôturé
  bool get canBeClosed => status == InventoryStatus.EN_COURS;

  /// Retourne le pourcentage de progression
  double get progressPercentage {
    if (items.isEmpty) return 0.0;
    final countedItems = items.where((item) => item.quantiteComptee != null).length;
    return (countedItems / items.length) * 100;
  }
}

/// Types d'inventaire
enum InventoryType {
  PARTIEL,
  TOTAL,
}

/// Statuts d'inventaire
enum InventoryStatus {
  BROUILLON,
  EN_COURS,
  TERMINE,
  CLOTURE,
}

/// Extension pour les types d'inventaire
extension InventoryTypeExtension on InventoryType {
  String get displayName {
    switch (this) {
      case InventoryType.PARTIEL:
        return 'Inventaire Partiel';
      case InventoryType.TOTAL:
        return 'Inventaire Total';
    }
  }

  String get description {
    switch (this) {
      case InventoryType.PARTIEL:
        return 'Inventaire par catégorie sélectionnée';
      case InventoryType.TOTAL:
        return 'Inventaire complet de tous les produits';
    }
  }
}

/// Extension pour les statuts d'inventaire
extension InventoryStatusExtension on InventoryStatus {
  String get displayName {
    switch (this) {
      case InventoryStatus.BROUILLON:
        return 'Brouillon';
      case InventoryStatus.EN_COURS:
        return 'En cours';
      case InventoryStatus.TERMINE:
        return 'Terminé';
      case InventoryStatus.CLOTURE:
        return 'Clôturé';
    }
  }
}

/// Modèle pour un article d'inventaire
class InventoryItem {
  final int? id;
  final int inventaireId;
  final int produitId;
  final String nomProduit;
  final String? codeProduit;
  final String? categorieProduit;
  final double quantiteSysteme;
  final double? quantiteComptee;
  final double? ecart;
  final String? commentaire;
  final DateTime? dateComptage;
  final int? utilisateurComptageId;
  final String? nomUtilisateurComptage;
  final double? prixUnitaire; // Prix unitaire du produit
  final double? prixAchat; // Prix d'achat du produit

  InventoryItem({
    this.id,
    required this.inventaireId,
    required this.produitId,
    required this.nomProduit,
    this.codeProduit,
    this.categorieProduit,
    required this.quantiteSysteme,
    this.quantiteComptee,
    this.ecart,
    this.commentaire,
    this.dateComptage,
    this.utilisateurComptageId,
    this.nomUtilisateurComptage,
    this.prixUnitaire,
    this.prixAchat,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      inventaireId: json['inventaireId'],
      produitId: json['produitId'],
      nomProduit: json['nomProduit'] ?? '',
      codeProduit: json['codeProduit'],
      categorieProduit: json['categorieProduit'],
      quantiteSysteme: (json['quantiteSysteme'] ?? 0.0).toDouble(),
      quantiteComptee: json['quantiteComptee']?.toDouble(),
      ecart: json['ecart']?.toDouble(),
      commentaire: json['commentaire'],
      dateComptage: json['dateComptage'] != null ? DateTime.parse(json['dateComptage']) : null,
      utilisateurComptageId: json['utilisateurComptageId'],
      nomUtilisateurComptage: json['nomUtilisateurComptage'],
      prixUnitaire: json['prixUnitaire']?.toDouble(),
      prixAchat: json['prixAchat']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventaireId': inventaireId,
      'produitId': produitId,
      'nomProduit': nomProduit,
      'codeProduit': codeProduit,
      'categorieProduit': categorieProduit,
      'quantiteSysteme': quantiteSysteme,
      'quantiteComptee': quantiteComptee,
      'ecart': ecart,
      'commentaire': commentaire,
      'dateComptage': dateComptage?.toIso8601String(),
      'utilisateurComptageId': utilisateurComptageId,
      'nomUtilisateurComptage': nomUtilisateurComptage,
      'prixUnitaire': prixUnitaire,
      'prixAchat': prixAchat,
    };
  }

  InventoryItem copyWith({
    int? id,
    int? inventaireId,
    int? produitId,
    String? nomProduit,
    String? codeProduit,
    String? categorieProduit,
    double? quantiteSysteme,
    double? quantiteComptee,
    double? ecart,
    String? commentaire,
    DateTime? dateComptage,
    int? utilisateurComptageId,
    String? nomUtilisateurComptage,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      inventaireId: inventaireId ?? this.inventaireId,
      produitId: produitId ?? this.produitId,
      nomProduit: nomProduit ?? this.nomProduit,
      codeProduit: codeProduit ?? this.codeProduit,
      categorieProduit: categorieProduit ?? this.categorieProduit,
      quantiteSysteme: quantiteSysteme ?? this.quantiteSysteme,
      quantiteComptee: quantiteComptee ?? this.quantiteComptee,
      ecart: ecart ?? this.ecart,
      commentaire: commentaire ?? this.commentaire,
      dateComptage: dateComptage ?? this.dateComptage,
      utilisateurComptageId: utilisateurComptageId ?? this.utilisateurComptageId,
      nomUtilisateurComptage: nomUtilisateurComptage ?? this.nomUtilisateurComptage,
    );
  }

  /// Vérifie si l'article a été compté
  bool get isCounted => quantiteComptee != null;

  /// Calcule l'écart automatiquement
  double get calculatedEcart {
    if (quantiteComptee == null) return 0.0;
    return quantiteComptee! - quantiteSysteme;
  }

  /// Vérifie s'il y a un écart
  bool get hasVariance => calculatedEcart != 0.0;

  /// Vérifie si l'écart est positif (surplus)
  bool get isPositiveVariance => calculatedEcart > 0.0;

  /// Vérifie si l'écart est négatif (manque)
  bool get isNegativeVariance => calculatedEcart < 0.0;

  /// Calcule la valeur système (quantité système × prix unitaire)
  double get valeurSysteme => quantiteSysteme * (prixUnitaire ?? 0.0);

  /// Calcule la valeur comptée (quantité comptée × prix unitaire)
  double get valeurComptee => (quantiteComptee ?? 0.0) * (prixUnitaire ?? 0.0);

  /// Calcule l'écart de valeur (valeur comptée - valeur système)
  double get ecartValeur => valeurComptee - valeurSysteme;

  /// Calcule la valeur d'achat système (quantité système × prix d'achat)
  double get valeurAchatSysteme => quantiteSysteme * (prixAchat ?? 0.0);

  /// Calcule la valeur d'achat comptée (quantité comptée × prix d'achat)
  double get valeurAchatComptee => (quantiteComptee ?? 0.0) * (prixAchat ?? 0.0);

  /// Calcule l'écart de valeur d'achat
  double get ecartValeurAchat => valeurAchatComptee - valeurAchatSysteme;
}

/// Modèle pour les statistiques d'inventaire
class InventoryStats {
  final int totalItems;
  final int countedItems;
  final int itemsWithVariance;
  final double totalSystemQuantity;
  final double totalCountedQuantity;
  final double totalVariance;
  final double positiveVariance;
  final double negativeVariance;
  final double totalSystemValue; // Valeur totale système
  final double totalCountedValue; // Valeur totale comptée
  final double totalValueVariance; // Écart de valeur total

  InventoryStats({
    required this.totalItems,
    required this.countedItems,
    required this.itemsWithVariance,
    required this.totalSystemQuantity,
    required this.totalCountedQuantity,
    required this.totalVariance,
    required this.positiveVariance,
    required this.negativeVariance,
    this.totalSystemValue = 0.0,
    this.totalCountedValue = 0.0,
    this.totalValueVariance = 0.0,
  });

  factory InventoryStats.fromJson(Map<String, dynamic> json) {
    return InventoryStats(
      totalItems: json['totalItems'] ?? 0,
      countedItems: json['countedItems'] ?? 0,
      itemsWithVariance: json['itemsWithVariance'] ?? 0,
      totalSystemQuantity: (json['totalSystemQuantity'] ?? 0.0).toDouble(),
      totalCountedQuantity: (json['totalCountedQuantity'] ?? 0.0).toDouble(),
      totalVariance: (json['totalVariance'] ?? 0.0).toDouble(),
      positiveVariance: (json['positiveVariance'] ?? 0.0).toDouble(),
      negativeVariance: (json['negativeVariance'] ?? 0.0).toDouble(),
      totalSystemValue: (json['totalSystemValue'] ?? 0.0).toDouble(),
      totalCountedValue: (json['totalCountedValue'] ?? 0.0).toDouble(),
      totalValueVariance: (json['totalValueVariance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'countedItems': countedItems,
      'itemsWithVariance': itemsWithVariance,
      'totalSystemQuantity': totalSystemQuantity,
      'totalCountedQuantity': totalCountedQuantity,
      'totalVariance': totalVariance,
      'positiveVariance': positiveVariance,
      'negativeVariance': negativeVariance,
      'totalSystemValue': totalSystemValue,
      'totalCountedValue': totalCountedValue,
      'totalValueVariance': totalValueVariance,
    };
  }

  /// Calcule le pourcentage de progression
  double get progressPercentage {
    if (totalItems == 0) return 0.0;
    return (countedItems / totalItems) * 100;
  }

  /// Calcule le pourcentage d'articles avec écart
  double get variancePercentage {
    if (countedItems == 0) return 0.0;
    return (itemsWithVariance / countedItems) * 100;
  }
}
