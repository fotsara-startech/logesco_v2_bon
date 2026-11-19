import 'package:get/get.dart';
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
            return DateTime.parse(value).toLocal();
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
      print(' [CustomerTransaction.fromJson] Erreur de parsing: $e');
      print('');
      rethrow;
    }
  }

  String get typeTransactionDisplay {
    switch (typeTransaction) {
      case 'paiement':
        return 'plain_payment'.tr;
      case 'credit':
        return 'sales_payment_credit'.tr;
      case 'debit':
        return 'customers_debit'.tr;
      case 'achat':
        return 'plain_purchase'.tr;
      // Anciens types pour compatibilité
      case 'paiement_dette':
        return 'plain_debt_payment'.tr;
      case 'achat_credit':
        return 'customers_credit_purchase'.tr;
      case 'achat_comptant':
        return 'plain_cash_purchase'.tr;
      case 'credit_manuel':
        return 'plain_manual_credit'.tr;
      case 'debit_manuel':
        return 'plain_manual_debit'.tr;
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
