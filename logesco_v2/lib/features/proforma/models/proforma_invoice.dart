import '../../customers/models/customer.dart';
import '../../sales/models/sale.dart';

/// Statuts possibles d'une proforma
class ProformaStatut {
  static const String brouillon = 'brouillon';
  static const String validee = 'validee';
  static const String annulee = 'annulee';
}

/// Modèle d'une facture proforma (stockée en base de données)
class ProformaInvoice {
  final int id;
  final String numeroProforma;
  final Customer? client;
  final int? clientId;
  final String modePaiement;
  final double sousTotal;
  final double montantTotal;
  final double montantRemise;
  final double montantTva;
  final double? tauxTva;
  final List<ProformaItem> items;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final String statut; // 'brouillon' | 'validee' | 'annulee'
  final int? vendeurId;
  final String? vendeurNom;
  final DateTime? dateVente; // Pour l'antidatage lors de la validation

  ProformaInvoice({
    required this.id,
    required this.numeroProforma,
    this.client,
    this.clientId,
    required this.modePaiement,
    required this.sousTotal,
    required this.montantTotal,
    required this.montantRemise,
    this.montantTva = 0.0,
    this.tauxTva,
    required this.items,
    required this.dateCreation,
    this.dateModification,
    required this.statut,
    this.vendeurId,
    this.vendeurNom,
    this.dateVente,
  });

  bool get isBrouillon => statut == ProformaStatut.brouillon;
  bool get isValidee => statut == ProformaStatut.validee;
  bool get isAnnulee => statut == ProformaStatut.annulee;

  factory ProformaInvoice.fromJson(Map<String, dynamic> json) {
    return ProformaInvoice(
      id: _parseInt(json['id']),
      numeroProforma: json['numeroProforma']?.toString() ?? json['numero']?.toString() ?? '',
      clientId: _parseIntNullable(json['clientId']),
      client: json['client'] != null ? Customer.fromJson(json['client'] as Map<String, dynamic>) : null,
      modePaiement: json['modePaiement']?.toString() ?? 'comptant',
      sousTotal: _parseDouble(json['sousTotal']),
      montantTotal: _parseDouble(json['montantTotal']),
      montantRemise: _parseDouble(json['montantRemise']),
      montantTva: _parseDouble(json['montantTva']),
      tauxTva: _parseDoubleNullable(json['tauxTva']),
      items: (json['details'] as List<dynamic>? ?? []).map((e) => ProformaItem.fromJson(e as Map<String, dynamic>)).toList(),
      dateCreation: _parseDate(json['dateCreation'] ?? json['createdAt']),
      dateModification: json['dateModification'] != null ? _parseDate(json['dateModification']) : null,
      statut: json['statut']?.toString() ?? ProformaStatut.brouillon,
      vendeurId: _parseIntNullable(json['vendeurId']),
      vendeurNom: json['vendeur']?['nomUtilisateur']?.toString(),
      dateVente: json['dateVente'] != null ? _parseDate(json['dateVente']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'numeroProforma': numeroProforma,
        'clientId': clientId,
        'modePaiement': modePaiement,
        'sousTotal': sousTotal,
        'montantTotal': montantTotal,
        'montantRemise': montantRemise,
        'montantTva': montantTva,
        'tauxTva': tauxTva,
        'statut': statut,
        'vendeurId': vendeurId,
        'dateVente': dateVente?.toIso8601String(),
        'details': items.map((e) => e.toJson()).toList(),
      };

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _parseIntNullable(dynamic v) {
    if (v == null) return null;
    return _parseInt(v);
  }

  static double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static double? _parseDoubleNullable(dynamic v) {
    if (v == null) return null;
    return _parseDouble(v);
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Ligne d'article d'une proforma
class ProformaItem {
  final int id;
  final int proformaId;
  final int produitId;
  final String? produitNom;
  final String? produitReference;
  final int quantite;
  final double prixUnitaire;
  final double prixAffiche;
  final double remiseAppliquee;
  final String? justificationRemise;
  final double montantLigne;

  ProformaItem({
    required this.id,
    required this.proformaId,
    required this.produitId,
    this.produitNom,
    this.produitReference,
    required this.quantite,
    required this.prixUnitaire,
    required this.prixAffiche,
    this.remiseAppliquee = 0.0,
    this.justificationRemise,
    required this.montantLigne,
  });

  factory ProformaItem.fromJson(Map<String, dynamic> json) {
    final prixUnit = ProformaInvoice._parseDouble(json['prixUnitaire']);
    final qte = json['quantite'] is int ? json['quantite'] as int : int.tryParse(json['quantite'].toString()) ?? 0;
    return ProformaItem(
      id: ProformaInvoice._parseInt(json['id']),
      proformaId: ProformaInvoice._parseInt(json['proformaId'] ?? json['venteProformaId'] ?? 0),
      produitId: ProformaInvoice._parseInt(json['produitId']),
      produitNom: json['produit']?['nom']?.toString() ?? json['produitNom']?.toString(),
      produitReference: json['produit']?['reference']?.toString() ?? json['produitReference']?.toString(),
      quantite: qte,
      prixUnitaire: prixUnit,
      prixAffiche: ProformaInvoice._parseDouble(json['prixAffiche']),
      remiseAppliquee: ProformaInvoice._parseDouble(json['remiseAppliquee']),
      justificationRemise: json['justificationRemise']?.toString(),
      montantLigne: ProformaInvoice._parseDouble(json['prixTotal'] ?? json['montantLigne'] ?? (prixUnit * qte)),
    );
  }

  Map<String, dynamic> toJson() => {
        'produitId': produitId,
        'quantite': quantite,
        'prixUnitaire': prixUnitaire,
        'prixAffiche': prixAffiche,
        'remiseAppliquee': remiseAppliquee,
        'justificationRemise': justificationRemise,
      };

  /// Convertit en CartItem pour réédition dans le panier
  CartItem toCartItem() => CartItem(
        productId: produitId,
        productName: produitNom ?? 'Produit $produitId',
        productReference: produitReference ?? '',
        quantity: quantite,
        unitPrice: prixUnitaire,
        originalPrice: prixAffiche > 0 ? prixAffiche : prixUnitaire,
        discountApplied: remiseAppliquee,
        discountJustification: justificationRemise,
      );
}

/// Requête de création d'une proforma
class CreateProformaRequest {
  final int? clientId;
  final String modePaiement;
  final double montantRemise;
  final double montantTva;
  final double? tauxTva;
  final DateTime? dateVente;
  final List<CreateProformaDetailRequest> details;

  CreateProformaRequest({
    this.clientId,
    required this.modePaiement,
    required this.montantRemise,
    this.montantTva = 0.0,
    this.tauxTva,
    this.dateVente,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'modePaiement': modePaiement,
        'montantRemise': montantRemise,
        'montantTva': montantTva,
        'tauxTva': tauxTva,
        'dateVente': dateVente?.toIso8601String(),
        'details': details.map((e) => e.toJson()).toList(),
      };
}

/// Détail d'une ligne dans la requête de création
class CreateProformaDetailRequest {
  final int produitId;
  final int quantite;
  final double prixUnitaire;
  final double prixAffiche;
  final double remiseAppliquee;
  final String? justificationRemise;

  CreateProformaDetailRequest({
    required this.produitId,
    required this.quantite,
    required this.prixUnitaire,
    required this.prixAffiche,
    this.remiseAppliquee = 0.0,
    this.justificationRemise,
  });

  Map<String, dynamic> toJson() => {
        'produitId': produitId,
        'quantite': quantite,
        'prixUnitaire': prixUnitaire,
        'prixAffiche': prixAffiche,
        'remiseAppliquee': remiseAppliquee,
        'justificationRemise': justificationRemise,
      };
}

/// Requête de validation d'une proforma (conversion en vente réelle)
class ValidateProformaRequest {
  final String modePaiement;
  final double montantPaye;
  final DateTime? dateVente;

  ValidateProformaRequest({
    required this.modePaiement,
    required this.montantPaye,
    this.dateVente,
  });

  Map<String, dynamic> toJson() => {
        'modePaiement': modePaiement,
        'montantPaye': montantPaye,
        'dateVente': dateVente?.toIso8601String(),
      };
}
