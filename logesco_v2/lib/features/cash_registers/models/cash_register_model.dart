/// Modèle pour la gestion des caisses
class CashRegister {
  final int? id;
  final String nom;
  final String description;
  final double soldeInitial;
  final double soldeActuel;
  final bool isActive;
  final int? utilisateurId;
  final String? nomUtilisateur;
  final DateTime? dateCreation;
  final DateTime? dateModification;
  final DateTime? dateOuverture;
  final DateTime? dateFermeture;

  CashRegister({
    this.id,
    required this.nom,
    this.description = '',
    this.soldeInitial = 0.0,
    this.soldeActuel = 0.0,
    this.isActive = true,
    this.utilisateurId,
    this.nomUtilisateur,
    this.dateCreation,
    this.dateModification,
    this.dateOuverture,
    this.dateFermeture,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      soldeInitial: (json['soldeInitial'] ?? 0.0).toDouble(),
      soldeActuel: (json['soldeActuel'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
      utilisateurId: json['utilisateurId'],
      nomUtilisateur: json['nomUtilisateur'],
      dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation']) : null,
      dateModification: json['dateModification'] != null ? DateTime.parse(json['dateModification']) : null,
      dateOuverture: json['dateOuverture'] != null ? DateTime.parse(json['dateOuverture']) : null,
      dateFermeture: json['dateFermeture'] != null ? DateTime.parse(json['dateFermeture']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'soldeInitial': soldeInitial,
      'soldeActuel': soldeActuel,
      'isActive': isActive,
      'utilisateurId': utilisateurId,
      'nomUtilisateur': nomUtilisateur,
      'dateCreation': dateCreation?.toIso8601String(),
      'dateModification': dateModification?.toIso8601String(),
      'dateOuverture': dateOuverture?.toIso8601String(),
      'dateFermeture': dateFermeture?.toIso8601String(),
    };
  }

  CashRegister copyWith({
    int? id,
    String? nom,
    String? description,
    double? soldeInitial,
    double? soldeActuel,
    bool? isActive,
    int? utilisateurId,
    String? nomUtilisateur,
    DateTime? dateCreation,
    DateTime? dateModification,
    DateTime? dateOuverture,
    DateTime? dateFermeture,
  }) {
    return CashRegister(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      soldeInitial: soldeInitial ?? this.soldeInitial,
      soldeActuel: soldeActuel ?? this.soldeActuel,
      isActive: isActive ?? this.isActive,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      dateOuverture: dateOuverture ?? this.dateOuverture,
      dateFermeture: dateFermeture ?? this.dateFermeture,
    );
  }

  /// Vérifie si la caisse est ouverte
  bool get isOpen => dateOuverture != null && dateFermeture == null;

  /// Vérifie si la caisse est fermée
  bool get isClosed => dateFermeture != null;

  /// Calcule la différence entre le solde actuel et initial
  double get difference => soldeActuel - soldeInitial;

  /// Retourne le statut de la caisse
  String get status {
    if (!isActive) return 'Inactive';
    if (isOpen) return 'Ouverte';
    if (isClosed) return 'Fermée';
    return 'Prête';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CashRegister && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CashRegister(id: $id, nom: $nom, soldeActuel: $soldeActuel)';
  }
}

/// Modèle pour les mouvements de caisse
class CashMovement {
  final int? id;
  final int caisseId;
  final String type; // 'ouverture', 'fermeture', 'entree', 'sortie', 'vente'
  final double montant;
  final String description;
  final int? utilisateurId;
  final String? nomUtilisateur;
  final DateTime dateCreation;
  final Map<String, dynamic>? metadata;

  CashMovement({
    this.id,
    required this.caisseId,
    required this.type,
    required this.montant,
    this.description = '',
    this.utilisateurId,
    this.nomUtilisateur,
    required this.dateCreation,
    this.metadata,
  });

  factory CashMovement.fromJson(Map<String, dynamic> json) {
    return CashMovement(
      id: json['id'],
      caisseId: json['caisseId'],
      type: json['type'] ?? '',
      montant: (json['montant'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      utilisateurId: json['utilisateurId'],
      nomUtilisateur: json['nomUtilisateur'],
      dateCreation: DateTime.parse(json['dateCreation']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caisseId': caisseId,
      'type': type,
      'montant': montant,
      'description': description,
      'utilisateurId': utilisateurId,
      'nomUtilisateur': nomUtilisateur,
      'dateCreation': dateCreation.toIso8601String(),
      'metadata': metadata,
    };
  }

  CashMovement copyWith({
    int? id,
    int? caisseId,
    String? type,
    double? montant,
    String? description,
    int? utilisateurId,
    String? nomUtilisateur,
    DateTime? dateCreation,
    Map<String, dynamic>? metadata,
  }) {
    return CashMovement(
      id: id ?? this.id,
      caisseId: caisseId ?? this.caisseId,
      type: type ?? this.type,
      montant: montant ?? this.montant,
      description: description ?? this.description,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      dateCreation: dateCreation ?? this.dateCreation,
      metadata: metadata ?? this.metadata,
    );
  }
}
