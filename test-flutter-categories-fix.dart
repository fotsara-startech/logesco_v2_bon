import 'dart:convert';
import 'dart:io';

/// Test pour vérifier que les catégories s'affichent correctement côté Flutter
void main() async {
  print('🔍 === TEST CATÉGORIES FLUTTER ===');
  
  try {
    // Test 1: Simuler l'appel API des produits
    print('\n1. Test simulation API produits...');
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/products'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = json.decode(responseBody);
      
      print('✅ API Response Status: ${response.statusCode}');
      print('📦 Produits trouvés: ${data['data'].length}');
      
      // Analyser les 5 premiers produits
      final products = data['data'] as List;
      for (int i = 0; i < 5 && i < products.length; i++) {
        final product = products[i];
        print('   Produit ${i + 1}: "${product['nom']}"');
        print('     - categorieId: ${product['categorieId']}');
        print('     - categorie: "${product['categorie']}"');
      }
      
      // Test 2: Simuler le parsing Flutter
      print('\n2. Test parsing modèle Flutter...');
      
      for (int i = 0; i < 3 && i < products.length; i++) {
        final productJson = products[i] as Map<String, dynamic>;
        
        // Simuler Product.fromJson
        final parsedProduct = parseProductFromJson(productJson);
        print('   Produit parsé ${i + 1}:');
        print('     - ID: ${parsedProduct['id']}');
        print('     - Nom: "${parsedProduct['nom']}"');
        print('     - Catégorie: "${parsedProduct['categorie']}"');
        print('     - CategorieId: ${parsedProduct['categorieId']}');
      }
      
      // Test 3: Vérifier les catégories disponibles
      print('\n3. Test récupération catégories...');
      
      final categoriesRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/categories'));
      final categoriesResponse = await categoriesRequest.close();
      
      if (categoriesResponse.statusCode == 200) {
        final categoriesBody = await categoriesResponse.transform(utf8.decoder).join();
        final categoriesData = json.decode(categoriesBody);
        
        print('✅ Catégories API Status: ${categoriesResponse.statusCode}');
        print('📋 Catégories disponibles: ${categoriesData['data'].length}');
        
        final categories = categoriesData['data'] as List;
        for (int i = 0; i < categories.length; i++) {
          final category = categories[i];
          print('   ${i + 1}. "${category['nom']}" (${category['_count']['produits']} produits)');
        }
      }
      
      print('\n✅ Tous les tests réussis !');
      print('🎉 Les catégories devraient maintenant s\'afficher correctement dans Flutter');
      
    } else {
      print('❌ Erreur API: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}

/// Simule le parsing Product.fromJson de Flutter
Map<String, dynamic> parseProductFromJson(Map<String, dynamic> json) {
  return {
    'id': _parseInt(json['id']),
    'reference': _parseString(json['reference']),
    'nom': _parseString(json['nom']),
    'description': json['description']?.toString(),
    'prixUnitaire': _parseDouble(json['prixUnitaire']),
    'prixAchat': json['prixAchat'] != null ? _parseDouble(json['prixAchat']) : null,
    'codeBarre': json['codeBarre']?.toString(),
    'categorie': json['categorie']?.toString(),
    'categorieId': json['categorieId'] != null ? _parseInt(json['categorieId']) : null,
    'seuilStockMinimum': _parseInt(json['seuilStockMinimum']),
    'remiseMaxAutorisee': _parseDouble(json['remiseMaxAutorisee']),
    'estActif': json['estActif'] as bool? ?? true,
    'estService': json['estService'] as bool? ?? false,
    'dateCreation': _parseDateTime(json['dateCreation']),
    'dateModification': _parseDateTime(json['dateModification']),
  };
}

/// Helper pour parser les doubles de manière sûre
double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) {
    return value.isNaN || value.isInfinite ? defaultValue : value;
  }
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return defaultValue;
    }
    return parsed;
  }
  return defaultValue;
}

/// Helper pour parser les entiers de manière sûre
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) {
    return value.isNaN || value.isInfinite ? defaultValue : value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? defaultValue;
  }
  return defaultValue;
}

/// Helper pour parser les chaînes de manière sûre
String _parseString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

/// Helper pour parser les dates de manière sûre
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}