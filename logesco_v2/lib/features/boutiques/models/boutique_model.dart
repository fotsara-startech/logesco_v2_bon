/// Modèle Boutique
class Boutique {
  final int id;
  final String nom;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? description;
  final bool estPrincipale;
  final bool isActive;
  final DateTime dateCreation;
  final DateTime dateModification;

  const Boutique({
    required this.id,
    required this.nom,
    this.adresse,
    this.telephone,
    this.email,
    this.description,
    required this.estPrincipale,
    required this.isActive,
    required this.dateCreation,
    required this.dateModification,
  });

  factory Boutique.fromJson(Map<String, dynamic> json) {
    return Boutique(
      id: json['id'] as int,
      nom: json['nom'] as String? ?? '',
      adresse: json['adresse'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      estPrincipale: json['estPrincipale'] as bool? ?? json['est_principale'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      dateCreation: DateTime.tryParse(json['dateCreation'] as String? ?? '') ?? DateTime.now(),
      dateModification: DateTime.tryParse(json['dateModification'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'email': email,
        'description': description,
        'estPrincipale': estPrincipale,
        'isActive': isActive,
      };

  Boutique copyWith({
    String? nom,
    String? adresse,
    String? telephone,
    String? email,
    String? description,
    bool? isActive,
  }) {
    return Boutique(
      id: id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      description: description ?? this.description,
      estPrincipale: estPrincipale,
      isActive: isActive ?? this.isActive,
      dateCreation: dateCreation,
      dateModification: dateModification,
    );
  }
}
