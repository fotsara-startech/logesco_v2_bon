import 'zone.dart';

/// Modèle de données pour un commercial terrain.
///
/// Un commercial n'est PAS un compte utilisateur — il ne se connecte jamais
/// à l'app. C'est une fiche de référence à laquelle une caissière rattache
/// une vente qu'elle encaisse après un versement effectué en magasin.
class Commercial {
  final int id;
  final String nom;
  final String? prenom;
  final String? telephone;
  final int zoneId;
  final Zone? zone;
  final bool isActive;
  final DateTime dateCreation;
  final DateTime dateModification;

  Commercial({
    required this.id,
    required this.nom,
    this.prenom,
    this.telephone,
    required this.zoneId,
    this.zone,
    this.isActive = true,
    required this.dateCreation,
    required this.dateModification,
  });

  factory Commercial.fromJson(Map<String, dynamic> json) {
    return Commercial(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String?,
      telephone: json['telephone'] as String?,
      zoneId: json['zoneId'] as int,
      zone: json['zone'] != null ? Zone.fromJson(json['zone'] as Map<String, dynamic>) : null,
      isActive: json['isActive'] as bool? ?? true,
      dateCreation: json['dateCreation'] != null ? DateTime.parse(json['dateCreation'] as String) : DateTime.now(),
      dateModification: json['dateModification'] != null ? DateTime.parse(json['dateModification'] as String) : DateTime.now(),
    );
  }

  String get nomComplet => prenom != null && prenom!.isNotEmpty ? '$nom $prenom' : nom;

  /// Libellé « nom — zone, ville », utilisé dans les sélecteurs (vente, filtres).
  String get libelleAvecZone {
    if (zone == null) return nomComplet;
    final villeNom = zone!.ville?.nom;
    return villeNom != null ? '$nomComplet — ${zone!.nom}, $villeNom' : '$nomComplet — ${zone!.nom}';
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Commercial && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Commercial(id: $id, nom: $nom, zoneId: $zoneId)';
}

/// Modèle pour la création/modification d'un commercial
class CommercialForm {
  final String nom;
  final String? prenom;
  final String? telephone;
  final int zoneId;
  final bool isActive;

  CommercialForm({
    required this.nom,
    this.prenom,
    this.telephone,
    required this.zoneId,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'zoneId': zoneId,
        'isActive': isActive,
      };

  factory CommercialForm.fromCommercial(Commercial commercial) {
    return CommercialForm(
      nom: commercial.nom,
      prenom: commercial.prenom,
      telephone: commercial.telephone,
      zoneId: commercial.zoneId,
      isActive: commercial.isActive,
    );
  }
}
