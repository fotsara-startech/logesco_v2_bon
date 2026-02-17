/// Modèle de données pour un fournisseur
class Supplier {
  final int id;
  final String nom;
  final String? personneContact;
  final String? telephone;
  final String? email;
  final String? adresse;
  final DateTime dateCreation;
  final DateTime dateModification;

  Supplier({
    required this.id,
    required this.nom,
    this.personneContact,
    this.telephone,
    this.email,
    this.adresse,
    required this.dateCreation,
    required this.dateModification,
  });

  /// Crée un fournisseur à partir d'un JSON
  factory Supplier.fromJson(Map<String, dynamic> json) {
    // Gestion flexible des noms de champs pour les dates
    String? dateCreationStr = json['dateCreation'] as String? ?? json['date_creation'] as String? ?? json['created_at'] as String?;
    String? dateModificationStr = json['dateModification'] as String? ?? json['date_modification'] as String? ?? json['updated_at'] as String?;

    return Supplier(
      id: json['id'] as int,
      nom: json['nom'] as String,
      personneContact: json['personneContact'] as String? ?? json['personne_contact'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      adresse: json['adresse'] as String?,
      dateCreation: dateCreationStr != null ? DateTime.parse(dateCreationStr) : DateTime.now(),
      dateModification: dateModificationStr != null ? DateTime.parse(dateModificationStr) : DateTime.now(),
    );
  }

  /// Convertit le fournisseur en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'personneContact': personneContact,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
    };
  }

  /// Crée une copie du fournisseur avec des modifications
  Supplier copyWith({
    int? id,
    String? nom,
    String? personneContact,
    String? telephone,
    String? email,
    String? adresse,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Supplier(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      personneContact: personneContact ?? this.personneContact,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  @override
  String toString() {
    return 'Supplier(id: $id, nom: $nom, telephone: $telephone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour la création/modification d'un fournisseur
class SupplierForm {
  final String nom;
  final String? personneContact;
  final String? telephone;
  final String? email;
  final String? adresse;

  SupplierForm({
    required this.nom,
    this.personneContact,
    this.telephone,
    this.email,
    this.adresse,
  });

  /// Convertit le formulaire en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'personneContact': personneContact,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
    };
  }

  /// Crée un formulaire à partir d'un fournisseur existant
  factory SupplierForm.fromSupplier(Supplier supplier) {
    return SupplierForm(
      nom: supplier.nom,
      personneContact: supplier.personneContact,
      telephone: supplier.telephone,
      email: supplier.email,
      adresse: supplier.adresse,
    );
  }

  /// Crée une copie du formulaire avec des modifications
  SupplierForm copyWith({
    String? nom,
    String? personneContact,
    String? telephone,
    String? email,
    String? adresse,
  }) {
    return SupplierForm(
      nom: nom ?? this.nom,
      personneContact: personneContact ?? this.personneContact,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
    );
  }
}

/// Modèle pour l'historique des transactions d'un fournisseur
class SupplierTransaction {
  final int id;
  final int supplierId;
  final String type; // 'achat', 'paiement', 'ajustement'
  final double montant;
  final String? description;
  final String? reference;
  final DateTime dateTransaction;

  SupplierTransaction({
    required this.id,
    required this.supplierId,
    required this.type,
    required this.montant,
    this.description,
    this.reference,
    required this.dateTransaction,
  });

  factory SupplierTransaction.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
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

    int parseInt(dynamic value, {int defaultValue = 0}) {
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

    DateTime parseDate(dynamic value, {DateTime? defaultValue}) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue ?? DateTime.now();
        }
      }
      return defaultValue ?? DateTime.now();
    }

    return SupplierTransaction(
      id: parseInt(json['id']),
      supplierId: parseInt(json['supplier_id']),
      type: json['type']?.toString() ?? '',
      montant: parseDouble(json['montant']),
      description: json['description']?.toString(),
      reference: json['reference']?.toString(),
      dateTransaction: parseDate(json['date_transaction']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'type': type,
      'montant': montant,
      'description': description,
      'reference': reference,
      'date_transaction': dateTransaction.toIso8601String(),
    };
  }
}
