/// Modèle de données pour un client
class Customer {
  final int id;
  final String nom;
  final String? prenom;
  final String? telephone;
  final String? email;
  final String? adresse;
  final double solde;
  final DateTime dateCreation;
  final DateTime dateModification;

  Customer({
    required this.id,
    required this.nom,
    this.prenom,
    this.telephone,
    this.email,
    this.adresse,
    this.solde = 0.0,
    required this.dateCreation,
    required this.dateModification,
  });

  /// Nom complet du client
  String get nomComplet => prenom != null ? '$nom $prenom' : nom;

  /// Crée un client à partir d'un JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    // Gestion flexible des noms de champs pour les dates
    String? dateCreationStr = json['date_creation'] as String? ?? json['dateCreation'] as String? ?? json['created_at'] as String?;
    String? dateModificationStr = json['date_modification'] as String? ?? json['dateModification'] as String? ?? json['updated_at'] as String?;

    return Customer(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      adresse: json['adresse'] as String?,
      solde: (json['solde'] as num?)?.toDouble() ?? 0.0,
      dateCreation: dateCreationStr != null ? DateTime.parse(dateCreationStr) : DateTime.now(),
      dateModification: dateModificationStr != null ? DateTime.parse(dateModificationStr) : DateTime.now(),
    );
  }

  /// Convertit le client en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'solde': solde,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification.toIso8601String(),
    };
  }

  /// Crée une copie du client avec des modifications
  Customer copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? adresse,
    double? solde,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Customer(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      solde: solde ?? this.solde,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, nom: $nomComplet, telephone: $telephone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour la création/modification d'un client
class CustomerForm {
  final String nom;
  final String? prenom;
  final String? telephone;
  final String? email;
  final String? adresse;

  CustomerForm({
    required this.nom,
    this.prenom,
    this.telephone,
    this.email,
    this.adresse,
  });

  /// Convertit le formulaire en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
    };
  }

  /// Crée un formulaire à partir d'un client existant
  factory CustomerForm.fromCustomer(Customer customer) {
    return CustomerForm(
      nom: customer.nom,
      prenom: customer.prenom,
      telephone: customer.telephone,
      email: customer.email,
      adresse: customer.adresse,
    );
  }

  /// Crée une copie du formulaire avec des modifications
  CustomerForm copyWith({
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? adresse,
  }) {
    return CustomerForm(
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
    );
  }
}
