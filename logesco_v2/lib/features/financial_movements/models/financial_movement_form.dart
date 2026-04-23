import 'financial_movement.dart';

/// Modèle de formulaire pour créer/modifier un mouvement financier
class FinancialMovementForm {
  final String reference;
  final double montant;
  final int categorieId;
  final String description;
  final DateTime date;
  final String? notes;

  const FinancialMovementForm({
    required this.reference,
    required this.montant,
    required this.categorieId,
    required this.description,
    required this.date,
    this.notes,
  });

  /// Crée un formulaire à partir d'un mouvement existant
  factory FinancialMovementForm.fromMovement(FinancialMovement movement) {
    return FinancialMovementForm(
      reference: movement.reference,
      montant: movement.montant,
      categorieId: movement.categorieId,
      description: movement.description,
      date: movement.date,
      notes: movement.notes,
    );
  }

  /// Valide les données du formulaire
  List<String> validate() {
    final errors = <String>[];

    if (reference.trim().isEmpty) {
      errors.add('La référence est obligatoire');
    }

    if (montant <= 0) {
      errors.add('Le montant doit être positif');
    }

    if (categorieId <= 0) {
      errors.add('Une catégorie doit être sélectionnée');
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

  /// Convertit en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'reference': reference.trim(),
      'montant': montant,
      'categorieId': categorieId,
      'description': description.trim(),
      'date': date.toIso8601String(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  /// Crée une copie avec des modifications
  FinancialMovementForm copyWith({
    String? reference,
    double? montant,
    int? categorieId,
    String? description,
    DateTime? date,
    String? notes,
  }) {
    return FinancialMovementForm(
      reference: reference ?? this.reference,
      montant: montant ?? this.montant,
      categorieId: categorieId ?? this.categorieId,
      description: description ?? this.description,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
