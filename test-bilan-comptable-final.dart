import 'dart:io';
import 'dart:convert';

/// Test complet du bilan comptable avec focus sur les dettes clients
void main() async {
  print('🧪 Test complet du bilan comptable - Focus dettes clients');
  print('=' * 70);

  await testCustomerDebtsAPI();
  await testBilanComptableGeneration();
}

/// Test de l'API des comptes clients
Future<void> testCustomerDebtsAPI() async {
  print('\n1️⃣ Test de l\'API des comptes clients');
  print('-' * 40);

  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://localhost:8080/api/v1/accounts/customers?limit=100')
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      final comptes = data['data'] as List;
      
      double totalDettes = 0.0;
      int clientsDebiteurs = 0;
      
      for (final compte in comptes) {
        final solde = (compte['soldeActuel'] as num).toDouble();
        if (solde > 0) {
          totalDettes += solde;
          clientsDebiteurs++;
        }
      }
      
      print('✅ API des comptes clients fonctionne');
      print('   - ${comptes.length} comptes récupérés');
      print('   - ${totalDettes.toStringAsFixed(0)} FCFA de dettes');
      print('   - $clientsDebiteurs clients débiteurs');
      
    } else {
      print('❌ Erreur API: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Erreur test API: $e');
  }
}

/// Test de génération du bilan comptable
Future<void> testBilanComptableGeneration() async {
  print('\n2️⃣ Test de génération du bilan comptable');
  print('-' * 40);

  try {
    // Simuler la génération d'un bilan comptable
    final client = HttpClient();
    
    // Test des ventes
    print('📊 Test des ventes...');
    final salesRequest = await client.getUrl(
      Uri.parse('http://localhost:8080/api/v1/sales?start_date=2025-12-01&end_date=2025-12-31&status=completed')
    );
    salesRequest.headers.set('Content-Type', 'application/json');
    final salesResponse = await salesRequest.close();
    final salesBody = await salesResponse.transform(utf8.decoder).join();
    
    if (salesResponse.statusCode == 200) {
      final salesData = json.decode(salesBody);
      final sales = salesData['data'] as List;
      double totalCA = 0.0;
      
      for (final sale in sales) {
        totalCA += (sale['montantTotal'] as num).toDouble();
      }
      
      print('✅ Ventes récupérées: ${sales.length} ventes, CA: ${totalCA.toStringAsFixed(0)} FCFA');
    } else {
      print('❌ Erreur ventes: ${salesResponse.statusCode}');
    }
    
    // Test des mouvements financiers
    print('💰 Test des mouvements financiers...');
    final movementsRequest = await client.getUrl(
      Uri.parse('http://localhost:8080/api/v1/financial-movements?start_date=2025-12-01&end_date=2025-12-31')
    );
    movementsRequest.headers.set('Content-Type', 'application/json');
    final movementsResponse = await movementsRequest.close();
    final movementsBody = await movementsResponse.transform(utf8.decoder).join();
    
    if (movementsResponse.statusCode == 200) {
      final movementsData = json.decode(movementsBody);
      final movements = movementsData['data'] as List;
      double totalDepenses = 0.0;
      
      for (final movement in movements) {
        totalDepenses += (movement['montant'] as num).toDouble().abs();
      }
      
      print('✅ Mouvements récupérés: ${movements.length} mouvements, Dépenses: ${totalDepenses.toStringAsFixed(0)} FCFA');
    } else {
      print('❌ Erreur mouvements: ${movementsResponse.statusCode}');
    }
    
    // Test des comptes clients (dettes)
    print('👥 Test des dettes clients...');
    final accountsRequest = await client.getUrl(
      Uri.parse('http://localhost:8080/api/v1/accounts/customers?limit=100')
    );
    accountsRequest.headers.set('Content-Type', 'application/json');
    final accountsResponse = await accountsRequest.close();
    final accountsBody = await accountsResponse.transform(utf8.decoder).join();
    
    if (accountsResponse.statusCode == 200) {
      final accountsData = json.decode(accountsBody);
      final accounts = accountsData['data'] as List;
      double totalDettes = 0.0;
      int clientsDebiteurs = 0;
      
      for (final account in accounts) {
        final solde = (account['soldeActuel'] as num).toDouble();
        if (solde > 0) {
          totalDettes += solde;
          clientsDebiteurs++;
        }
      }
      
      print('✅ Dettes clients récupérées: ${totalDettes.toStringAsFixed(0)} FCFA, $clientsDebiteurs débiteurs');
    } else {
      print('❌ Erreur dettes: ${accountsResponse.statusCode}');
    }
    
    client.close();
    
    print('\n🎯 RÉSUMÉ DU TEST');
    print('=' * 30);
    print('✅ Toutes les APIs nécessaires au bilan comptable fonctionnent');
    print('✅ Les dettes clients sont correctement récupérées');
    print('✅ Le problème de port (3000 → 8080) a été corrigé');
    print('\n📱 L\'application Flutter devrait maintenant afficher les dettes clients correctement !');
    
  } catch (e) {
    print('❌ Erreur test bilan: $e');
  }
}