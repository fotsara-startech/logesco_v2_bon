/// Modèle pour un transfert de stock entre boutiques
class StockTransfert {
  final int id;
  final String reference;
  final int sourceBoutiqueId;
  final int destBoutiqueId;
  final int produitId;
  final int quantite;
  final String? notes;
  final int utilisateurId;
  final DateTime dateTransfert;
  final Map<String, dynamic>? sourceBoutique;
  final Map<String, dynamic>? destBoutique;
  final Map<String, dynamic>? produit;
  final Map<String, dynamic>? utilisateur;

  const StockTransfert({
    required this.id,
    required this.reference,
    required this.sourceBoutiqueId,
    required this.destBoutiqueId,
    required this.produitId,
    required this.quantite,
    this.notes,
    required this.utilisateurId,
    required this.dateTransfert,
    this.sourceBoutique,
    this.destBoutique,
    this.produit,
    this.utilisateur,
  });

  factory StockTransfert.fromJson(Map<String, dynamic> json) {
    return StockTransfert(
      id: json['id'] as int,
      reference: json['reference'] as String? ?? '',
      sourceBoutiqueId: json['sourceBoutiqueId'] as int? ?? json['source_boutique_id'] as int? ?? 0,
      destBoutiqueId: json['destBoutiqueId'] as int? ?? json['dest_boutique_id'] as int? ?? 0,
      produitId: json['produitId'] as int? ?? json['produit_id'] as int? ?? 0,
      quantite: json['quantite'] as int? ?? 0,
      notes: json['notes'] as String?,
      utilisateurId: json['utilisateurId'] as int? ?? json['utilisateur_id'] as int? ?? 0,
      dateTransfert: DateTime.tryParse(json['dateTransfert'] as String? ?? json['date_transfert'] as String? ?? '') ?? DateTime.now(),
      sourceBoutique: json['sourceBoutique'] as Map<String, dynamic>?,
      destBoutique: json['destBoutique'] as Map<String, dynamic>?,
      produit: json['produit'] as Map<String, dynamic>?,
      utilisateur: json['utilisateur'] as Map<String, dynamic>?,
    );
  }
}
