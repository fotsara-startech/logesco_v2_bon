/**
 * Utilitaires pour le formatage des devises
 */

class CurrencyFormatter {
  /// Formate un montant avec séparateur de milliers
  /// Exemple: 1234567.89 -> "1 234 568 FCFA"
  static String formatCurrency(double amount, {String currency = 'FCFA'}) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = amount.toStringAsFixed(0);
    String formatted = result.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
    return '$formatted $currency';
  }

  /// Formate un montant sans la devise
  /// Exemple: 1234567.89 -> "1 234 568"
  static String formatAmount(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = amount.toStringAsFixed(0);
    return result.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
  }

  /// Parse un montant formaté vers un double
  /// Exemple: "1 234 568" -> 1234568.0
  static double parseAmount(String formattedAmount) {
    String cleaned = formattedAmount.replaceAll(' ', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Formate un montant avec décimales si nécessaire
  /// Exemple: 1234.50 -> "1 234,50 FCFA", 1234.00 -> "1 234 FCFA"
  static String formatCurrencyWithDecimals(double amount, {String currency = 'FCFA'}) {
    bool hasDecimals = amount % 1 != 0;

    if (hasDecimals) {
      final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String result = amount.toStringAsFixed(2).replaceAll('.', ',');
      String formatted = result.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
      return '$formatted $currency';
    } else {
      return formatCurrency(amount, currency: currency);
    }
  }
}
