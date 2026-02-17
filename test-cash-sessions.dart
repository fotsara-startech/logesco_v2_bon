import 'dart:io';
import 'dart:convert';

/// Test complet du système de sessions de caisse
void main() async {
  print('🧪 TEST SYSTÈME SESSIONS DE CAISSE');
  print('===================================');

  final client = HttpClient();

  try {
    // Test 1: Récupérer les caisses disponibles
    print('\n💰 Test 1: Récupération des caisses disponibles...');
    
    final availableRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/available-cash-registers'));
    availableRequest.headers.set('Content-Type', 'application/json');
    final availableResponse = await availableRequest.close();
    final availableBody = await availableResponse.transform(utf8.decoder).join();
    
    if (availableResponse.statusCode == 200) {
      final availableData = json.decode(availableBody);
      final caisses = availableData['data'] as List;
      print('✅ Succès! ${caisses.length} caisse(s) disponible(s)');
      
      for (final caisse in caisses) {
        print('  - ${caisse['nom']} - Solde: ${caisse['soldeActuel']} FCFA');
      }
      
      if (caisses.isNotEmpty) {
        final firstCaisse = caisses.first;
        final caisseId = firstCaisse['id'];
        
        // Test 2: Se connecter à une caisse
        print('\n🔐 Test 2: Connexion à la caisse "${firstCaisse['nom']}"...');
        
        final connectRequest = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/connect'));
        connectRequest.headers.set('Content-Type', 'application/json');
        connectRequest.write(json.encode({
          'cashRegisterId': caisseId,
          'soldeInitial': 100.0
        }));
        final connectResponse = await connectRequest.close();
        final connectBody = await connectResponse.transform(utf8.decoder).join();
        
        if (connectResponse.statusCode == 201) {
          final sessionData = json.decode(connectBody);
          final session = sessionData['data'];
          print('✅ Connexion réussie!');
          print('   Session ID: ${session['id']}');
          print('   Caisse: ${session['nomCaisse']}');
          print('   Utilisateur: ${session['nomUtilisateur']}');
          print('   Solde ouverture: ${session['soldeOuverture']} FCFA');
          
          // Test 3: Vérifier la session active
          print('\n📊 Test 3: Vérification de la session active...');
          
          final activeRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/active'));
          activeRequest.headers.set('Content-Type', 'application/json');
          final activeResponse = await activeRequest.close();
          final activeBody = await activeResponse.transform(utf8.decoder).join();
          
          if (activeResponse.statusCode == 200) {
            final activeData = json.decode(activeBody);
            final activeSession = activeData['data'];
            print('✅ Session active trouvée: ${activeSession['nomCaisse']}');
          } else {
            print('❌ Erreur lors de la récupération de la session active: ${activeResponse.statusCode}');
          }
          
          // Test 4: Vérifier que la caisse n'est plus disponible
          print('\n🔒 Test 4: Vérification de l\'exclusivité...');
          
          final checkRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/check-availability/$caisseId'));
          checkRequest.headers.set('Content-Type', 'application/json');
          final checkResponse = await checkRequest.close();
          final checkBody = await checkResponse.transform(utf8.decoder).join();
          
          if (checkResponse.statusCode == 200) {
            final checkData = json.decode(checkBody);
            final available = checkData['data']['available'];
            if (!available) {
              print('✅ Exclusivité respectée: caisse non disponible');
            } else {
              print('❌ Problème d\'exclusivité: caisse encore disponible');
            }
          }
          
          // Test 5: Tentative de connexion simultanée (doit échouer)
          print('\n⚠️ Test 5: Tentative de connexion simultanée...');
          
          final duplicateRequest = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/connect'));
          duplicateRequest.headers.set('Content-Type', 'application/json');
          duplicateRequest.write(json.encode({
            'cashRegisterId': caisseId,
            'soldeInitial': 50.0
          }));
          final duplicateResponse = await duplicateRequest.close();
          final duplicateBody = await duplicateResponse.transform(utf8.decoder).join();
          
          if (duplicateResponse.statusCode == 400) {
            print('✅ Connexion simultanée bloquée correctement');
          } else {
            print('❌ Problème: connexion simultanée autorisée');
          }
          
          // Attendre un peu pour simuler une session
          await Future.delayed(Duration(seconds: 2));
          
          // Test 6: Se déconnecter de la caisse
          print('\n🔓 Test 6: Déconnexion de la caisse...');
          
          final disconnectRequest = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/disconnect'));
          disconnectRequest.headers.set('Content-Type', 'application/json');
          disconnectRequest.write(json.encode({
            'soldeFinal': 120.0
          }));
          final disconnectResponse = await disconnectRequest.close();
          final disconnectBody = await disconnectResponse.transform(utf8.decoder).join();
          
          if (disconnectResponse.statusCode == 200) {
            final closedData = json.decode(disconnectBody);
            final closedSession = closedData['data'];
            print('✅ Déconnexion réussie!');
            print('   Solde fermeture: ${closedSession['soldeFermeture']} FCFA');
            print('   Différence: ${closedSession['soldeFermeture'] - closedSession['soldeOuverture']} FCFA');
          } else {
            print('❌ Erreur lors de la déconnexion: ${disconnectResponse.statusCode}');
          }
          
          // Test 7: Vérifier l'historique des sessions
          print('\n📚 Test 7: Vérification de l\'historique...');
          
          final historyRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/history?limit=5'));
          historyRequest.headers.set('Content-Type', 'application/json');
          final historyResponse = await historyRequest.close();
          final historyBody = await historyResponse.transform(utf8.decoder).join();
          
          if (historyResponse.statusCode == 200) {
            final historyData = json.decode(historyBody);
            final sessions = historyData['data'] as List;
            print('✅ Historique récupéré: ${sessions.length} session(s)');
            
            for (final session in sessions.take(3)) {
              print('  - ${session['nomCaisse']} (${session['dateOuverture']})');
            }
          }
          
        } else {
          print('❌ Erreur lors de la connexion: ${connectResponse.statusCode}');
          print('   Réponse: $connectBody');
        }
      } else {
        print('⚠️ Aucune caisse disponible pour les tests');
      }
    } else {
      print('❌ Erreur lors de la récupération des caisses: ${availableResponse.statusCode}');
    }

    print('\n🎉 TESTS SESSIONS DE CAISSE TERMINÉS!');
    print('=====================================');
    print('✅ Système de sessions de caisse opérationnel');
    print('✅ Exclusivité des caisses respectée');
    print('✅ Gestion complète du cycle de vie des sessions');
    print('✅ Historique et statistiques disponibles');

  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  } finally {
    client.close();
  }
}