void main() {
  print('🧪 Test des types de données pour le widget graphique...');

  // Simuler différents types de données que l'API peut retourner
  final testData = [
    // Cas 1: revenue comme double
    {
      'date': '2025-11-01',
      'sales': 5,
      'revenue': 150.50, // double
    },
    // Cas 2: revenue comme int
    {
      'date': '2025-11-02',
      'sales': 3,
      'revenue': 100, // int
    },
    // Cas 3: revenue comme String (cas d'erreur potentiel)
    {
      'date': '2025-11-03',
      'sales': 2,
      'revenue': '75.25', // String
    },
    // Cas 4: revenue null
    {
      'date': '2025-11-04',
      'sales': 0,
      'revenue': null, // null
    },
  ];

  print('\n📊 Test de conversion des types:');

  for (int i = 0; i < testData.length; i++) {
    final data = testData[i];
    print('\nTest ${i + 1}: ${data['date']}');
    print('  Sales: ${data['sales']} (${data['sales'].runtimeType})');
    print('  Revenue original: ${data['revenue']} (${data['revenue'].runtimeType})');

    try {
      // Test de la conversion comme dans le widget
      final sales = (data['sales'] ?? 0) as int;
      final revenue = ((data['revenue'] ?? 0.0) as num).toDouble();

      print('  ✅ Sales converti: $sales (int)');
      print('  ✅ Revenue converti: $revenue (double)');

      // Test des calculs de normalisation
      final maxSales = 10;
      final maxRevenue = 200.0;

      final salesHeight = maxSales > 0 ? (sales / maxSales * 150).clamp(sales > 0 ? 15.0 : 0.0, 150.0) : 0.0;
      final revenueHeight = maxRevenue > 0 ? (revenue / maxRevenue * 150).clamp(revenue > 0 ? 15.0 : 0.0, 150.0) : 0.0;

      print('  📏 Hauteur sales: ${salesHeight.toStringAsFixed(1)}px');
      print('  📏 Hauteur revenue: ${revenueHeight.toStringAsFixed(1)}px');
    } catch (e) {
      print('  ❌ Erreur de conversion: $e');

      // Solution alternative pour les cas problématiques
      try {
        final sales = (data['sales'] ?? 0) as int;
        final revenueRaw = data['revenue'];
        double revenue = 0.0;

        if (revenueRaw is num) {
          revenue = revenueRaw.toDouble();
        } else if (revenueRaw is String) {
          revenue = double.tryParse(revenueRaw) ?? 0.0;
        }

        print('  🔧 Solution alternative: sales=$sales, revenue=$revenue');
      } catch (e2) {
        print('  💥 Échec total: $e2');
      }
    }
  }

  print('\n🎯 Recommandations:');
  print('  - Utiliser ((value ?? 0.0) as num).toDouble() pour les revenues');
  print('  - Utiliser (value ?? 0) as int pour les sales');
  print('  - Ajouter une validation côté backend pour garantir les types');
  print('  - Considérer l\'utilisation de modèles Dart typés');

  print('\n✅ Test terminé - Le widget devrait maintenant fonctionner !');
}
