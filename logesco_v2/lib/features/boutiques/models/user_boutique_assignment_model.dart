import 'boutique_model.dart';
import '../../users/models/role_model.dart' as role_model;

/// Assignation d'un utilisateur à une boutique avec un rôle spécifique
class UserBoutiqueAssignment {
  final int id;
  final int utilisateurId;
  final int boutiqueId;
  final int? roleId;
  final bool isActive;
  final Boutique? boutique;
  final role_model.UserRole? role;
  final Map<String, dynamic>? utilisateur;

  const UserBoutiqueAssignment({
    required this.id,
    required this.utilisateurId,
    required this.boutiqueId,
    this.roleId,
    required this.isActive,
    this.boutique,
    this.role,
    this.utilisateur,
  });

  factory UserBoutiqueAssignment.fromJson(Map<String, dynamic> json) {
    return UserBoutiqueAssignment(
      id: json['id'] as int,
      utilisateurId: json['utilisateurId'] as int? ?? json['utilisateur_id'] as int? ?? 0,
      boutiqueId: json['boutiqueId'] as int? ?? json['boutique_id'] as int? ?? 0,
      roleId: json['roleId'] as int? ?? json['role_id'] as int?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      boutique: json['boutique'] != null ? Boutique.fromJson(json['boutique'] as Map<String, dynamic>) : null,
      role: json['role'] != null ? role_model.UserRole.fromJson(json['role'] as Map<String, dynamic>) : null,
      utilisateur: json['utilisateur'] as Map<String, dynamic>?,
    );
  }
}
