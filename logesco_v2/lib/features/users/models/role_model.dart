import 'dart:convert';

/// Modèle unifié pour les rôles utilisateur
class UserRole {
  final int? id;
  final String nom;
  final String displayName;
  final bool isAdmin;
  final Map<String, List<String>> privileges;
  final DateTime? dateCreation;
  final DateTime? dateModification;

  const UserRole({
    this.id,
    required this.nom,
    required this.displayName,
    this.isAdmin = false,
    this.privileges = const {},
    this.dateCreation,
    this.dateModification,
  });

  /// Crée un UserRole à partir d'un JSON
  factory UserRole.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> parsedPrivileges = {};

    if (json['privileges'] != null) {
      if (json['privileges'] is String) {
        // Si c'est une chaîne JSON, on la parse
        try {
          final privilegesData = jsonDecode(json['privileges']);
          if (privilegesData is Map) {
            parsedPrivileges = _parsePrivilegesMap(privilegesData);
          }
        } catch (e) {
          // En cas d'erreur de parsing, on garde un map vide
          parsedPrivileges = {};
        }
      } else if (json['privileges'] is Map) {
        // Si c'est déjà un Map, le parser
        parsedPrivileges = _parsePrivilegesMap(json['privileges']);
      } else if (json['privileges'] is List) {
        // Ancien format avec liste simple
        final List<String> oldPrivileges = List<String>.from(json['privileges']);
        parsedPrivileges = {'general': oldPrivileges};
      }
    }

    return UserRole(
      id: json['id'],
      nom: json['nom'] ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? '',
      isAdmin: json['isAdmin'] ?? json['is_admin'] ?? false,
      privileges: parsedPrivileges,
      dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation']) : null,
      dateModification: json['dateModification'] != null ? DateTime.parse(json['dateModification']) : null,
    );
  }

  /// Parse les privilèges depuis un Map (format backend)
  /// Convertit {users: {create: true, read: true}} en {users: ['CREATE', 'READ']}
  static Map<String, List<String>> _parsePrivilegesMap(Map<dynamic, dynamic> privilegesMap) {
    final Map<String, List<String>> result = {};

    privilegesMap.forEach((module, privileges) {
      final moduleKey = module.toString();
      final List<String> privilegesList = [];

      if (privileges is Map) {
        // Format: {create: true, read: false, update: true}
        privileges.forEach((privilege, enabled) {
          if (enabled == true) {
            privilegesList.add(privilege.toString().toUpperCase());
          }
        });
      } else if (privileges is List) {
        // Format: ['CREATE', 'READ', 'UPDATE']
        privilegesList.addAll(privileges.map((p) => p.toString().toUpperCase()));
      }

      if (privilegesList.isNotEmpty) {
        result[moduleKey] = privilegesList;
      }
    });

    return result;
  }

  /// Convertit le UserRole en JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'privileges': privileges, // Envoyer l'objet directement, pas encodé en JSON
      if (dateCreation != null) 'dateCreation': dateCreation!.toIso8601String(),
      if (dateModification != null) 'dateModification': dateModification!.toIso8601String(),
    };
  }

  /// Vérifie si le rôle a un privilège spécifique pour un module
  bool hasPrivilege(String module, String privilege) {
    if (isAdmin) return true;
    return privileges[module]?.contains(privilege) ?? false;
  }

  /// Vérifie si le rôle a tous les privilèges pour un module
  bool hasAllPrivileges(String module) {
    if (isAdmin) return true;
    final modulePrivileges = privileges[module] ?? [];
    return modulePrivileges.contains('ALL');
  }

  /// Obtient tous les privilèges pour un module
  List<String> getModulePrivileges(String module) {
    if (isAdmin) return ['ALL'];
    return privileges[module] ?? [];
  }

  /// Crée une copie du rôle avec des modifications
  UserRole copyWith({
    int? id,
    String? nom,
    String? displayName,
    bool? isAdmin,
    Map<String, List<String>>? privileges,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return UserRole(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      privileges: privileges ?? this.privileges,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
    );
  }

  @override
  String toString() {
    return 'UserRole(id: $id, nom: $nom, displayName: $displayName, isAdmin: $isAdmin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRole && other.id == id && other.nom == nom;
  }

  @override
  int get hashCode => Object.hash(id, nom);

  // Méthodes de compatibilité avec l'ancien système
  bool get canManageUsers => isAdmin || hasPrivilege('users', 'CREATE') || hasPrivilege('users', 'UPDATE') || hasPrivilege('users', 'DELETE');
  bool get canManageProducts => isAdmin || hasPrivilege('products', 'CREATE') || hasPrivilege('products', 'UPDATE') || hasPrivilege('products', 'DELETE');
  bool get canManageSales => isAdmin || hasPrivilege('sales', 'CREATE') || hasPrivilege('sales', 'UPDATE') || hasPrivilege('sales', 'DELETE');
  bool get canManageInventory => isAdmin || hasPrivilege('inventory', 'CREATE') || hasPrivilege('inventory', 'UPDATE') || hasPrivilege('inventory', 'ADJUST');
  bool get canManageReports => isAdmin || hasPrivilege('reports', 'READ') || hasPrivilege('reports', 'EXPORT');
  bool get canManageCompanySettings => isAdmin || hasPrivilege('company_settings', 'UPDATE');
  bool get canManageCashRegisters => isAdmin || hasPrivilege('cash_registers', 'CREATE') || hasPrivilege('cash_registers', 'UPDATE');
  bool get canViewReports => isAdmin || hasPrivilege('reports', 'READ') || hasPrivilege('dashboard', 'STATS');
  bool get canMakeSales => isAdmin || hasPrivilege('sales', 'CREATE') || hasPrivilege('sales', 'READ');
  bool get canBackdateSales => isAdmin || hasPrivilege('sales', 'BACKDATE');
  bool get canManageStock => isAdmin || hasPrivilege('inventory', 'ADJUST') || hasPrivilege('stock_inventory', 'COUNT');
  bool get canManageSuppliers => isAdmin || hasPrivilege('suppliers', 'CREATE') || hasPrivilege('suppliers', 'UPDATE') || hasPrivilege('suppliers', 'DELETE');
  bool get canViewSuppliers => isAdmin || hasPrivilege('suppliers', 'READ');
  bool get canManageProcurement => isAdmin || hasPrivilege('procurement', 'CREATE') || hasPrivilege('procurement', 'UPDATE') || hasPrivilege('procurement', 'DELETE');
  bool get canViewProcurement => isAdmin || hasPrivilege('procurement', 'READ');
  bool get canReceiveProcurement => isAdmin || hasPrivilege('procurement', 'RECEIVE');
}

/// Privilèges prédéfinis par module
class ModulePrivileges {
  static const Map<String, List<String>> availablePrivileges = {
    'dashboard': ['READ', 'STATS'],
    'products': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
    'categories': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
    'inventory': ['READ', 'CREATE', 'UPDATE', 'DELETE', 'ADJUST'],
    'suppliers': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
    'customers': ['READ', 'CREATE', 'UPDATE', 'DELETE'],
    'sales': ['READ', 'CREATE', 'UPDATE', 'DELETE', 'REFUND', 'BACKDATE'],
    'procurement': ['READ', 'CREATE', 'UPDATE', 'DELETE', 'RECEIVE'],
    'accounts': ['READ', 'CREATE', 'UPDATE', 'DELETE', 'TRANSACTIONS'],
    'financial_movements': ['READ', 'CREATE', 'UPDATE', 'DELETE', 'REPORTS'],
    'cash_registers': ['READ', 'CREATE', 'UPDATE', 'DELETE', 'OPEN', 'CLOSE'],
    'stock_inventory': ['READ', 'CREATE', 'UPDATE', 'DELETE', 'COUNT'],
    'users': ['READ', 'CREATE', 'UPDATE', 'DELETE', 'ROLES'],
    'company_settings': ['READ', 'UPDATE'],
    'printing': ['READ', 'PRINT', 'REPRINT'],
    'reports': ['READ', 'EXPORT'],
  };

  static const Map<String, String> moduleDisplayNames = {
    'dashboard': 'Tableau de bord',
    'products': 'Produits',
    'categories': 'Catégories',
    'inventory': 'Inventaire',
    'suppliers': 'Fournisseurs',
    'customers': 'Clients',
    'sales': 'Ventes',
    'procurement': 'Approvisionnement',
    'accounts': 'Comptes',
    'financial_movements': 'Mouvements financiers',
    'cash_registers': 'Caisses',
    'stock_inventory': 'Inventaire de stock',
    'users': 'Utilisateurs',
    'company_settings': 'Paramètres entreprise',
    'printing': 'Impression',
    'reports': 'Rapports',
  };

  static const Map<String, String> privilegeDisplayNames = {
    'READ': 'Lecture',
    'CREATE': 'Création',
    'UPDATE': 'Modification',
    'DELETE': 'Suppression',
    'STATS': 'Statistiques',
    'ADJUST': 'Ajustement',
    'REFUND': 'Remboursement',
    'RECEIVE': 'Réception',
    'TRANSACTIONS': 'Transactions',
    'REPORTS': 'Rapports',
    'OPEN': 'Ouverture',
    'CLOSE': 'Fermeture',
    'COUNT': 'Comptage',
    'ROLES': 'Gestion des rôles',
    'PRINT': 'Impression',
    'REPRINT': 'Réimpression',
    'EXPORT': 'Exportation',
    'BACKDATE': 'Antidater',
  };
}
