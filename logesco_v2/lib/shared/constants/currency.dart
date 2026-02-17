/// Constantes pour la gestion de la devise
class CurrencyConstants {
  /// Devise par défaut de l'application
  static const String defaultCurrency = 'FCFA';

  /// Symbole de la devise par défaut
  static const String defaultCurrencySymbol = 'FCFA';

  /// Nombre de décimales pour l'affichage des montants
  /// FCFA n'utilise généralement pas de décimales
  static const int decimalPlaces = 0;

  /// Formate un montant avec la devise par défaut
  static String formatAmount(double amount) {
    return '${amount.toStringAsFixed(decimalPlaces)} $defaultCurrency';
  }

  /// Formate un montant avec signe (+ ou -)
  static String formatAmountWithSign(double amount, bool isPositive) {
    final sign = isPositive ? '+' : '-';
    return '$sign${amount.abs().toStringAsFixed(decimalPlaces)} $defaultCurrency';
  }

  /// Formate un montant pour les formulaires de saisie
  static String formatAmountForInput(double amount) {
    return amount.toStringAsFixed(decimalPlaces);
  }
}
