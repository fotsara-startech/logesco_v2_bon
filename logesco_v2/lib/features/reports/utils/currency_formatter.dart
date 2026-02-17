import 'package:intl/intl.dart';

/// Utilitaire pour formater les montants avec séparateurs de milliers
class CurrencyFormatter {
  /// Formateur pour les montants avec séparateur de milliers (format français)
  static final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'fr_FR');
  
  /// Formate un montant avec séparateur de milliers et devise FCFA
  static String formatAmount(double amount) {
    return '${_currencyFormatter.format(amount)} FCFA';
  }
  
  /// Formate un nombre avec séparateur de milliers (sans devise)
  static String formatNumber(double number) {
    return _currencyFormatter.format(number);
  }
  
  /// Formate un pourcentage avec une décimale
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}