/// Modèle pour les catégories de mouvements financiers
class MovementCategory {
  final int id;
  final String name;
  final String displayName;
  final String color;
  final String icon;
  final bool isDefault;
  final bool isActive;

  MovementCategory({
    required this.id,
    required this.name,
    required this.displayName,
    required this.color,
    required this.icon,
    required this.isDefault,
    required this.isActive,
  });

  /// Crée une catégorie depuis JSON
  factory MovementCategory.fromJson(Map<String, dynamic> json) {
    try {
      return MovementCategory(
        id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['nom']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        color: json['color']?.toString() ?? '#6B7280',
        icon: json['icon']?.toString() ?? 'receipt',
        isDefault: json['isDefault'] == true || json['isDefault']?.toString().toLowerCase() == 'true',
        isActive: json['isActive'] == true || json['isActive']?.toString().toLowerCase() == 'true',
      );
    } catch (e) {
      print('❌ [MovementCategory.fromJson] Erreur de parsing: $e');
      print('📋 [MovementCategory.fromJson] JSON reçu: $json');
      rethrow;
    }
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': name,
      'displayName': displayName,
      'color': color,
      'icon': icon,
      'isDefault': isDefault,
      'isActive': isActive,
    };
  }

  /// Crée une copie avec des modifications
  MovementCategory copyWith({
    int? id,
    String? name,
    String? displayName,
    String? color,
    String? icon,
    bool? isDefault,
    bool? isActive,
  }) {
    return MovementCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'MovementCategory(id: $id, name: $name, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovementCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Catégories prédéfinies par défaut
  static List<MovementCategory> get defaultCategories => [
        MovementCategory(
          id: 1,
          name: 'achats',
          displayName: 'Achats de marchandises',
          color: '#EF4444',
          icon: 'shopping_cart',
          isDefault: true,
          isActive: true,
        ),
        MovementCategory(
          id: 2,
          name: 'charges',
          displayName: 'Charges et frais',
          color: '#F59E0B',
          icon: 'receipt_long',
          isDefault: true,
          isActive: true,
        ),
        MovementCategory(
          id: 3,
          name: 'salaires',
          displayName: 'Salaires et personnel',
          color: '#10B981',
          icon: 'people',
          isDefault: true,
          isActive: true,
        ),
        MovementCategory(
          id: 4,
          name: 'maintenance',
          displayName: 'Maintenance et réparations',
          color: '#8B5CF6',
          icon: 'build',
          isDefault: true,
          isActive: true,
        ),
        MovementCategory(
          id: 5,
          name: 'transport',
          displayName: 'Transport et livraison',
          color: '#06B6D4',
          icon: 'local_shipping',
          isDefault: true,
          isActive: true,
        ),
        MovementCategory(
          id: 6,
          name: 'autres',
          displayName: 'Autres dépenses',
          color: '#6B7280',
          icon: 'more_horiz',
          isDefault: true,
          isActive: true,
        ),
      ];

  /// Trouve une catégorie par son nom
  static MovementCategory? findByName(String name) {
    try {
      return defaultCategories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Trouve une catégorie par son ID
  static MovementCategory? findById(int id) {
    try {
      return defaultCategories.firstWhere(
        (category) => category.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtient les catégories actives uniquement
  static List<MovementCategory> get activeCategories {
    return defaultCategories.where((category) => category.isActive).toList();
  }

  /// Vérifie si la catégorie est valide pour la création
  bool get isValidForCreation {
    return name.isNotEmpty && displayName.isNotEmpty && color.isNotEmpty && icon.isNotEmpty;
  }
}

/// Modèle pour la création/modification d'une catégorie
class MovementCategoryForm {
  final String name;
  final String displayName;
  final String color;
  final String icon;
  final bool isActive;

  MovementCategoryForm({
    required this.name,
    required this.displayName,
    required this.color,
    required this.icon,
    this.isActive = true,
  });

  /// Convertit le formulaire en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'nom': name,
      'displayName': displayName,
      'color': color,
      'icon': icon,
      'isActive': isActive,
    };
  }

  /// Crée un formulaire à partir d'une catégorie existante
  factory MovementCategoryForm.fromCategory(MovementCategory category) {
    return MovementCategoryForm(
      name: category.name,
      displayName: category.displayName,
      color: category.color,
      icon: category.icon,
      isActive: category.isActive,
    );
  }

  /// Valide les données du formulaire
  List<String> validate() {
    List<String> errors = [];

    if (name.trim().isEmpty) {
      errors.add('Le nom de la catégorie est obligatoire');
    }

    if (name.trim().length < 2) {
      errors.add('Le nom doit contenir au moins 2 caractères');
    }

    if (displayName.trim().isEmpty) {
      errors.add('Le nom d\'affichage est obligatoire');
    }

    if (displayName.trim().length < 3) {
      errors.add('Le nom d\'affichage doit contenir au moins 3 caractères');
    }

    if (color.trim().isEmpty) {
      errors.add('La couleur est obligatoire');
    }

    if (!color.startsWith('#') || color.length != 7) {
      errors.add('La couleur doit être au format hexadécimal (#RRGGBB)');
    }

    if (icon.trim().isEmpty) {
      errors.add('L\'icône est obligatoire');
    }

    return errors;
  }

  /// Vérifie si le formulaire est valide
  bool get isValid => validate().isEmpty;
}
