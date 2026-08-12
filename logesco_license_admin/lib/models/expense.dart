import 'package:json_annotation/json_annotation.dart';

part 'expense.g.dart';

enum ExpenseCategory {
  advertising, // Publicité
  transport, // Transport
  internet, // Internet
  aiSubscription, // Abonnement IA (ex: Claude)
  phoneCredit, // Crédit téléphonique
  other, // Autre (texte libre requis)
}

/// Dépense de l'activité (publicité, transport, internet, abonnement IA,
/// crédit téléphonique, etc.).
@JsonSerializable()
class Expense {
  final String id;
  final ExpenseCategory category;
  final String? otherCategoryLabel;
  final double amount;
  final String currency;
  final DateTime expenseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.category,
    this.otherCategoryLabel,
    required this.amount,
    this.currency = 'XAF',
    required this.expenseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseToJson(this);

  Expense copyWith({
    String? id,
    ExpenseCategory? category,
    String? otherCategoryLabel,
    double? amount,
    String? currency,
    DateTime? expenseDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      otherCategoryLabel: otherCategoryLabel ?? this.otherCategoryLabel,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Libellé FR affichable (catégorie prédéfinie, ou texte libre si "Autre")
  String get categoryLabel {
    switch (category) {
      case ExpenseCategory.advertising:
        return 'Publicité';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.internet:
        return 'Internet';
      case ExpenseCategory.aiSubscription:
        return 'Abonnement IA';
      case ExpenseCategory.phoneCredit:
        return 'Crédit téléphonique';
      case ExpenseCategory.other:
        return (otherCategoryLabel != null && otherCategoryLabel!.isNotEmpty) ? otherCategoryLabel! : 'Autre';
    }
  }

  @override
  String toString() {
    return 'Expense(id: $id, category: $category, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Libellés FR pour le sélecteur de catégorie dans les formulaires
String expenseCategoryLabel(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.advertising:
      return 'Publicité';
    case ExpenseCategory.transport:
      return 'Transport';
    case ExpenseCategory.internet:
      return 'Internet';
    case ExpenseCategory.aiSubscription:
      return 'Abonnement IA';
    case ExpenseCategory.phoneCredit:
      return 'Crédit téléphonique';
    case ExpenseCategory.other:
      return 'Autre';
  }
}
