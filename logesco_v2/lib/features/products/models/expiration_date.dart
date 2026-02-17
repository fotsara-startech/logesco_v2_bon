/// Modèle pour les dates de péremption des produits
class ExpirationDate {
  final int id;
  final int produitId;
  final DateTime datePeremption;
  final int quantite;
  final String? numeroLot;
  final DateTime dateEntree;
  final String? notes;
  final bool estEpuise;
  final DateTime dateCreation;
  final DateTime dateModification;

  // Champs calculés
  final int joursRestants;
  final bool estPerime;
  final bool estProcheDeLaPeremption;
  final String niveauAlerte;

  // Produit associé (optionnel)
  final ProductInfo? produit;

  ExpirationDate({
    required this.id,
    required this.produitId,
    required this.datePeremption,
    required this.quantite,
    this.numeroLot,
    required this.dateEntree,
    this.notes,
    required this.estEpuise,
    required this.dateCreation,
    required this.dateModification,
    required this.joursRestants,
    required this.estPerime,
    required this.estProcheDeLaPeremption,
    required this.niveauAlerte,
    this.produit,
  });

  factory ExpirationDate.fromJson(Map<String, dynamic> json) {
    return ExpirationDate(
      id: json['id'] as int,
      produitId: json['produitId'] as int,
      datePeremption: DateTime.parse(json['datePeremption'] as String),
      quantite: json['quantite'] as int,
      numeroLot: json['numeroLot'] as String?,
      dateEntree: DateTime.parse(json['dateEntree'] as String),
      notes: json['notes'] as String?,
      estEpuise: json['estEpuise'] as bool? ?? false,
      dateCreation: DateTime.parse(json['dateCreation'] as String),
      dateModification: DateTime.parse(json['dateModification'] as String),
      joursRestants: json['joursRestants'] as int,
      estPerime: json['estPerime'] as bool,
      estProcheDeLaPeremption: json['estProcheDeLaPeremption'] as bool,
      niveauAlerte: json['niveauAlerte'] as String,
      produit: json['produit'] != null ? ProductInfo.fromJson(json['produit'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produitId': produitId,
      'datePeremption': datePeremption.toIso8601String(),
      'quantite': quantite,
      'numeroLot': numeroLot,
      'dateEntree': dateEntree.toIso8601String(),
      'notes': notes,
      'estEpuise': estEpuise,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      'joursRestants': joursRestants,
      'estPerime': estPerime,
      'estProcheDeLaPeremption': estProcheDeLaPeremption,
      'niveauAlerte': niveauAlerte,
      'produit': produit?.toJson(),
    };
  }

  /// Retourne la couleur associée au niveau d'alerte
  String getAlertColor() {
    switch (niveauAlerte) {
      case 'perime':
        return '#EF4444'; // Rouge
      case 'critique':
        return '#F97316'; // Orange foncé
      case 'avertissement':
        return '#F59E0B'; // Orange
      case 'attention':
        return '#EAB308'; // Jaune
      default:
        return '#10B981'; // Vert
    }
  }

  /// Retourne le libellé du niveau d'alerte
  String getAlertLabel() {
    switch (niveauAlerte) {
      case 'perime':
        return 'Périmé';
      case 'critique':
        return 'Critique';
      case 'avertissement':
        return 'Avertissement';
      case 'attention':
        return 'Attention';
      default:
        return 'Normal';
    }
  }

  /// Retourne une description du statut
  String getStatusDescription() {
    if (estEpuise) {
      return 'Épuisé';
    }
    if (estPerime) {
      return 'Périmé depuis ${joursRestants.abs()} jour(s)';
    }
    if (joursRestants == 0) {
      return 'Expire aujourd\'hui';
    }
    if (joursRestants == 1) {
      return 'Expire demain';
    }
    return 'Expire dans $joursRestants jour(s)';
  }

  ExpirationDate copyWith({
    int? id,
    int? produitId,
    DateTime? datePeremption,
    int? quantite,
    String? numeroLot,
    DateTime? dateEntree,
    String? notes,
    bool? estEpuise,
    DateTime? dateCreation,
    DateTime? dateModification,
    int? joursRestants,
    bool? estPerime,
    bool? estProcheDeLaPeremption,
    String? niveauAlerte,
    ProductInfo? produit,
  }) {
    return ExpirationDate(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      datePeremption: datePeremption ?? this.datePeremption,
      quantite: quantite ?? this.quantite,
      numeroLot: numeroLot ?? this.numeroLot,
      dateEntree: dateEntree ?? this.dateEntree,
      notes: notes ?? this.notes,
      estEpuise: estEpuise ?? this.estEpuise,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      joursRestants: joursRestants ?? this.joursRestants,
      estPerime: estPerime ?? this.estPerime,
      estProcheDeLaPeremption: estProcheDeLaPeremption ?? this.estProcheDeLaPeremption,
      niveauAlerte: niveauAlerte ?? this.niveauAlerte,
      produit: produit ?? this.produit,
    );
  }
}

/// Informations basiques du produit
class ProductInfo {
  final int id;
  final String reference;
  final String nom;
  final double? prixUnitaire;
  final double? prixAchat;

  ProductInfo({
    required this.id,
    required this.reference,
    required this.nom,
    this.prixUnitaire,
    this.prixAchat,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] as int,
      reference: json['reference'] as String,
      nom: json['nom'] as String,
      prixUnitaire: json['prixUnitaire'] != null ? (json['prixUnitaire'] as num).toDouble() : null,
      prixAchat: json['prixAchat'] != null ? (json['prixAchat'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'nom': nom,
      'prixUnitaire': prixUnitaire,
      'prixAchat': prixAchat,
    };
  }
}

/// Statistiques des alertes de péremption
class ExpirationAlertStats {
  final int totalAlertes;
  final int perimes;
  final int critiques;
  final int avertissements;
  final double valeurTotale;

  ExpirationAlertStats({
    required this.totalAlertes,
    required this.perimes,
    required this.critiques,
    required this.avertissements,
    required this.valeurTotale,
  });

  factory ExpirationAlertStats.fromJson(Map<String, dynamic> json) {
    return ExpirationAlertStats(
      totalAlertes: json['totalAlertes'] as int? ?? 0,
      perimes: json['perimes'] as int? ?? 0,
      critiques: json['critiques'] as int? ?? 0,
      avertissements: json['avertissements'] as int? ?? 0,
      valeurTotale: (json['valeurTotale'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAlertes': totalAlertes,
      'perimes': perimes,
      'critiques': critiques,
      'avertissements': avertissements,
      'valeurTotale': valeurTotale,
    };
  }
}
