import 'package:json_annotation/json_annotation.dart';

part 'expense_category.g.dart';

@JsonSerializable()
class ExpenseCategory {
  final int id;
  final String nom;
  final String displayName;
  final String color;
  final String icon;
  final bool isDefault;
  final bool isActive;
  final DateTime dateCreation;
  final DateTime dateModification;

  const ExpenseCategory({
    required this.id,
    required this.nom,
    required this.displayName,
    required this.color,
    required this.icon,
    required this.isDefault,
    required this.isActive,
    required this.dateCreation,
    required this.dateModification,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => _$ExpenseCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseCategoryToJson(this);
}

@JsonSerializable()
class CreateExpenseCategoryRequest {
  final String nom;
  final String? couleur;

  const CreateExpenseCategoryRequest({
    required this.nom,
    this.couleur,
  });

  factory CreateExpenseCategoryRequest.fromJson(Map<String, dynamic> json) => _$CreateExpenseCategoryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateExpenseCategoryRequestToJson(this);
}

@JsonSerializable()
class UpdateExpenseCategoryRequest {
  final String nom;
  final String? couleur;
  final bool estActif;

  const UpdateExpenseCategoryRequest({
    required this.nom,
    this.couleur,
    required this.estActif,
  });

  factory UpdateExpenseCategoryRequest.fromJson(Map<String, dynamic> json) => _$UpdateExpenseCategoryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateExpenseCategoryRequestToJson(this);
}
