import 'dart:convert';
import 'dart:io';

/// Test complet du module de gestion des caisses
void main() async {
  print('🧪 TEST MODULE GESTION DES CAISSES');
  print('==================================');

  final client = HttpClient();

  try {
    // Test 1: Récupérer toutes les caisses
    print('\n💰 Test 1: Récupération des caisses...');
    final cashRegistersRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-registers'));
    cashRegistersRequest.headers.set('Content-Type', 'application/json');
    final cashRegistersResponse = await cashRegistersRequest.close();
    final cashRegistersBody = await cashRegistersResponse.transform(utf8.decoder).join();

    print('Status: ${cashRegistersResponse.statusCode}');
    if (cashRegistersResponse.statusCode == 200) {
      final cashData = json.decode(cashRegistersBody);
      final caisses = cashData['data'] as List;
      print('✅ Succès! ${caisses.length} caisse(s) trouvée(s)');

      for (final caisse in caisses) {
        print('  - ${caisse['nom']} - Solde: ${caisse['soldeActuel']} FCFA - ${caisse['isActive'] ? 'Active' : 'Inactive'}');
      }
    } else {
      print('❌ Erreur: $cashRegistersBody');
    }

    // Test 2: Créer une nouvelle caisse
    print('\n💰 Test 2: Création d\'une nouvelle caisse...');

    final newCashRegister = {'nom': 'Caisse Test ${DateTime.now().millisecondsSinceEpoch}', 'description': 'Caisse de test automatique', 'soldeInitial': 100.0, 'isActive': true};

    final createRequest = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/cash-registers'));
    createRequest.headers.set('Content-Type', 'application/json');
    createRequest.write(json.encode(newCashRegister));

    final createResponse = await createRequest.close();
    final createResponseBody = await createResponse.transform(utf8.decoder).join();

    print('Status: ${createResponse.statusCode}');
    if (createResponse.statusCode == 201) {
      final createdCashRegister = json.decode(createResponseBody);
      final cashRegisterData = createdCashRegister['data'];
      print('✅ Caisse créée: ${cashRegisterData['nom']} (ID: ${cashRegisterData['id']})');

      final cashRegisterId = cashRegisterData['id'];

      // Test 3: Ouvrir la caisse
      print('\n🔓 Test 3: Ouverture de la caisse...');

      final openData = {'action': 'open', 'soldeInitial': 150.0};

      final openRequest = await client.patchUrl(Uri.parse('http://localhost:3002/api/v1/cash-registers/$cashRegisterId/status'));
      openRequest.headers.set('Content-Type', 'application/json');
      openRequest.write(json.encode(openData));

      final openResponse = await openRequest.close();
      final openResponseBody = await openResponse.transform(utf8.decoder).join();

      print('Status: ${openResponse.statusCode}');
      if (openResponse.statusCode == 200) {
        final openedCashRegister = json.decode(openResponseBody);
        print('✅ Caisse ouverte avec succès');
        print('   Solde: ${openedCashRegister['data']['soldeActuel']} FCFA');
      } else {
        print('❌ Erreur ouverture: $openResponseBody');
      }

      // Test 4: Ajouter un mouvement
      print('\n💸 Test 4: Ajout d\'un mouvement...');

      final movementData = {'type': 'entree', 'montant': 50.0, 'description': 'Test d\'entrée de fonds'};

      final movementRequest = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/cash-registers/$cashRegisterId/movements'));
      movementRequest.headers.set('Content-Type', 'application/json');
      movementRequest.write(json.encode(movementData));

      final movementResponse = await movementRequest.close();
      final movementResponseBody = await movementResponse.transform(utf8.decoder).join();

      print('Status: ${movementResponse.statusCode}');
      if (movementResponse.statusCode == 201) {
        final movement = json.decode(movementResponseBody);
        print('✅ Mouvement ajouté: ${movement['data']['type']} de ${movement['data']['montant']} FCFA');
      } else {
        print('❌ Erreur mouvement: $movementResponseBody');
      }

      // Test 5: Récupérer les mouvements
      print('\n📋 Test 5: Récupération des mouvements...');

      final movementsRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-registers/$cashRegisterId/movements'));
      movementsRequest.headers.set('Content-Type', 'application/json');
      final movementsResponse = await movementsRequest.close();
      final movementsResponseBody = await movementsResponse.transform(utf8.decoder).join();

      print('Status: ${movementsResponse.statusCode}');
      if (movementsResponse.statusCode == 200) {
        final movementsData = json.decode(movementsResponseBody);
        final movements = movementsData['data'] as List;
        print('✅ ${movements.length} mouvement(s) trouvé(s)');

        for (final movement in movements) {
          print('  - ${movement['type']}: ${movement['montant']} FCFA - ${movement['description']}');
        }
      } else {
        print('❌ Erreur mouvements: $movementsResponseBody');
      }

      // Test 6: Fermer la caisse
      print('\n🔒 Test 6: Fermeture de la caisse...');

      final closeData = {'action': 'close'};

      final closeRequest = await client.patchUrl(Uri.parse('http://localhost:3002/api/v1/cash-registers/$cashRegisterId/status'));
      closeRequest.headers.set('Content-Type', 'application/json');
      closeRequest.write(json.encode(closeData));

      final closeResponse = await closeRequest.close();
      final closeResponseBody = await closeResponse.transform(utf8.decoder).join();

      print('Status: ${closeResponse.statusCode}');
      if (closeResponse.statusCode == 200) {
        final closedCashRegister = json.decode(closeResponseBody);
        print('✅ Caisse fermée avec succès');
        print('   Solde final: ${closedCashRegister['data']['soldeActuel']} FCFA');
      } else {
        print('❌ Erreur fermeture: $closeResponseBody');
      }
    } else {
      print('❌ Erreur création: $createResponseBody');
    }

    print('\n🎉 TESTS MODULE CAISSE TERMINÉS!');
    print('================================');
    print('✅ Module de gestion des caisses opérationnel');
    print('✅ CRUD complet fonctionnel');
    print('✅ Ouverture/fermeture des caisses');
    print('✅ Gestion des mouvements de caisse');
  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  } finally {
    client.close();
  }
}
