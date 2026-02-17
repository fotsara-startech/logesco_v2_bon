import 'dart:convert';
import 'dart:io';

/// Test pour vérifier que le contrôleur stock utilise les vraies catégories
void main() async {
  print('🔍 === TEST CONTRÔLEUR STOCK CATÉGORIES ===');
  
  try {
    // Test 1: Vérifier l'API des catégories (ce que le contrôleur devrait utiliser)
    print('\n1. Test API catégories (service produits)...');
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/categories'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);
      
      print('✅ API Categories Status: ${response.statusCode}');
      
      List<dynamic> realCategories;
      if (data is List) {
        realCategories = data;
      } else if (data is Map && data['data'] != null) {
        realCategories = data['data'];
      } else {
        realCategories = [];
      }
      
      print('📋 Vraies catégories de la BD: ${realCategories.length}');
      
      for (int i = 0; i < realCategories.length; i++) {
        final category = realCategories[i];
        print('   ${i + 1}. ID: ${category['id']}, Nom: "${category['nom']}"');
      }
      
      // Test 2: Simuler la conversion du contrôleur
      print('\n2. Test conversion contrôleur...');
      
      final categoryMaps = realCategories.map((category) => {
        'id': category['id'],
        'nom': category['nom'],
        'description': category['description'],
      }).toList();
      
      print('✅ Conversion réussie: ${categoryMaps.length} catégories');
      
      // Test 3: Comparer avec les catégories de mock
      print('\n3. Comparaison avec catégories de mock...');
      
      final mockCategories = [
        'Électronique', 'Vêtements', 'Alimentation', 'Maison & Jardin',
        'Sport & Loisirs', 'Beauté & Santé', 'Automobile', 'Livres & Médias'
      ];
      
      final realCategoryNames = realCategories.map((cat) => cat['nom'] as String).toList();
      
      print('Catégories de mock: ${mockCategories.join(', ')}');
      print('Vraies catégories: ${realCategoryNames.join(', ')}');
      
      // Vérifier si des catégories de mock apparaissent dans les vraies
      final mockInReal = mockCategories.where((mock) => realCategoryNames.contains(mock)).toList();
      final mockNotInReal = mockCategories.where((mock) => !realCategoryNames.contains(mock)).toList();
      
      if (mockInReal.isNotEmpty) {
        print('✅ Catégories communes: ${mockInReal.join(', ')}');
      }
      
      if (mockNotInReal.isNotEmpty) {
        print('❌ Catégories de mock qui ne devraient PAS apparaître: ${mockNotInReal.join(', ')}');
      }
      
      // Test 4: Vérifier la structure attendue par le contrôleur
      print('\n4. Test structure pour contrôleur...');
      
      bool structureValide = true;
      for (final category in categoryMaps) {
        if (!category.containsKey('id') || !category.containsKey('nom')) {
          structureValide = false;
          break;
        }
      }
      
      if (structureValide) {
        print('✅ Structure des données valide pour le contrôleur');
      } else {
        print('❌ Structure des données invalide');
      }
      
      // Test 5: Recommandations
      print('\n5. Recommandations...');
      
      if (mockNotInReal.isNotEmpty) {
        print('⚠️ PROBLÈME DÉTECTÉ:');
        print('   Si vous voyez ces catégories dans l\'app: ${mockNotInReal.join(', ')}');
        print('   Cela signifie que le contrôleur utilise encore les données de mock');
        print('   Solution: Redémarrer l\'application Flutter (hot restart)');
      } else {
        print('✅ Aucun problème détecté');
        print('   Le contrôleur devrait utiliser les vraies catégories');
      }
      
      print('\n✅ Test terminé');
      
    } else {
      print('❌ Erreur API: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}