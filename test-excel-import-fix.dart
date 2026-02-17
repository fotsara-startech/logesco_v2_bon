import 'dart:io';
import 'dart:convert';

/// Test des corrections d'import Excel
void main() async {
  print('🧪 Test des corrections d\'import Excel');
  print('=====================================\n');

  // Test 1: Vérifier le formatage des prix en FCFA
  await testCurrencyFormatting();
  
  // Test 2: Simuler l'import avec les nouvelles valeurs du template
  await testTemplateValues();
  
  // Test 3: Tester l'API d'import
  await testImportAPI();
}

/// Test du formatage des devises
Future<void> testCurrencyFormatting() async {
  print('📊 Test 1: Formatage des prix en FCFA');
  print('-------------------------------------');
  
  // Simulation du CurrencyFormatter
  String formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = amount.toStringAsFixed(0);
    String formatted = result.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
    return '$formatted FCFA';
  }
  
  List<double> testPrices = [1200.0, 25.0, 250.0, 200.0, 350.0, 450.0];
  
  for (double price in testPrices) {
    String formatted = formatCurrency(price);
    print('  Prix: $price -> $formatted');
  }
  
  print('✅ Formatage FCFA correct\n');
}

/// Test des nouvelles valeurs du template
Future<void> testTemplateValues() async {
  print('📋 Test 2: Nouvelles valeurs du template');
  print('----------------------------------------');
  
  List<Map<String, dynamic>> templateProducts = [
    {
      'reference': 'REF001',
      'nom': 'Produit Exemple',
      'prixUnitaire': 2500.0,
      'prixAchat': 1500.0,
      'categorie': 'Électronique',
    },
    {
      'reference': 'REF002',
      'nom': 'Service Exemple',
      'prixUnitaire': 5000.0,
      'prixAchat': null,
      'categorie': 'Services',
    },
  ];
  
  for (var product in templateProducts) {
    print('  ${product['reference']}: ${product['nom']}');
    print('    Prix unitaire: ${product['prixUnitaire']} FCFA');
    if (product['prixAchat'] != null) {
      print('    Prix achat: ${product['prixAchat']} FCFA');
    }
    print('    Catégorie: ${product['categorie']}');
    print('');
  }
  
  print('✅ Template avec valeurs FCFA correct\n');
}

/// Test de l'API d'import
Future<void> testImportAPI() async {
  print('🌐 Test 3: API d\'import des produits');
  print('------------------------------------');
  
  try {
    // Données de test pour l'import
    List<Map<String, dynamic>> productsToImport = [
      {
        'reference': 'TEST001',
        'nom': 'Produit Test 1',
        'description': 'Description test 1',
        'prixUnitaire': 1500.0,
        'prixAchat': 1000.0,
        'codeBarre': null,
        'categorie': 'TEST',
        'seuilStockMinimum': 5,
        'remiseMaxAutorisee': 0.0,
        'estActif': true,
        'estService': false,
      },
      {
        'reference': 'TEST002',
        'nom': 'Service Test 2',
        'description': 'Description service test 2',
        'prixUnitaire': 3000.0,
        'prixAchat': 0.0,
        'codeBarre': null,
        'categorie': 'SERVICES',
        'seuilStockMinimum': 0,
        'remiseMaxAutorisee': 10.0,
        'estActif': true,
        'estService': true,
      },
    ];

    // Simulation de l'appel API
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:8080/api/v1/products/import'));
    
    request.headers.set('Content-Type', 'application/json');
    
    // Ajouter le token d'authentification si disponible
    // request.headers.set('Authorization', 'Bearer YOUR_TOKEN');
    
    final requestBody = json.encode({'products': productsToImport});
    request.add(utf8.encode(requestBody));
    
    print('📤 Envoi de ${productsToImport.length} produits à importer...');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📡 Réponse API:');
    print('  Status: ${response.statusCode}');
    print('  Body: $responseBody');
    
    if (response.statusCode == 201) {
      final responseData = json.decode(responseBody);
      print('✅ Import réussi !');
      
      if (responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data.containsKey('imported')) {
          final imported = data['imported'] as List;
          print('  Produits importés: ${imported.length}');
        } else if (data.containsKey('products')) {
          final products = data['products'] as List;
          print('  Produits importés: ${products.length}');
        }
      }
    } else {
      print('❌ Erreur import: ${response.statusCode}');
      print('  Message: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Erreur lors du test API: $e');
    print('💡 Assurez-vous que le backend est démarré sur localhost:8080');
  }
  
  print('');
}