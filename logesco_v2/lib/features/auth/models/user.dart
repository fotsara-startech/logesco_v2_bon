import '../../users/models/role_model.dart' as role_model;

/// Modèle utilisateur pour l'authentification
class User {
  final int id;
  final String nomUtilisateur;
  final String email;
  final DateTime dateCreation;
  final DateTime dateModification;
  final role_model.UserRole role;

  User({
    required this.id,
    required this.nomUtilisateur,
    required this.email,
    required this.dateCreation,
    required this.dateModification,
    required this.role,
  });

  /// Crée un utilisateur à partir d'un JSON
  factory User.fromJson(Map<String, dynamic> json) {
    role_model.UserRole role;

    // Traiter le rôle selon le format reçu
    if (json['role'] != null) {
      if (json['role'] is String) {
        // Format simple: juste le nom du rôle - créer un rôle basique
        final roleName = json['role'] as String;
        role = _createBasicRole(roleName);
      } else if (json['role'] is Map<String, dynamic>) {
        // Format complet: objet role avec détails - utiliser le parser complet
        role = role_model.UserRole.fromJson(json['role'] as Map<String, dynamic>);
      } else {
        // Fallback: créer un rôle utilisateur basique
        role = _createBasicRole('user');
      }
    } else {
      // Pas de rôle fourni: créer un rôle utilisateur basique
      role = _createBasicRole('user');
    }

    // Construire le nom d'utilisateur à partir de nom et prénom si nécessaire
    String nomUtilisateur = json['nomUtilisateur'] as String? ?? json['nom_utilisateur'] as String? ?? '${json['prenom'] ?? ''} ${json['nom'] ?? ''}'.trim();

    if (nomUtilisateur.isEmpty) {
      nomUtilisateur = json['email'] as String? ?? 'Utilisateur';
    }

    // Gérer les dates avec différents formats possibles
    DateTime dateCreation = DateTime.now();
    DateTime dateModification = DateTime.now();

    try {
      if (json['dateCreation'] != null) {
        dateCreation = DateTime.parse(json['dateCreation'] as String);
      } else if (json['created_at'] != null) {
        dateCreation = DateTime.parse(json['created_at'] as String);
      }
    } catch (e) {
      // Garder la date par défaut si parsing échoue
    }

    try {
      if (json['dateModification'] != null) {
        dateModification = DateTime.parse(json['dateModification'] as String);
      } else if (json['updated_at'] != null) {
        dateModification = DateTime.parse(json['updated_at'] as String);
      }
    } catch (e) {
      // Garder la date par défaut si parsing échoue
    }

    return User(
      id: json['id'] as int,
      nomUtilisateur: nomUtilisateur,
      email: json['email'] as String,
      dateCreation: dateCreation,
      dateModification: dateModification,
      role: role,
    );
  }

  /// Crée un rôle basique à partir d'un nom (pour compatibilité)
  static role_model.UserRole _createBasicRole(String roleName) {
    final normalizedName = roleName.toLowerCase();

    if (normalizedName == 'admin' || normalizedName == 'administrateur') {
      return const role_model.UserRole(
        nom: 'ADMIN',
        displayName: 'Administrateur',
        isAdmin: true,
        privileges: {},
      );
    } else if (normalizedName == 'manager' || normalizedName == 'gestionnaire') {
      return const role_model.UserRole(
        nom: 'MANAGER',
        displayName: 'Gestionnaire',
        isAdmin: false,
        privileges: {
          'dashboard': ['READ', 'STATS'],
          'products': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
          'categories': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
          'inventory': ['READ', 'CREATE', 'UPDATE', 'ADJUST'],
          'suppliers': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
          'customers': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
          'sales': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
          'procurement': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
          'cash_registers': ['READ', 'CREATE', 'UPDATE', 'OPEN', 'CLOSE'],
          'reports': ['READ', 'EXPORT'],
          'printing': ['READ', 'PRINT'],
        },
      );
    } else {
      // Rôle utilisateur basique (vendeur par défaut)
      return const role_model.UserRole(
        nom: 'USER',
        displayName: 'Utilisateur',
        isAdmin: false,
        privileges: {
          'dashboard': ['READ'],
          'sales': ['READ', 'CREATE'],
          'products': ['READ'],
          'customers': ['READ', 'CREATE'],
          'cash_registers': ['READ', 'OPEN', 'CLOSE'],
          'printing': ['READ', 'PRINT'],
        },
      );
    }
  }

  /// Convertit l'utilisateur en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomUtilisateur': nomUtilisateur,
      'email': email,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
      'role': role.toJson(),
    };
  }

  /// Crée une copie de l'utilisateur avec des modifications
  User copyWith({
    int? id,
    String? nomUtilisateur,
    String? email,
    DateTime? dateCreation,
    DateTime? dateModification,
    role_model.UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      email: email ?? this.email,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, nomUtilisateur: $nomUtilisateur, email: $email, role: ${role.nom})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
