import 'ville.dart';

/// Modèle de données pour une zone (quartier), rattachée à une ville
class Zone {
  final int id;
  final String nom;
  final int villeId;
  final Ville? ville;
  final DateTime dateCreation;
  final DateTime dateModification;

  Zone({
    required this.id,
    required this.nom,
    required this.villeId,
    this.ville,
    required this.dateCreation,
    required this.dateModification,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as int,
      nom: json['nom'] as String,
      villeId: json['villeId'] as int,
      ville: json['ville'] != null ? Ville.fromJson(json['ville'] as Map<String, dynamic>) : null,
      dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation'] as String) : DateTime.now(),
      dateModification: json['dateModification'] != null ? DateTime.parse(json['dateModification'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {'nom': nom, 'villeId': villeId};

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Zone && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Zone(id: $id, nom: $nom, villeId: $villeId)';
}
