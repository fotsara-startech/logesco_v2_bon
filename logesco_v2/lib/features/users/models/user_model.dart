import '../models/role_model.dart' as role_model;

/// Modèle pour la gestion des utilisateurs
class User {
  final int? id;
  final String nomUtilisateur;
  final String email;
  final String? motDePasse;
  final role_model.UserRole role;
  final bool isActive;
  final DateTime? dateCreation;
  final DateTime? dateModification;

  User({
    this.id,
    required this.nomUtilisateur,
    required this.email,
    this.motDePasse,
    required this.role,
    this.isActive = true,
    this.dateCreation,
    this.dateModification,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      print('👤 [User.fromJson] Input JSON: $json');
      print('👤 [User.fromJson] JSON Type: ${json.runtimeType}');

      final user = User(
        id: json['id'],
        nomUtilisateur: json['nomUtilisateur'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] != null ? role_model.UserRole.fromJson(json['role']) : _createDefaultRole(),
        isActive: json['isActive'] ?? true,
        dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation']) : null,
        dateModification: json['dateModification'] != null ? DateTime.parse(json['dateModification']) : null,
      );

      print('✅ [User.fromJson] Successfully created user: ${user.nomUtilisateur}');
      return user;
    } catch (e) {
      print('❌ [User.fromJson] Error parsing user: $e');
      print('❌ [User.fromJson] Input was: $json');
      rethrow;
    }
  }

  /// Crée un rôle par défaut utilisant le nouveau modèle
  static role_model.UserRole _createDefaultRole() {
    return const role_model.UserRole(
      nom: 'user',
      displayName: 'Utilisateur',
      isAdmin: false,
      privileges: {
        'sales': ['READ', 'CREATE'],
        'dashboard': ['READ'],
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomUtilisateur': nomUtilisateur,
      'email': email,
      'motDePasse': motDePasse,
      'role': role.toJson(),
      'isActive': isActive,
      'dateCreation': dateCreation?.toIso8601String(),
      'dateModification': dateModification?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? nomUtilisateur,
    String? email,
    String? motDePasse,
    role_model.UserRole? role,
    bool? isActive,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return User(
      id: id ?? this.id,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }
}
