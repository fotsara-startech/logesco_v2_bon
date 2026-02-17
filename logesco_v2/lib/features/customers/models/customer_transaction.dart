class CustomerTransaction {
  final int id;
  final String typeTransaction;
  final double montant;
  final String? description;
  final DateTime dateTransaction;
  final double soldeApres;
  final String? referenceType;
  final int? referenceId;

  CustomerTransaction({
    required this.id,
    required this.typeTransaction,
    required this.montant,
    this.description,
    required this.dateTransaction,
    required this.soldeApres,
    this.referenceType,
    this.referenceId,
  });

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) {
    try {
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

      return CustomerTransaction(
        id: parseInt(json['id']),
        typeTransaction: json['typeTransaction']?.toString() ?? '',
        montant: parseDouble(json['montant']),
        description: json['description']?.toString(),
        dateTransaction: parseDate(json['dateTransaction']),
        soldeApres: parseDouble(json['soldeApres']),
        referenceType: json['referenceType']?.toString(),
        referenceId: json['referenceId'] != null ? parseInt(json['referenceId']) : null,
      );
    } catch (e) {
      print('❌ [CustomerTransaction.fromJson] Erreur de parsing: $e');
      print('📋 [CustomerTransaction.fromJson] JSON reçu: $json');
      rethrow;
    }
  }

  String get typeTransactionDisplay {
    switch (typeTransaction) {
      case 'paiement':
        return 'Paiement';
      case 'credit':
        return 'Crédit';
      case 'debit':
        return 'Débit';
      case 'achat':
        return 'Achat';
      // Anciens types pour compatibilité
      case 'paiement_dette':
        return 'Paiement dette';
      case 'achat_credit':
        return 'Achat à crédit';
      case 'achat_comptant':
        return 'Achat comptant';
      case 'credit_manuel':
        return 'Crédit manuel';
      case 'debit_manuel':
        return 'Débit manuel';
      default:
        return typeTransaction.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool get isCredit {
    return typeTransaction == 'paiement' || 
           typeTransaction == 'credit' || 
           typeTransaction == 'paiement_dette' || 
           typeTransaction == 'credit_manuel';
  }

  bool get isDebit {
    return typeTransaction == 'debit' || 
           typeTransaction == 'achat' || 
           typeTransaction == 'achat_credit' || 
           typeTransaction == 'achat_comptant' || 
           typeTransaction == 'debit_manuel';
  }
}
