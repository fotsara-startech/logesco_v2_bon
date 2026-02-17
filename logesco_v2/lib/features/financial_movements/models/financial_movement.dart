import 'movement_category.dart';

/// Modèle de données pour un mouvement financier
class FinancialMovement {
  final int id;
  final String reference;
  final double montant;
  final int categorieId;
  final String description;
  final DateTime date;
  final int utilisateurId;
  final DateTime dateCreation;
  final DateTime dateModification;
  final String? notes;
  final MovementCategory? categorie;
  final String? utilisateurNom;

  FinancialMovement({
    required this.id,
    required this.reference,
    required this.montant,
    required this.categorieId,
    required this.description,
    required this.date,
    required this.utilisateurId,
    required this.dateCreation,
    required this.dateModification,
    this.notes,
    this.categorie,
    this.utilisateurNom,
  });

  /// Crée un mouvement financier à partir d'un JSON
  factory FinancialMovement.fromJson(Map<String, dynamic> json) {
    try {
      // Helper pour parser les nombres de manière sûre
      double parseDouble(dynamic value, {double defaultValue = 0.0}) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          return parsed ?? defaultValue;
        }
        return defaultValue;
      }

      // Helper pour parser les entiers de manière sûre
      int parseInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          return parsed ?? defaultValue;
        }
        return defaultValue;
      }

      // Helper pour parser les dates de manière sûre
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

      return FinancialMovement(
        id: parseInt(json['id']),
        reference: json['reference']?.toString() ?? '',
        montant: parseDouble(json['montant']),
        categorieId: parseInt(json['categorieId']),
        description: json['description']?.toString() ?? '',
        date: parseDate(json['date']),
        utilisateurId: parseInt(json['utilisateurId']),
        dateCreation: parseDate(json['dateCreation']),
        dateModification: parseDate(json['dateModification']),
        notes: json['notes']?.toString(),
        categorie: json['categorie'] != null 
            ? MovementCategory.fromJson(json['categorie'] as Map<String, dynamic>) 
            : null,
        utilisateurNom: json['utilisateurNom']?.toString(),
      );
    } catch (e) {
      print('❌ [FinancialMovement.fromJson] Erreur de parsing: $e');
      print('📋 [FinancialMovement.fromJson] JSON reçu: $json');
      rethrow;
    }
  }

  /// Convertit le mouvement financier en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'montant': montant,
      'categorieId': categorieId,
      'description': description,
      'date': date.toIso8601String(),
      'utilisateurId': utilisateurId,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (categorie != null) 'categorie': categorie!.toJson(),
      if (utilisateurNom != null) 'utilisateurNom': utilisateurNom,
    };
  }

  /// Crée une copie du mouvement financier avec des modifications
  FinancialMovement copyWith({
    int? id,
    String? reference,
    double? montant,
    int? categorieId,
    String? description,
    DateTime? date,
    int? utilisateurId,
    DateTime? dateCreation,
    DateTime? dateModification,
    String? notes,
    MovementCategory? categorie,
    String? utilisateurNom,
  }) {
    return FinancialMovement(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      montant: montant ?? this.montant,
      categorieId: categorieId ?? this.categorieId,
      description: description ?? this.description,
      date: date ?? this.date,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      notes: notes ?? this.notes,
      categorie: categorie ?? this.categorie,
      utilisateurNom: utilisateurNom ?? this.utilisateurNom,
    );
  }

  @override
  String toString() {
    return 'FinancialMovement(id: $id, reference: $reference, montant: $montant, description: $description)';
  }

  /// Formate le montant avec la devise
  String get montantFormate {
    return '${montant.toStringAsFixed(2)} FCFA';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinancialMovement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour la création/modification d'un mouvement financier
class FinancialMovementForm {
  final double montant;
  final int categorieId;
  final String description;
  final DateTime date;
  final String? notes;

  FinancialMovementForm({
    required this.montant,
    required this.categorieId,
    required this.description,
    required this.date,
    this.notes,
  });

  /// Convertit le formulaire en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'montant': montant,
      'categorieId': categorieId,
      'description': description,
      'date': date.toIso8601String(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  /// Crée un formulaire à partir d'un mouvement existant
  factory FinancialMovementForm.fromMovement(FinancialMovement movement) {
    return FinancialMovementForm(
      montant: movement.montant,
      categorieId: movement.categorieId,
      description: movement.description,
      date: movement.date,
      notes: movement.notes,
    );
  }

  /// Valide les données du formulaire
  List<String> validate() {
    List<String> errors = [];

    if (montant <= 0) {
      errors.add('Le montant doit être supérieur à 0');
    }

    if (description.trim().isEmpty) {
      errors.add('La description est obligatoire');
    }

    if (description.trim().length < 3) {
      errors.add('La description doit contenir au moins 3 caractères');
    }

    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      errors.add('La date ne peut pas être dans le futur');
    }

    return errors;
  }

  /// Vérifie si le formulaire est valide
  bool get isValid => validate().isEmpty;
}
