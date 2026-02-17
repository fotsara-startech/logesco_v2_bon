/// Modèles de données pour la gestion des comptes clients et fournisseurs

/// Modèle de base pour un compte
abstract class Account {
  final int id;
  final double soldeActuel;
  final double limiteCredit;
  final DateTime dateDerniereMaj;

  Account({
    required this.id,
    required this.soldeActuel,
    required this.limiteCredit,
    required this.dateDerniereMaj,
  });

  /// Calcule le crédit disponible
  double get creditDisponible => limiteCredit - soldeActuel;

  /// Vérifie si le compte est en dépassement de crédit
  bool get estEnDepassement => soldeActuel > limiteCredit;

  /// Vérifie si le compte a un solde positif (dette)
  bool get aSoldePositif => soldeActuel > 0;
}

/// Modèle pour un compte client
class CompteClient extends Account {
  final int clientId;
  final Client client;

  CompteClient({
    required super.id,
    required this.clientId,
    required this.client,
    required super.soldeActuel,
    required super.limiteCredit,
    required super.dateDerniereMaj,
  });

  /// Crée un compte client à partir d'un JSON
  factory CompteClient.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    DateTime parseDate(dynamic value, {DateTime? defaultValue}) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue ?? DateTime.now();
        }
      }
      return defaultValue ?? DateTime.now();
    }

    return CompteClient(
      id: parseInt(json['id']),
      clientId: parseInt(json['clientId']),
      client: Client.fromJson(json['client'] as Map<String, dynamic>),
      soldeActuel: parseDouble(json['soldeActuel']),
      limiteCredit: parseDouble(json['limiteCredit']),
      dateDerniereMaj: parseDate(json['dateDerniereMaj']),
    );
  }

  /// Convertit le compte client en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'client': client.toJson(),
      'soldeActuel': soldeActuel,
      'limiteCredit': limiteCredit,
      'creditDisponible': creditDisponible,
      'estEnDepassement': estEnDepassement,
      'dateDerniereMaj': dateDerniereMaj.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CompteClient(id: $id, client: ${client.nomComplet}, solde: $soldeActuel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompteClient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour un compte fournisseur
class CompteFournisseur extends Account {
  final int fournisseurId;
  final Fournisseur fournisseur;

  CompteFournisseur({
    required super.id,
    required this.fournisseurId,
    required this.fournisseur,
    required super.soldeActuel,
    required super.limiteCredit,
    required super.dateDerniereMaj,
  });

  /// Crée un compte fournisseur à partir d'un JSON
  factory CompteFournisseur.fromJson(Map<String, dynamic> json) {
    // Réutilise les helpers de parsing sécurisé
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    DateTime parseDate(dynamic value, {DateTime? defaultValue}) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue ?? DateTime.now();
        }
      }
      return defaultValue ?? DateTime.now();
    }

    return CompteFournisseur(
      id: parseInt(json['id']),
      fournisseurId: parseInt(json['fournisseurId']),
      fournisseur: Fournisseur.fromJson(json['fournisseur'] as Map<String, dynamic>),
      soldeActuel: parseDouble(json['soldeActuel']),
      limiteCredit: parseDouble(json['limiteCredit']),
      dateDerniereMaj: parseDate(json['dateDerniereMaj']),
    );
  }

  /// Convertit le compte fournisseur en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fournisseurId': fournisseurId,
      'fournisseur': fournisseur.toJson(),
      'soldeActuel': soldeActuel,
      'limiteCredit': limiteCredit,
      'creditDisponible': creditDisponible,
      'estEnDepassement': estEnDepassement,
      'dateDerniereMaj': dateDerniereMaj.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CompteFournisseur(id: $id, fournisseur: ${fournisseur.nom}, solde: $soldeActuel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompteFournisseur && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour une transaction de compte
class TransactionCompte {
  final int id;
  final String typeTransaction;
  final double montant;
  final String? description;
  final int? referenceId;
  final String? referenceType;
  final DateTime dateTransaction;
  final double soldeApres;

  // NOUVEAUX CHAMPS
  final int? venteId;
  final String? venteReference;
  final String? typeTransactionDetail;

  TransactionCompte({
    required this.id,
    required this.typeTransaction,
    required this.montant,
    this.description,
    this.referenceId,
    this.referenceType,
    required this.dateTransaction,
    required this.soldeApres,
    this.venteId,
    this.venteReference,
    this.typeTransactionDetail,
  });

  /// Crée une transaction à partir d'un JSON
  factory TransactionCompte.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les nombres de manière sûre
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value;
      }
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) {
        return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }

    DateTime parseDate(dynamic value, {DateTime? defaultValue}) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue ?? DateTime.now();
        }
      }
      return defaultValue ?? DateTime.now();
    }

    return TransactionCompte(
      id: parseInt(json['id']),
      typeTransaction: json['typeTransaction']?.toString() ?? '',
      montant: parseDouble(json['montant']),
      description: json['description']?.toString(),
      referenceId: json['referenceId'] != null ? parseInt(json['referenceId']) : null,
      referenceType: json['referenceType']?.toString(),
      dateTransaction: parseDate(json['dateTransaction']),
      soldeApres: parseDouble(json['soldeApres']),
      venteId: json['venteId'] != null ? parseInt(json['venteId']) : null,
      venteReference: json['venteReference']?.toString(),
      typeTransactionDetail: json['typeTransactionDetail']?.toString(),
    );
  }

  /// Convertit la transaction en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeTransaction': typeTransaction,
      'montant': montant,
      'description': description,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'dateTransaction': dateTransaction.toIso8601String(),
      'soldeApres': soldeApres,
      'venteId': venteId,
      'venteReference': venteReference,
      'typeTransactionDetail': typeTransactionDetail,
    };
  }

  /// Retourne le libellé formaté de la transaction
  String get libelleFormate {
    if (venteReference != null) {
      if (typeTransactionDetail == 'paiement_vente') {
        return 'Paiement Facture #$venteReference';
      } else if (typeTransactionDetail == 'paiement_dette') {
        return 'Paiement Dette (Vente #$venteReference)';
      } else if (typeTransactionDetail == 'vente_credit') {
        return 'Vente à Crédit #$venteReference';
      }
    }
    return typeTransactionLibelle;
  }

  /// Vérifie si la transaction est liée à une vente
  bool get isLinkedToSale => venteId != null;

  /// Retourne une description lisible du type de transaction
  String get typeTransactionLibelle {
    switch (typeTransaction) {
      case 'debit':
        return 'Débit';
      case 'credit':
        return 'Crédit';
      case 'paiement':
        return 'Paiement';
      case 'achat':
        return 'Achat';
      default:
        return typeTransaction;
    }
  }

  /// Vérifie si la transaction augmente le solde
  bool get augmenteSolde => typeTransaction == 'debit' || typeTransaction == 'achat';

  @override
  String toString() {
    return 'TransactionCompte(id: $id, type: $typeTransaction, montant: $montant)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionCompte && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour créer une nouvelle transaction
class TransactionForm {
  final double montant;
  final String typeTransaction;
  final String? description;

  TransactionForm({
    required this.montant,
    required this.typeTransaction,
    this.description,
  });

  /// Convertit le formulaire en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'montant': montant,
      'typeTransaction': typeTransaction,
      'description': description,
    };
  }

  /// Valide les données du formulaire
  bool get isValid {
    return montant > 0 && typeTransaction.isNotEmpty;
  }
}

/// Modèle pour mettre à jour la limite de crédit
class LimiteCreditForm {
  final double limiteCredit;

  LimiteCreditForm({
    required this.limiteCredit,
  });

  /// Convertit le formulaire en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'limiteCredit': limiteCredit,
    };
  }

  /// Valide les données du formulaire
  bool get isValid {
    return limiteCredit >= 0;
  }
}

/// Modèles simplifiés pour Client et Fournisseur (utilisés dans les comptes)
class Client {
  final int id;
  final String nom;
  final String? prenom;
  final String? telephone;
  final String? email;

  Client({
    required this.id,
    required this.nom,
    this.prenom,
    this.telephone,
    this.email,
  });

  /// Nom complet du client
  String get nomComplet => prenom != null ? '$nom $prenom' : nom;

  /// Crée un client à partir d'un JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
    );
  }

  /// Convertit le client en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'nomComplet': nomComplet,
    };
  }

  @override
  String toString() {
    return 'Client(id: $id, nom: $nomComplet)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Fournisseur {
  final int id;
  final String nom;
  final String? personneContact;
  final String? telephone;
  final String? email;

  Fournisseur({
    required this.id,
    required this.nom,
    this.personneContact,
    this.telephone,
    this.email,
  });

  /// Crée un fournisseur à partir d'un JSON
  factory Fournisseur.fromJson(Map<String, dynamic> json) {
    return Fournisseur(
      id: json['id'] as int,
      nom: json['nom'] as String,
      personneContact: json['personneContact'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
    );
  }

  /// Convertit le fournisseur en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'personneContact': personneContact,
      'telephone': telephone,
      'email': email,
    };
  }

  @override
  String toString() {
    return 'Fournisseur(id: $id, nom: $nom)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fournisseur && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour une vente impayée
class UnpaidSale {
  final int id;
  final String reference;
  final DateTime dateVente;
  final double montantTotal;
  final double montantPaye;
  final double montantRestant;
  final int nombreArticles;

  UnpaidSale({
    required this.id,
    required this.reference,
    required this.dateVente,
    required this.montantTotal,
    required this.montantPaye,
    required this.montantRestant,
    required this.nombreArticles,
  });

  factory UnpaidSale.fromJson(Map<String, dynamic> json) {
    return UnpaidSale(
      id: json['id'] as int,
      reference: json['reference'] as String,
      dateVente: DateTime.parse(json['dateVente'] as String),
      montantTotal: (json['montantTotal'] as num).toDouble(),
      montantPaye: (json['montantPaye'] as num).toDouble(),
      montantRestant: (json['montantRestant'] as num).toDouble(),
      nombreArticles: json['nombreArticles'] as int,
    );
  }

  String get dateVenteFormatted {
    return '${dateVente.day.toString().padLeft(2, '0')}/${dateVente.month.toString().padLeft(2, '0')}/${dateVente.year}';
  }

  String get montantTotalFormatted => '${montantTotal.toStringAsFixed(0)} FCFA';
  String get montantPayeFormatted => '${montantPaye.toStringAsFixed(0)} FCFA';
  String get montantRestantFormatted => '${montantRestant.toStringAsFixed(0)} FCFA';
}
