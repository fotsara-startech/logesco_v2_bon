import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing API connectivity...');

  try {
    // Test de base - ping du serveur (sans authentification, devrait retourner 401)
    final response = await http.get(
      Uri.parse('http://localhost:3002/api/v1/sales'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 5));

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
