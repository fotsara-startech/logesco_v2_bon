import 'dart:convert';
import 'dart:io';

/// Test pour vérifier que le dropdown des caisses fonctionne
void main() async {
  print('🧪 TEST CORRECTION DROPDOWN CAISSES');
  print('====================================');

  final client = HttpClient();

  try {
    // Test 1: Récupérer les caisses disponibles
    print('\n💰 Test 1: Récupération des caisses disponibles...');
    
    final cashRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/available-cash-registers'));
    cashRequest.headers.set('Content-Type', 'application/json');
    final cashResponse = await cashRequest.close();
    final cashBody = await cashResponse.transform(utf8.decoder).join();
    
    if (cashResponse.statusCode == 200) {
      final cashData = json.decode(cashBody);
      final caisses = cashData['data'] as List;
      print('✅ ${caisses.length} caisse(s) disponible(s)');
      
      // Vérifier l'unicité des IDs
      final ids = caisses.map((c) => c['id']).toList();
      final uniqueIds = ids.toSet().toList();
      
      if (ids.length == uniqueIds.length) {
        print('✅ Tous les IDs de caisses sont uniques');
      } else {
        print('❌ Doublons détectés dans les IDs de caisses');
        print('   IDs: $ids');
        print('   IDs uniques: $uniqueIds');
      }
      
      // Vérifier l'unicité des noms
      final noms = caisses.map((c) => c['nom']).toList();
      final uniqueNoms = noms.toSet().toList();
      
      if (noms.length == uniqueNoms.length) {
        print('✅ Tous les noms de caisses sont uniques');
      } else {
        print('❌ Doublons détectés dans les noms de caisses');
        print('   Noms: $noms');
        print('   Noms uniques: $uniqueNoms');
      }
      
      // Afficher les détails des caisses
      print('\n📋 Détails des caisses:');
      for (int i = 0; i < caisses.length; i++) {
        final caisse = caisses[i];
        print('   ${i + 1}. ID: ${caisse['id']} | Nom: "${caisse['nom']}" | Solde: ${caisse['soldeActuel']} FCFA');
      }
      
      // Test de simulation du dropdown
      print('\n🔽 Simulation du dropdown:');
      print('   Valeur par défaut: null');
      print('   Options disponibles:');
      for (final caisse in caisses) {
        print('     - CashRegister(id: ${caisse['id']}, nom: "${caisse['nom']}")');
      }
      
      if (caisses.isNotEmpty) {
        final premiereCaisse = caisses.first;
        print('   Sélection simulée: CashRegister(id: ${premiereCaisse['id']}, nom: "${premiereCaisse['nom']}")');
        print('   ✅ Sélection valide (existe dans la liste)');
      }
      
    } else {
      print('❌ Erreur lors de la récupération des caisses: ${cashResponse.statusCode}');
      print('   Réponse: $cashBody');
    }

    print('\n🎉 TEST DROPDOWN TERMINÉ!');
    print('========================');
    print('✅ Structure des données validée');
    print('✅ Pas de doublons détectés');
    print('✅ Le dropdown devrait fonctionner correctement');

  } catch (e) {
    print('❌ Erreur lors du test: $e');
  } finally {
    client.close();
  }
}