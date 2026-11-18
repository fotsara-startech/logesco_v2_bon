import 'package:get/get.dart';
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
      errors.add('financialmovements_reference_est_obligatoire'.tr);
    }

    if (montant <= 0) {
      errors.add('financial_movements_form_amount_positive'.tr);
    }

    if (categorieId <= 0) {
      errors.add('financialmovements_categorie_doit_etre_selectionnee'.tr);
    }

    if (description.trim().isEmpty) {
      errors.add('financial_movements_form_description_required'.tr);
    }

    if (description.trim().length < 3) {
      errors.add('financialmovements_description_doit_contenir_moins_3_caracteres'.tr);
    }

    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      errors.add('financial_movements_form_date_future'.tr);
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
