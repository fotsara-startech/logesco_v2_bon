import 'dart:io';

// Simulation du CurrencyFormatter pour tester le formatage
class CurrencyFormatter {
  static String formatAmount(double amount) {
    // Simulation du formatage avec séparateurs de milliers
    final formatted = amount.toStringAsFixed(0);
    
    // Ajouter les séparateurs de milliers manuellement
    final parts = <String>[];
    final chars = formatted.split('').reversed.toList();
    
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        parts.add(',');
      }
      parts.add(chars[i]);
    }
    
    return '${parts.reversed.join('')} FCFA';
  }
  
  static String formatNumber(double number) {
    final formatted = number.toStringAsFixed(0);
    final parts = <String>[];
    final chars = formatted.split('').reversed.toList();
    
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        parts.add(',');
      }
      parts.add(chars[i]);
    }
    
    return parts.reversed.join('');
  }
}

void main() {
  print('🧪 TEST DU FORMATAGE DES MONTANTS');
  print('=' * 50);
  
  // Test des montants du bilan comptable
  final testAmounts = [
    4460094.0,   // Chiffre d'affaires
    1740338.0,   // Bénéfice net
    4484.0,      // Dettes clients
    43700.0,     // Dépenses
    2676057.0,   // Coût marchandises
    2260.0,      // Dette individuelle
    1121.0,      // Dette moyenne
  ];
  
  print('\n📊 Test du formatage des montants:');
  print('-' * 40);
  
  for (final amount in testAmounts) {
    final formatted = CurrencyFormatter.formatAmount(amount);
    final number = CurrencyFormatter.formatNumber(amount);
    
    print('${amount.toStringAsFixed(0).padLeft(10)} → $formatted');
    print('${' ' * 10}   (nombre: $number)');
  }
  
  print('\n✅ Résultats attendus dans le PDF:');
  print('   - Chiffre d\'affaires: 4,460,094 FCFA');
  print('   - Bénéfice net: 1,740,338 FCFA');
  print('   - Dettes clients: 4,484 FCFA');
  print('   - Dépenses: 43,700 FCFA');
  print('   - Coût marchandises: 2,676,057 FCFA');
  
  print('\n🎯 Vérifications dans l\'application:');
  print('   1. Interface utilisateur: montants avec séparateurs');
  print('   2. PDF généré: montants lisibles avec virgules');
  print('   3. Aucune erreur de police dans les logs');
  print('   4. Tendances affichées comme "Hausse" / "Baisse"');
}