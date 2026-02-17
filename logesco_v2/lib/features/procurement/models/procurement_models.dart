/**
 * Modèles de données pour la gestion des approvisionnements
 */

import 'package:logesco_v2/features/inventory/models/stock_model.dart';
import 'package:logesco_v2/features/suppliers/models/supplier.dart';



/// Statuts possibles d'une commande d'approvisionnement
enum CommandeStatut {
  enAttente('en_attente', 'En attente'),
  partielle('partielle', 'Partiellement reçue'),
  terminee('terminee', 'Terminée'),
  annulee('annulee', 'Annulée');

  const CommandeStatut(this.value, this.label);
  final String value;
  final String label;

  static CommandeStatut fromString(String value) {
    return CommandeStatut.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CommandeStatut.enAttente,
    );
  }
}

/// Modes de paiement pour les commandes
enum ModePaiement {
  comptant('comptant', 'Comptant'),
  credit('credit', 'À crédit');

  const ModePaiement(this.value, this.label);
  final String value;
  final String label;

  static ModePaiement fromString(String value) {
    return ModePaiement.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ModePaiement.credit,
    );
  }
}

/// Détail d'une commande d'approvisionnement
class DetailCommandeApprovisionnement {
  final int id;
  final int produitId;
  final Product? produit;
  final int quantiteCommandee;
  final int quantiteRecue;
  final double coutUnitaire;

  DetailCommandeApprovisionnement({
    required this.id,
    required this.produitId,
    this.produit,
    required this.quantiteCommandee,
    required this.quantiteRecue,
    required this.coutUnitaire,
  });

  /// Quantité restante à recevoir
  int get quantiteRestante => quantiteCommandee - quantiteRecue;

  /// Coût total pour ce détail
  double get coutTotal => quantiteCommandee * coutUnitaire;

  /// Indique si ce détail est complètement reçu
  bool get estComplete => quantiteRecue >= quantiteCommandee;

  factory DetailCommandeApprovisionnement.fromJson(Map<String, dynamic> json) {
    return DetailCommandeApprovisionnement(
      id: json['id'] ?? 0,
      produitId: json['produitId'] ?? 0,
      produit: json['produit'] != null ? Product.fromJson(json['produit']) : null,
      quantiteCommandee: json['quantiteCommandee'] ?? 0,
      quantiteRecue: json['quantiteRecue'] ?? 0,
      coutUnitaire: (json['coutUnitaire'] ?? 0.0).toDouble(),
    );
  }
}

/// Statistiques d'une commande d'approvisionnement
class StatistiquesCommande {
  final int totalQuantiteCommandee;
  final int totalQuantiteRecue;
  final int pourcentageReception;
  final int nombreProduits;
  final int produitsCompletsRecus;

  StatistiquesCommande({
    required this.totalQuantiteCommandee,
    required this.totalQuantiteRecue,
    required this.pourcentageReception,
    required this.nombreProduits,
    required this.produitsCompletsRecus,
  });

  factory StatistiquesCommande.fromJson(Map<String, dynamic> json) {
    return StatistiquesCommande(
      totalQuantiteCommandee: json['totalQuantiteCommandee'] ?? 0,
      totalQuantiteRecue: json['totalQuantiteRecue'] ?? 0,
      pourcentageReception: json['pourcentageReception'] ?? 0,
      nombreProduits: json['nombreProduits'] ?? 0,
      produitsCompletsRecus: json['produitsCompletsRecus'] ?? 0,
    );
  }
}

/// Commande d'approvisionnement
class CommandeApprovisionnement {
  final int id;
  final String numeroCommande;
  final int fournisseurId;
  final Supplier? fournisseur;
  final CommandeStatut statut;
  final DateTime dateCommande;
  final DateTime? dateLivraisonPrevue;
  final double? montantTotal;
  final ModePaiement modePaiement;
  final String? notes;
  final List<DetailCommandeApprovisionnement> details;
  final StatistiquesCommande? statistiques;

  CommandeApprovisionnement({
    required this.id,
    required this.numeroCommande,
    required this.fournisseurId,
    this.fournisseur,
    required this.statut,
    required this.dateCommande,
    this.dateLivraisonPrevue,
    this.montantTotal,
    required this.modePaiement,
    this.notes,
    required this.details,
    this.statistiques,
  });

  /// Indique si la commande peut être modifiée
  bool get peutEtreModifiee => statut != CommandeStatut.terminee && statut != CommandeStatut.annulee;

  /// Indique si la commande peut être réceptionnée
  bool get peutEtreReceptionnee => statut == CommandeStatut.enAttente || statut == CommandeStatut.partielle;

  factory CommandeApprovisionnement.fromJson(Map<String, dynamic> json) {
    return CommandeApprovisionnement(
      id: json['id'] ?? 0,
      numeroCommande: json['numeroCommande'] ?? '',
      fournisseurId: json['fournisseurId'] ?? 0,
      fournisseur: json['fournisseur'] != null ? Supplier.fromJson(json['fournisseur']) : null,
      statut: CommandeStatut.fromString(json['statut'] ?? 'en_attente'),
      dateCommande: DateTime.parse(json['dateCommande'] ?? DateTime.now().toIso8601String()),
      dateLivraisonPrevue: json['dateLivraisonPrevue'] != null ? DateTime.parse(json['dateLivraisonPrevue']) : null,
      montantTotal: json['montantTotal']?.toDouble(),
      modePaiement: ModePaiement.fromString(json['modePaiement'] ?? 'credit'),
      notes: json['notes'],
      details: (json['details'] as List<dynamic>?)?.map((detail) => DetailCommandeApprovisionnement.fromJson(detail)).toList() ?? [],
      statistiques: json['statistiques'] != null ? StatistiquesCommande.fromJson(json['statistiques']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numeroCommande': numeroCommande,
      'fournisseurId': fournisseurId,
      'statut': statut.value,
      'dateCommande': dateCommande.toIso8601String(),
      'dateLivraisonPrevue': dateLivraisonPrevue?.toIso8601String(),
      'montantTotal': montantTotal,
      'modePaiement': modePaiement.value,
      'notes': notes,
    };
  }
}
