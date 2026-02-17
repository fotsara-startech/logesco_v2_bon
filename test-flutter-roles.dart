import 'dart:convert';
import 'dart:io';

void main() async {
  print('🧪 Test des rôles depuis Flutter...');

  try {
    // Simuler un appel HTTP comme le ferait Flutter
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/roles'));
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);

      print('✅ Réponse API reçue');
      print('📊 Nombre de rôles: ${data['data'].length}');

      if (data['data'].length == 1) {
        final role = data['data'][0];
        print('🎉 Parfait ! Un seul rôle trouvé:');
        print('   - Nom: ${role['nom']}');
        print('   - Affichage: ${role['displayName']}');
        print('   - Admin: ${role['isAdmin']}');
      } else {
        print('⚠️ Problème: ${data['data'].length} rôles trouvés au lieu de 1');
        for (var role in data['data']) {
          print('   - ${role['displayName']} (${role['nom']})');
        }
      }
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
    }

    client.close();
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
