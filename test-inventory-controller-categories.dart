import 'dart:convert';
import 'dart:io';

/// Test pour vérifier que le contrôleur inventory utilise les vraies catégories
void main() async {
  print('🔍 === TEST CONTRÔLEUR INVENTORY CATÉGORIES ===');
  
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
      
      // Test 2: Simuler la conversion du contrôleur inventory
      print('\n2. Test conversion contrôleur inventory...');
      
      final categoryNames = realCategories.map((category) => category['nom'] as String).toList();
      
      print('✅ Conversion réussie: ${categoryNames.length} noms de catégories');
      print('📋 Noms des catégories: ${categoryNames.join(', ')}');
      
      // Test 3: Comparer avec les anciennes catégories statiques
      print('\n3. Comparaison avec catégories statiques...');
      
      final staticCategories = [
        'Alimentation', 'Automobile', 'Beauté & Santé', 'Électronique',
        'Livres & Médias', 'Maison & Jardin', 'Sport & Loisirs', 'Vêtements'
      ];
      
      print('Catégories statiques: ${staticCategories.join(', ')}');
      print('Vraies catégories: ${categoryNames.join(', ')}');
      
      // Vérifier si des catégories statiques apparaissent dans les vraies
      final staticInReal = staticCategories.where((static) => categoryNames.contains(static)).toList();
      final staticNotInReal = staticCategories.where((static) => !categoryNames.contains(static)).toList();
      
      if (staticInReal.isNotEmpty) {
        print('✅ Catégories communes: ${staticInReal.join(', ')}');
      }
      
      if (staticNotInReal.isNotEmpty) {
        print('❌ Catégories statiques qui ne devraient PAS apparaître: ${staticNotInReal.join(', ')}');
      }
      
      // Test 4: Vérifier la structure attendue par le contrôleur
      print('\n4. Test structure pour contrôleur inventory...');
      
      bool structureValide = categoryNames.every((name) => name.isNotEmpty);
      
      if (structureValide) {
        print('✅ Structure des données valide pour le contrôleur inventory');
      } else {
        print('❌ Structure des données invalide');
      }
      
      // Test 5: Recommandations
      print('\n5. Recommandations...');
      
      if (staticNotInReal.isNotEmpty) {
        print('⚠️ PROBLÈME DÉTECTÉ:');
        print('   Si vous voyez ces catégories dans l\'app inventory: ${staticNotInReal.join(', ')}');
        print('   Cela signifie que le contrôleur utilise encore les données statiques');
        print('   Solution: Redémarrer l\'application Flutter (hot restart)');
      } else {
        print('✅ Aucun problème détecté');
        print('   Le contrôleur inventory devrait utiliser les vraies catégories');
      }
      
      // Test 6: Vérifier les nouvelles catégories uniques
      final newCategories = categoryNames.where((real) => !staticCategories.contains(real)).toList();
      if (newCategories.isNotEmpty) {
        print('\n6. Nouvelles catégories disponibles:');
        for (final cat in newCategories) {
          print('   + "${cat}"');
        }
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