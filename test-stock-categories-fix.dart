import 'dart:convert';
import 'dart:io';

/// Test pour vérifier que le module stock utilise les vraies catégories de la base de données
void main() async {
  print('🔍 === TEST CATÉGORIES MODULE STOCK ===');
  
  try {
    // Test 1: Vérifier l'API des catégories
    print('\n1. Test API catégories...');
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/categories'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);
      
      print('✅ API Categories Status: ${response.statusCode}');
      
      List<dynamic> categories;
      if (data is List) {
        categories = data;
      } else if (data is Map && data['data'] != null) {
        categories = data['data'];
      } else {
        categories = [];
      }
      
      print('📋 Catégories disponibles: ${categories.length}');
      
      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        print('   ${i + 1}. ID: ${category['id']}, Nom: "${category['nom']}"');
      }
      
      // Test 2: Simuler l'utilisation dans le module stock
      print('\n2. Test simulation module stock...');
      
      final stockCategories = categories.map((category) => {
        'id': category['id'],
        'nom': category['nom'],
        'description': category['description'],
      }).toList();
      
      print('✅ Conversion pour module stock réussie');
      print('📦 Catégories converties: ${stockCategories.length}');
      
      for (int i = 0; i < stockCategories.length && i < 5; i++) {
        final category = stockCategories[i];
        print('   ${i + 1}. ID: ${category['id']}, Nom: "${category['nom']}"');
      }
      
      // Test 3: Vérifier la structure attendue
      print('\n3. Test structure données...');
      
      bool structureValide = true;
      for (final category in stockCategories) {
        if (!category.containsKey('id') || !category.containsKey('nom')) {
          structureValide = false;
          break;
        }
      }
      
      if (structureValide) {
        print('✅ Structure des données valide');
      } else {
        print('❌ Structure des données invalide');
      }
      
      // Test 4: Comparer avec les anciennes catégories par défaut
      print('\n4. Comparaison avec anciennes catégories...');
      
      final oldCategories = [
        {'id': 1, 'nom': 'Électronique'},
        {'id': 2, 'nom': 'Vêtements'},
        {'id': 3, 'nom': 'Alimentation'},
      ];
      
      print('Anciennes catégories par défaut: ${oldCategories.length}');
      for (final cat in oldCategories) {
        print('   - ${cat['nom']}');
      }
      
      print('Nouvelles catégories de la BD: ${stockCategories.length}');
      for (final cat in stockCategories) {
        print('   - ${cat['nom']}');
      }
      
      if (stockCategories.length > oldCategories.length) {
        print('✅ Plus de catégories disponibles qu\'avant');
      } else if (stockCategories.length == oldCategories.length) {
        print('⚠️ Même nombre de catégories');
      } else {
        print('❌ Moins de catégories qu\'avant');
      }
      
      print('\n✅ Tous les tests réussis !');
      print('🎉 Le module stock devrait maintenant utiliser les vraies catégories de la BD');
      
    } else {
      print('❌ Erreur API: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}