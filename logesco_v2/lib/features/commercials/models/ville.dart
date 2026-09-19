/// Modèle de données pour une ville (commerciaux terrain)
class Ville {
  final int id;
  final String nom;
  final DateTime dateCreation;
  final DateTime dateModification;

  Ville({
    required this.id,
    required this.nom,
    required this.dateCreation,
    required this.dateModification,
  });

  factory Ville.fromJson(Map<String, dynamic> json) {
    return Ville(
      id: json['id'] as int,
      nom: json['nom'] as String,
      dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation'] as String) : DateTime.now(),
      dateModification: json['dateModification'] != null ? DateTime.parse(json['dateModification'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {'nom': nom};

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Ville && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Ville(id: $id, nom: $nom)';
}
