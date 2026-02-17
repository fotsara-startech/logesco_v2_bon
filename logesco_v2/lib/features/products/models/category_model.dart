/// Modèle pour les catégories de produits
class Category {
  final int? id;
  final String nom;
  final String? description;
  final DateTime dateCreation;
  final DateTime dateModification;

  Category({
    this.id,
    required this.nom,
    this.description,
    DateTime? dateCreation,
    DateTime? dateModification,
  })  : dateCreation = dateCreation ?? DateTime.now(),
        dateModification = dateModification ?? DateTime.now();

  /// Crée une catégorie depuis JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation'] as String) : DateTime.now(),
      dateModification: json['dateModification'] != null ? DateTime.parse(json['dateModification'] as String) : DateTime.now(),
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      if (description != null) 'description': description,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification.toIso8601String(),
    };
  }

  /// Crée une copie avec des modifications
  Category copyWith({
    int? id,
    String? nom,
    String? description,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return Category(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, nom: $nom, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id && other.nom == nom;
  }

  @override
  int get hashCode => Object.hash(id, nom);
}
