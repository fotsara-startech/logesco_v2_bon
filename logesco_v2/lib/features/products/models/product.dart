/// Modèle de données pour un produit
class Product {
  final int id;
  final String reference;
  final String nom;
  final String? description;
  final double prixUnitaire;
  final double? prixAchat;
  final String? codeBarre;
  final String? categorie;
  final int? categorieId;
  final int seuilStockMinimum;
  final double remiseMaxAutorisee;
  final bool estActif;
  final bool estService;
  final bool gestionPeremption;
  final DateTime dateCreation;
  final DateTime dateModification;

  Product({
    required this.id,
    required this.reference,
    required this.nom,
    this.description,
    required this.prixUnitaire,
    this.prixAchat,
    this.codeBarre,
    this.categorie,
    this.categorieId,
    required this.seuilStockMinimum,
    this.remiseMaxAutorisee = 0.0,
    required this.estActif,
    this.estService = false,
    this.gestionPeremption = false,
    required this.dateCreation,
    required this.dateModification,
  });

  /// Crée un produit à partir d'un JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Debug: Afficher les données reçues pour les catégories
    print('🔍 Product.fromJson - Données catégorie:');
    print('  - categorie: ${json['categorie']}');
    print('  - categorieId: ${json['categorieId']}');
    print('  - JSON complet: $json');

    return Product(
      id: _parseInt(json['id']),
      reference: _parseString(json['reference']),
      nom: _parseString(json['nom']),
      description: json['description']?.toString(),
      prixUnitaire: _parseDouble(json['prixUnitaire']),
      prixAchat: json['prixAchat'] != null ? _parseDouble(json['prixAchat']) : null,
      codeBarre: json['codeBarre']?.toString(),
      categorie: json['categorie']?.toString(),
      categorieId: json['categorieId'] != null ? _parseInt(json['categorieId']) : null,
      seuilStockMinimum: _parseInt(json['seuilStockMinimum']),
      remiseMaxAutorisee: _parseDouble(json['remiseMaxAutorisee']),
      estActif: json['estActif'] as bool? ?? true,
      estService: json['estService'] as bool? ?? false,
      gestionPeremption: json['gestionPeremption'] as bool? ?? false,
      dateCreation: _parseDateTime(json['dateCreation']),
      dateModification: _parseDateTime(json['dateModification']),
    );
  }

  /// Convertit le produit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'nom': nom,
      'description': description,
      'prixUnitaire': prixUnitaire,
      'prixAchat': prixAchat,
      'codeBarre': codeBarre,
      'categorie': categorie,
      'categorieId': categorieId,
      'seuilStockMinimum': seuilStockMinimum,
      'remiseMaxAutorisee': remiseMaxAutorisee,
      'estActif': estActif,
      'estService': estService,
      'gestionPeremption': gestionPeremption,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
    };
  }

  /// Crée une copie du produit avec des modifications
  Product copyWith({
    int? id,
    String? reference,
    String? nom,
    String? description,
    double? prixUnitaire,
    double? prixAchat,
    String? codeBarre,
    String? categorie,
    int? categorieId,
    int? seuilStockMinimum,
    double? remiseMaxAutorisee,
    bool? estActif,
    bool? estService,
    bool? gestionPeremption,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Product(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      prixAchat: prixAchat ?? this.prixAchat,
      codeBarre: codeBarre ?? this.codeBarre,
      categorie: categorie ?? this.categorie,
      categorieId: categorieId ?? this.categorieId,
      seuilStockMinimum: seuilStockMinimum ?? this.seuilStockMinimum,
      remiseMaxAutorisee: remiseMaxAutorisee ?? this.remiseMaxAutorisee,
      estActif: estActif ?? this.estActif,
      estService: estService ?? this.estService,
      gestionPeremption: gestionPeremption ?? this.gestionPeremption,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, reference: $reference, nom: $nom, prixUnitaire: $prixUnitaire, estService: $estService)';
  }

  /// Calcule la marge bénéficiaire si le prix d'achat est disponible
  double? get marge {
    if (prixAchat == null) return null;
    return prixUnitaire - prixAchat!;
  }

  /// Calcule le pourcentage de marge si le prix d'achat est disponible
  double? get pourcentageMarge {
    if (prixAchat == null || prixAchat == 0) return null;
    return ((prixUnitaire - prixAchat!) / prixAchat!) * 100;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Helper pour parser les doubles de manière sûre
  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) {
      return value.isNaN || value.isInfinite ? defaultValue : value;
    }
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null || parsed.isNaN || parsed.isInfinite) {
        return defaultValue;
      }
      return parsed;
    }
    return defaultValue;
  }

  /// Helper pour parser les entiers de manière sûre
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Helper pour parser les chaînes de manière sûre
  static String _parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Helper pour parser les dates de manière sûre
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

/// Modèle pour la création/modification d'un produit
class ProductForm {
  final String reference;
  final String nom;
  final String? description;
  final double prixUnitaire;
  final double? prixAchat;
  final String? codeBarre;
  final String? categorie;
  final int seuilStockMinimum;
  final double remiseMaxAutorisee;
  final bool estActif;
  final bool estService;
  final bool gestionPeremption;

  ProductForm({
    required this.reference,
    required this.nom,
    this.description,
    required this.prixUnitaire,
    this.prixAchat,
    this.codeBarre,
    this.categorie,
    required this.seuilStockMinimum,
    this.remiseMaxAutorisee = 0.0,
    this.estActif = true,
    this.estService = false,
    this.gestionPeremption = false,
  });

  /// Convertit le formulaire en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'nom': nom,
      'description': description,
      'prixUnitaire': prixUnitaire,
      'prixAchat': prixAchat,
      'codeBarre': codeBarre,
      'categorie': categorie,
      'seuilStockMinimum': seuilStockMinimum,
      'remiseMaxAutorisee': remiseMaxAutorisee,
      'estActif': estActif,
      'estService': estService,
      'gestionPeremption': gestionPeremption,
    };
  }

  /// Crée un formulaire à partir d'un produit existant
  factory ProductForm.fromProduct(Product product) {
    return ProductForm(
      reference: product.reference,
      nom: product.nom,
      description: product.description,
      prixUnitaire: product.prixUnitaire,
      prixAchat: product.prixAchat,
      codeBarre: product.codeBarre,
      categorie: product.categorie,
      seuilStockMinimum: product.seuilStockMinimum,
      remiseMaxAutorisee: product.remiseMaxAutorisee,
      estActif: product.estActif,
      estService: product.estService,
      gestionPeremption: product.gestionPeremption,
    );
  }
}
