// Modèles pour la gestion du stock avec désérialisation JSON sécurisée

class Stock {
  final int id;
  final int produitId;
  final int quantiteDisponible;
  final int quantiteReservee;
  final DateTime derniereMaj;
  final Product? produit;
  final bool? stockFaible;
  final List<StockMovement>? mouvementsRecents;

  Stock({
    required this.id,
    required this.produitId,
    required this.quantiteDisponible,
    required this.quantiteReservee,
    required this.derniereMaj,
    this.produit,
    this.stockFaible,
    this.mouvementsRecents,
  });

  int get quantiteTotale => quantiteDisponible + quantiteReservee;

  factory Stock.fromJson(Map<String, dynamic> json) {
    try {
      final id = _safeExtractInt(json, ['id']);
      final produitId = _safeExtractInt(json, ['produitId', 'productId', 'product_id']);
      final quantiteDisponible = _safeExtractInt(json, ['quantiteDisponible', 'quantite_disponible', 'availableQuantity', 'available_quantity']);
      final quantiteReservee = _safeExtractInt(json, ['quantiteReservee', 'quantite_reservee', 'reservedQuantity', 'reserved_quantity']);

      // Gestion robuste de la date
      DateTime derniereMaj = DateTime.now();
      try {
        final dateStr = json['derniereMaj'] as String? ??
            json['derniere_maj'] as String? ??
            json['lastUpdate'] as String? ??
            json['last_update'] as String? ??
            json['updatedAt'] as String? ??
            json['updated_at'] as String?;
        if (dateStr != null) {
          derniereMaj = DateTime.parse(dateStr);
        }
      } catch (e) {
        derniereMaj = DateTime.now();
      }

      Product? produit;
      if (json['produit'] != null) {
        try {
          final produitData = json['produit'];
          if (produitData is Map<String, dynamic>) {
            produit = Product.fromJson(produitData);
          } else {
            produit = null;
          }
        } catch (e) {
          produit = null;
        }
      }

      final stockFaible = json['stockFaible'] as bool?;

      return Stock(
        id: id,
        produitId: produitId,
        quantiteDisponible: quantiteDisponible,
        quantiteReservee: quantiteReservee,
        derniereMaj: derniereMaj,
        produit: produit,
        stockFaible: stockFaible,
        mouvementsRecents: null, // Temporairement ignoré pour éviter les erreurs
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produitId': produitId,
      'quantiteDisponible': quantiteDisponible,
      'quantiteReservee': quantiteReservee,
      'derniereMaj': derniereMaj.toIso8601String(),
      'produit': produit?.toJson(),
      'stockFaible': stockFaible,
      'mouvementsRecents': mouvementsRecents?.map((e) => e.toJson()).toList(),
    };
  }

  // Méthode helper pour extraire des entiers de manière sécurisée
  static int _safeExtractInt(Map<String, dynamic> json, List<String> keys) {
    for (String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        final value = json[key];
        try {
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) {
            final parsed = int.tryParse(value);
            if (parsed != null) return parsed;
          }
          if (value is num) return value.toInt();
        } catch (e) {
          continue;
        }
      }
    }
    return 0;
  }

  // Méthode helper pour parser les mouvements de manière sécurisée
  static List<StockMovement>? _parseMovements(dynamic movementsData) {
    if (movementsData == null) return null;

    try {
      if (movementsData is List) {
        final movements = <StockMovement>[];
        for (final item in movementsData) {
          try {
            if (item is Map<String, dynamic>) {
              movements.add(StockMovement.fromJson(item));
            }
          } catch (e) {
            // Ignorer les mouvements avec erreur
          }
        }
        return movements.isEmpty ? null : movements;
      }
    } catch (e) {
      // Ignorer les erreurs de parsing des mouvements
    }

    return null;
  }
}

class Product {
  final int id;
  final String reference;
  final String nom;
  final int seuilStockMinimum;
  final bool? estActif;
  final int? stockActuel;

  Product({
    required this.id,
    required this.reference,
    required this.nom,
    required this.seuilStockMinimum,
    this.estActif,
    this.stockActuel,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _safeExtractInt(json, ['id']),
      reference: json['reference'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      seuilStockMinimum: _safeExtractInt(json, ['seuilStockMinimum', 'seuil_stock_minimum', 'minStockLevel']),
      estActif: json['estActif'] as bool?,
      stockActuel: _safeExtractInt(json, ['stockActuel', 'stock_actuel']),
    );
  }

  // Méthode helper pour extraire des entiers de manière sécurisée
  static int _safeExtractInt(Map<String, dynamic> json, List<String> keys) {
    for (String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        final value = json[key];
        try {
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) {
            final parsed = int.tryParse(value);
            if (parsed != null) return parsed;
          }
          if (value is num) return value.toInt();
        } catch (e) {
          continue;
        }
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'nom': nom,
      'seuilStockMinimum': seuilStockMinimum,
      'estActif': estActif,
      'stockActuel': stockActuel,
    };
  }
}

class StockMovement {
  final int id;
  final int produitId;
  final String typeMouvement;
  final int changementQuantite;
  final DateTime dateMouvement;
  final String? notes;
  final Product? produit;

  StockMovement({
    required this.id,
    required this.produitId,
    required this.typeMouvement,
    required this.changementQuantite,
    required this.dateMouvement,
    this.notes,
    this.produit,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: _safeExtractInt(json, ['id']),
      produitId: _safeExtractInt(json, ['produitId', 'productId', 'product_id']),
      typeMouvement: json['typeMouvement'] as String? ?? '',
      changementQuantite: _safeExtractInt(json, ['changementQuantite', 'changement_quantite', 'quantityChange']),
      dateMouvement: json['dateMouvement'] != null ? DateTime.parse(json['dateMouvement'] as String) : DateTime.now(),
      notes: json['notes'] as String?,
      produit: json['produit'] != null ? Product.fromJson(json['produit'] as Map<String, dynamic>) : null,
    );
  }

  // Méthode helper pour extraire des entiers de manière sécurisée
  static int _safeExtractInt(Map<String, dynamic> json, List<String> keys) {
    for (String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        final value = json[key];
        try {
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) {
            final parsed = int.tryParse(value);
            if (parsed != null) return parsed;
          }
          if (value is num) return value.toInt();
        } catch (e) {
          continue;
        }
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produitId': produitId,
      'typeMouvement': typeMouvement,
      'changementQuantite': changementQuantite,
      'dateMouvement': dateMouvement.toIso8601String(),
      'notes': notes,
      'produit': produit?.toJson(),
    };
  }
}

class StockSummary {
  final int totalProduits;
  final int produitsEnStock;
  final int produitsEnAlerte;
  final int produitsEnRupture;
  final double valeurTotaleStock; // Compatibilité (valeur de vente)
  final double? valeurStockAchat;
  final double? valeurStockVente;
  final int pourcentageEnStock;
  final int pourcentageEnAlerte;
  final int pourcentageEnRupture;

  StockSummary({
    required this.totalProduits,
    required this.produitsEnStock,
    required this.produitsEnAlerte,
    required this.produitsEnRupture,
    required this.valeurTotaleStock,
    this.valeurStockAchat,
    this.valeurStockVente,
    required this.pourcentageEnStock,
    required this.pourcentageEnAlerte,
    required this.pourcentageEnRupture,
  });

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    return StockSummary(
      totalProduits: (json['totalProduits'] as num?)?.toInt() ?? 0,
      produitsEnStock: (json['produitsEnStock'] as num?)?.toInt() ?? 0,
      produitsEnAlerte: (json['produitsEnAlerte'] as num?)?.toInt() ?? 0,
      produitsEnRupture: (json['produitsEnRupture'] as num?)?.toInt() ?? 0,
      valeurTotaleStock: (json['valeurTotaleStock'] as num?)?.toDouble() ?? 0.0,
      valeurStockAchat: (json['valeurStockAchat'] as num?)?.toDouble(),
      valeurStockVente: (json['valeurStockVente'] as num?)?.toDouble(),
      pourcentageEnStock: (json['pourcentageEnStock'] as num?)?.toInt() ?? 0,
      pourcentageEnAlerte: (json['pourcentageEnAlerte'] as num?)?.toInt() ?? 0,
      pourcentageEnRupture: (json['pourcentageEnRupture'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProduits': totalProduits,
      'produitsEnStock': produitsEnStock,
      'produitsEnAlerte': produitsEnAlerte,
      'produitsEnRupture': produitsEnRupture,
      'valeurTotaleStock': valeurTotaleStock,
      'valeurStockAchat': valeurStockAchat,
      'valeurStockVente': valeurStockVente,
      'pourcentageEnStock': pourcentageEnStock,
      'pourcentageEnAlerte': pourcentageEnAlerte,
      'pourcentageEnRupture': pourcentageEnRupture,
    };
  }
}

class StockAdjustment {
  final int produitId;
  final int changementQuantite;
  final String? notes;

  StockAdjustment({
    required this.produitId,
    required this.changementQuantite,
    this.notes,
  });

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    return StockAdjustment(
      produitId: (json['produitId'] as num?)?.toInt() ?? 0,
      changementQuantite: (json['changementQuantite'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produitId': produitId,
      'changementQuantite': changementQuantite,
      'notes': notes,
    };
  }
}

class BulkAdjustmentRequest {
  final List<StockAdjustment> ajustements;
  final String? notes;

  BulkAdjustmentRequest({
    required this.ajustements,
    this.notes,
  });

  factory BulkAdjustmentRequest.fromJson(Map<String, dynamic> json) {
    return BulkAdjustmentRequest(
      ajustements: (json['ajustements'] as List<dynamic>?)?.map((e) => StockAdjustment.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ajustements': ajustements.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }
}

class BulkAdjustmentResponse {
  final int ajustementsReussis;
  final int ajustementsEchoues;
  final List<AdjustmentResult> resultats;
  final List<AdjustmentError> erreurs;

  BulkAdjustmentResponse({
    required this.ajustementsReussis,
    required this.ajustementsEchoues,
    required this.resultats,
    required this.erreurs,
  });

  factory BulkAdjustmentResponse.fromJson(Map<String, dynamic> json) {
    return BulkAdjustmentResponse(
      ajustementsReussis: (json['ajustementsReussis'] as num?)?.toInt() ?? 0,
      ajustementsEchoues: (json['ajustementsEchoues'] as num?)?.toInt() ?? 0,
      resultats: (json['resultats'] as List<dynamic>?)?.map((e) => AdjustmentResult.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      erreurs: (json['erreurs'] as List<dynamic>?)?.map((e) => AdjustmentError.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ajustementsReussis': ajustementsReussis,
      'ajustementsEchoues': ajustementsEchoues,
      'resultats': resultats.map((e) => e.toJson()).toList(),
      'erreurs': erreurs.map((e) => e.toJson()).toList(),
    };
  }
}

class AdjustmentResult {
  final int produitId;
  final int changementQuantite;
  final int nouvelleQuantite;
  final bool succes;

  AdjustmentResult({
    required this.produitId,
    required this.changementQuantite,
    required this.nouvelleQuantite,
    required this.succes,
  });

  factory AdjustmentResult.fromJson(Map<String, dynamic> json) {
    return AdjustmentResult(
      produitId: (json['produitId'] as num?)?.toInt() ?? 0,
      changementQuantite: (json['changementQuantite'] as num?)?.toInt() ?? 0,
      nouvelleQuantite: (json['nouvelleQuantite'] as num?)?.toInt() ?? 0,
      succes: json['succes'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produitId': produitId,
      'changementQuantite': changementQuantite,
      'nouvelleQuantite': nouvelleQuantite,
      'succes': succes,
    };
  }
}

class AdjustmentError {
  final int produitId;
  final String erreur;

  AdjustmentError({
    required this.produitId,
    required this.erreur,
  });

  factory AdjustmentError.fromJson(Map<String, dynamic> json) {
    return AdjustmentError(
      produitId: (json['produitId'] as num?)?.toInt() ?? 0,
      erreur: json['erreur'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produitId': produitId,
      'erreur': erreur,
    };
  }
}
