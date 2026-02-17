// Test du formatage des devises FCFA
void main() {
  print('🧪 TEST FORMATAGE DEVISES FCFA');
  print('===============================');

  // Test des montants typiques
  final testAmounts = [
    0.0,
    100.0,
    1000.0,
    15000.0,
    125000.0,
    1000000.0,
    1234567.89,
  ];

  print('\n💰 Test formatage des montants:');
  for (final amount in testAmounts) {
    final formatted = formatAmount(amount);
    final withSeparator = formatAmountWithSeparator(amount);
    print('  ${amount.toString().padLeft(12)} → $formatted (avec séparateur: $withSeparator)');
  }

  print('\n📊 Test calcul de différences:');
  final testDifferences = [
    [100.0, 150.0], // +50
    [200.0, 180.0], // -20
    [1000.0, 1000.0], // 0
    [50000.0, 75000.0], // +25000
  ];

  for (final diff in testDifferences) {
    final initial = diff[0];
    final final_ = diff[1];
    final difference = formatDifference(final_, initial);
    print('  ${initial.toInt()} → ${final_.toInt()} = $difference');
  }

  print('\n✅ Tests terminés!');
}

// Fonctions utilitaires simplifiées pour le test
String formatAmount(double amount, {bool showSymbol = true}) {
  final formatted = amount.toStringAsFixed(0);
  return showSymbol ? '$formatted FCFA' : formatted;
}

String formatAmountWithSeparator(double amount, {bool showSymbol = true}) {
  final formatted = _addThousandsSeparator(amount.round().toString());
  return showSymbol ? '$formatted FCFA' : formatted;
}

String formatDifference(double finalAmount, double initialAmount) {
  final difference = finalAmount - initialAmount;
  final sign = difference >= 0 ? '+' : '';
  return '$sign${formatAmount(difference.abs())}';
}

String _addThousandsSeparator(String number) {
  final reversed = number.split('').reversed.join('');
  final withSpaces = reversed.replaceAllMapped(
    RegExp(r'(\d{3})(?=\d)'),
    (match) => '${match.group(1)} ',
  );
  return withSpaces.split('').reversed.join('');
}