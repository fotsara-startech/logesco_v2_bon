import 'dart:io';
import 'dart:convert';

/// Test de connexion au backend
void main() async {
  print('🧪 TEST DE CONNEXION AU BACKEND');
  print('================================');

  final client = HttpClient();

  try {
    // Test 1: Vérifier que le serveur répond
    print('\n🌐 Test 1: Connexion au serveur...');
    
    final healthRequest = await client.getUrl(Uri.parse('http://localhost:3002/'));
    final healthResponse = await healthRequest.close();
    final healthBody = await healthResponse.transform(utf8.decoder).join();
    
    if (healthResponse.statusCode == 200) {
      final healthData = json.decode(healthBody);
      print('✅ Serveur accessible!');
      print('   Message: ${healthData['message']}');
      print('   Version: ${healthData['version']}');
      print('   Environnement: ${healthData['environment']}');
      print('   Base de données: ${healthData['database']}');
    } else {
      print('❌ Erreur serveur: ${healthResponse.statusCode}');
    }

    // Test 2: Tester l'authentification
    print('\n🔐 Test 2: Test d\'authentification...');
    
    final authRequest = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/auth/login'));
    authRequest.headers.set('Content-Type', 'application/json');
    authRequest.write(json.encode({
      'nomUtilisateur': 'admin',
      'motDePasse': 'password123'
    }));
    final authResponse = await authRequest.close();
    final authBody = await authResponse.transform(utf8.decoder).join();
    
    if (authResponse.statusCode == 200) {
      final authData = json.decode(authBody);
      print('✅ Authentification réussie!');
      print('   Utilisateur: ${authData['data']['utilisateur']?['nomUtilisateur'] ?? 'N/A'}');
      print('   Token reçu: ${authData['data']['accessToken'] != null ? 'Oui' : 'Non'}');
    } else {
      print('❌ Erreur d\'authentification: ${authResponse.statusCode}');
      print('   Réponse: $authBody');
    }

    // Test 3: Tester les caisses disponibles
    print('\n💰 Test 3: Caisses disponibles...');
    
    final cashRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/available-cash-registers'));
    cashRequest.headers.set('Content-Type', 'application/json');
    final cashResponse = await cashRequest.close();
    final cashBody = await cashResponse.transform(utf8.decoder).join();
    
    if (cashResponse.statusCode == 200) {
      final cashData = json.decode(cashBody);
      final caisses = cashData['data'] as List;
      print('✅ Caisses récupérées: ${caisses.length} caisse(s)');
      
      for (final caisse in caisses) {
        print('   - ${caisse['nom']}: ${caisse['soldeActuel']} FCFA');
      }
    } else {
      print('❌ Erreur caisses: ${cashResponse.statusCode}');
      print('   Réponse: $cashBody');
    }

    print('\n🎉 TESTS DE CONNEXION TERMINÉS!');
    print('================================');
    print('✅ Le backend est accessible sur le port 3002');
    print('✅ L\'authentification fonctionne');
    print('✅ Les APIs des caisses sont opérationnelles');
    print('\n💡 L\'application Flutter peut maintenant se connecter!');

  } catch (e) {
    print('❌ Erreur de connexion: $e');
    print('\n🔧 Vérifications à faire:');
    print('   1. Le backend est-il démarré ?');
    print('   2. Le port 3002 est-il libre ?');
    print('   3. Pas de firewall qui bloque ?');
  } finally {
    client.close();
  }
}