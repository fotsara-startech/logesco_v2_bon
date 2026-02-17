import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Test de l\'API de stock...');

  const baseUrl = 'http://localhost:3002/api/v1';
  const inventoryEndpoint = '/inventory';

  try {
    // Test de connexion à l'API
    print('1. Test de connexion au serveur...');
    final response = await http.get(
      Uri.parse('$baseUrl$inventoryEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        // Note: En production, il faudrait un vrai token
        'Authorization': 'Bearer test-token',
      },
    ).timeout(const Duration(seconds: 10));

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      print('✅ API accessible');
      print('Données reçues: ${jsonData.toString()}');

      if (jsonData['data'] != null) {
        final stocks = jsonData['data'] as List;
        print('Nombre de stocks trouvés: ${stocks.length}');

        for (var stock in stocks.take(3)) {
          print('- Produit ${stock['produitId']}: ${stock['quantiteDisponible']} unités');
        }
      }
    } else if (response.statusCode == 401) {
      print('❌ Erreur d\'authentification - Token invalide');
    } else {
      print('❌ Erreur API: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur de connexion: $e');
    print('');
    print('Solutions possibles:');
    print('1. Vérifiez que le serveur backend est démarré sur le port 3002');
    print('2. Vérifiez la configuration de l\'API dans api_config.dart');
    print('3. Vérifiez que l\'endpoint /inventory existe dans le backend');
  }
}
