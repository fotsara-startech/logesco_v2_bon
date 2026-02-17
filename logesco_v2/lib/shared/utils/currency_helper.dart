import '../constants/currency.dart';

/// Utilitaires pour la gestion de la devise dans l'application
class CurrencyHelper {
  /// Remplace les anciennes méthodes de formatage par les nouvelles constantes
  static String formatCurrency(double amount) {
    return CurrencyConstants.formatAmount(amount);
  }

  /// Méthode de compatibilité pour _formatCurrency utilisée dans les widgets existants
  static String _formatCurrency(double amount) {
    return CurrencyConstants.formatAmount(amount);
  }

  /// Formate un montant avec signe
  static String formatCurrencyWithSign(double amount, bool isPositive) {
    return CurrencyConstants.formatAmountWithSign(amount, isPositive);
  }
}
