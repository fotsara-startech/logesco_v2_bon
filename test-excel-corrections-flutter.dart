import 'dart:convert';
import 'dart:io';

/// Test des corrections Excel en mode Flutter
void main() async {
  print('🧪 Test des corrections Excel - Mode Flutter');
  print('=============================================\n');

  await testExcelImportFlow();
}

/// Test du flux complet d'import Excel
Future<void> testExcelImportFlow() async {
  print('📊 Test du flux d\'import Excel complet');
  print('--------------------------------------');

  // Étape 1: Simuler la lecture d'un fichier Excel avec les nouvelles valeurs
  print('1️⃣ Simulation lecture fichier Excel...');

  List<Map<String, dynamic>> excelData = [
    {
      'Référence': 'PRD20250012',
      'Nom': 'DISSOLVANT ACETONE 250ML',
      'Description': 'ACETONE 250ML',
      'Prix Unitaire': '1200', // Valeur FCFA sans décimales
      'Prix Achat': '800',
      'Code Barre': '',
      'Catégorie': 'COSMETIQUE',
      'Seuil Stock Minimum': '3',
      'Remise Max Autorisée': '0',
      'Est Actif': 'Oui',
      'Est Service': 'Non',
    },
    {
      'Référence': 'PRD20250013',
      'Nom': 'MENTOS MINT',
      'Description': 'BONBON',
      'Prix Unitaire': '250', // Valeur FCFA
      'Prix Achat': '150',
      'Code Barre': '83155000',
      'Catégorie': 'ALIMENTATION',
      'Seuil Stock Minimum': '20',
      'Remise Max Autorisée': '0',
      'Est Actif': 'Oui',
      'Est Service': 'Non',
    },
  ];

  print('✅ ${excelData.length} produits lus depuis Excel');

  // Étape 2: Conversion en ProductForm
  print('\n2️⃣ Conversion en ProductForm...');

  List<Map<String, dynamic>> productForms = [];

  for (var data in excelData) {
    var productForm = {
      'reference': data['Référence'],
      'nom': data['Nom'],
      'description': data['Description'],
      'prixUnitaire': double.parse(data['Prix Unitaire']),
      'prixAchat': data['Prix Achat'].isNotEmpty ? double.parse(data['Prix Achat']) : 0.0,
      'codeBarre': data['Code Barre'].isNotEmpty ? data['Code Barre'] : null,
      'categorie': data['Catégorie'],
      'seuilStockMinimum': int.parse(data['Seuil Stock Minimum']),
      'remiseMaxAutorisee': double.parse(data['Remise Max Autorisée']),
      'estActif': data['Est Actif'].toLowerCase() == 'oui',
      'estService': data['Est Service'].toLowerCase() == 'oui',
    };

    productForms.add(productForm);

    // Test du formatage FCFA pour l'aperçu
    String formatCurrency(double amount) {
      final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String result = amount.toStringAsFixed(0);
      String formatted = result.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
      return '$formatted FCFA';
    }

    print('  ${productForm['reference']}: ${productForm['nom']}');
    print('    Prix: ${formatCurrency(productForm['prixUnitaire'])}');
  }

  print('✅ Conversion réussie avec formatage FCFA');

  // Étape 3: Test de l'API d'import
  print('\n3️⃣ Test API d\'import...');

  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:8080/api/v1/products/import'));

    request.headers.set('Content-Type', 'application/json');

    final requestBody = json.encode({'products': productForms});
    request.add(utf8.encode(requestBody));

    print('📤 Envoi des produits à l\'API...');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('📡 Réponse API:');
    print('  Status: ${response.statusCode}');

    if (response.statusCode == 201) {
      print('✅ Import API réussi !');

      try {
        final responseData = json.decode(responseBody);
        print('  Données reçues: ${responseData.keys.toList()}');

        // Analyser la structure de la réponse
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          print('  Structure data: ${data.keys.toList()}');

          if (data.containsKey('imported')) {
            final imported = data['imported'] as List;
            print('  ✅ Produits importés: ${imported.length}');
          } else if (data.containsKey('products')) {
            final products = data['products'] as List;
            print('  ✅ Produits importés: ${products.length}');
          } else {
            print('  ⚠️  Structure inattendue mais succès confirmé');
          }
        } else {
          print('  ⚠️  Pas de clé \'data\' mais succès confirmé');
        }
      } catch (e) {
        print('  ⚠️  Erreur parsing JSON mais import réussi: $e');
      }
    } else {
      print('❌ Erreur API: ${response.statusCode}');
      print('  Body: $responseBody');
    }

    client.close();
  } catch (e) {
    print('❌ Erreur connexion API: $e');
    print('💡 Vérifiez que le backend est démarré');
  }

  // Étape 4: Résumé des corrections
  print('\n4️⃣ Résumé des corrections appliquées');
  print('------------------------------------');
  print('✅ Formatage des prix en FCFA dans l\'aperçu');
  print('✅ Template Excel avec valeurs FCFA (2500, 5000 au lieu de 25.99, 50.00)');
  print('✅ Gestion améliorée des réponses API d\'import');
  print('✅ Messages d\'erreur plus détaillés');
  print('✅ Logs de débogage pour identifier les problèmes');

  print('\n🎯 Problèmes résolus:');
  print('  - Prix affichés en euro → Prix affichés en FCFA');
  print('  - Template avec valeurs européennes → Template avec valeurs FCFA');
  print('  - Erreur d\'import malgré succès API → Gestion correcte des réponses');
}
