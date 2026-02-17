import 'dart:io';
import 'dart:convert';

/// Test détaillé pour diagnostiquer le problème des dettes clients dans Flutter
void main() async {
  print('🔍 DIAGNOSTIC DÉTAILLÉ - Dettes clients Flutter');
  print('=' * 60);

  await testAPIDirectly();
  await testWithAuth();
  await simulateFlutterCall();
}

/// Test direct de l'API sans authentification
Future<void> testAPIDirectly() async {
  print('\n1️⃣ Test direct de l\'API (sans auth)');
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
    
    print('Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      final comptes = data['data'] as List;
      
      double totalDettes = 0.0;
      int clientsDebiteurs = 0;
      
      print('✅ ${comptes.length} comptes récupérés');
      
      for (final compte in comptes) {
        final solde = (compte['soldeActuel'] as num).toDouble();
        final nom = compte['client']['nomComplet'] ?? 'Inconnu';
        
        if (solde > 0) {
          totalDettes += solde;
          clientsDebiteurs++;
          print('  💰 $nom: ${solde.toStringAsFixed(2)} FCFA (DETTE)');
        }
      }
      
      print('📊 RÉSULTAT: ${totalDettes.toStringAsFixed(0)} FCFA, $clientsDebiteurs débiteurs');
      
    } else {
      print('❌ Erreur: ${response.statusCode}');
      print('Body: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Exception: $e');
  }
}

/// Test avec authentification (token factice)
Future<void> testWithAuth() async {
  print('\n2️⃣ Test avec authentification');
  print('-' * 40);

  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://localhost:8080/api/v1/accounts/customers?limit=100')
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    request.headers.set('Authorization', 'Bearer fake-token-for-test');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status avec auth: ${response.statusCode}');
    
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
      
      print('✅ Avec auth: ${totalDettes.toStringAsFixed(0)} FCFA, $clientsDebiteurs débiteurs');
      
    } else if (response.statusCode == 401) {
      print('⚠️  Auth requise (401) - mais l\'endpoint existe');
    } else {
      print('❌ Erreur avec auth: ${response.statusCode}');
      print('Body: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Exception avec auth: $e');
  }
}

/// Simulation de l'appel Flutter avec tous les headers
Future<void> simulateFlutterCall() async {
  print('\n3️⃣ Simulation appel Flutter complet');
  print('-' * 40);

  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://localhost:8080/api/v1/accounts/customers?page=1&limit=100')
    );
    
    // Headers comme Flutter les envoie
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    request.headers.set('User-Agent', 'LOGESCO-Mobile/1.0.0');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status Flutter simulation: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      
      // Vérifier la structure de la réponse
      print('✅ Structure de réponse:');
      print('  - success: ${data['success']}');
      print('  - message: ${data['message']}');
      print('  - data type: ${data['data'].runtimeType}');
      print('  - data length: ${(data['data'] as List).length}');
      
      final comptes = data['data'] as List;
      
      // Simulation exacte de la logique Flutter
      double totalOutstandingDebt = 0.0;
      int customersWithDebt = 0;
      
      print('\n📋 Analyse détaillée des comptes:');
      for (int i = 0; i < comptes.length; i++) {
        final compteJson = comptes[i];
        final soldeActuel = (compteJson['soldeActuel'] as num).toDouble();
        final clientData = compteJson['client'] as Map<String, dynamic>;
        final nom = clientData['nom'] ?? 'Inconnu';
        final prenom = clientData['prenom'];
        final nomComplet = prenom != null ? '$nom $prenom' : nom;
        
        print('  ${i + 1}. $nomComplet: ${soldeActuel.toStringAsFixed(2)} FCFA');
        
        // Logique exacte du service Flutter
        if (soldeActuel > 0) {
          totalOutstandingDebt += soldeActuel;
          customersWithDebt++;
          print('     ⚠️  DETTE DÉTECTÉE: ${soldeActuel.toStringAsFixed(2)} FCFA');
        } else if (soldeActuel < 0) {
          print('     ✅ CRÉDIT: ${(-soldeActuel).toStringAsFixed(2)} FCFA');
        } else {
          print('     ➖ SOLDE NUL');
        }
      }
      
      final averageDebtPerCustomer = customersWithDebt > 0 ? totalOutstandingDebt / customersWithDebt : 0.0;
      
      print('\n🎯 RÉSULTAT FINAL (logique Flutter):');
      print('  - totalOutstandingDebt: ${totalOutstandingDebt.toStringAsFixed(2)} FCFA');
      print('  - customersWithDebt: $customersWithDebt');
      print('  - averageDebtPerCustomer: ${averageDebtPerCustomer.toStringAsFixed(2)} FCFA');
      
      // Vérifier si le problème vient de la conversion
      if (totalOutstandingDebt > 0) {
        print('\n✅ LES DETTES SONT BIEN CALCULÉES !');
        print('   Le problème doit être ailleurs dans Flutter...');
        
        // Suggestions de diagnostic
        print('\n🔍 PISTES À VÉRIFIER DANS FLUTTER:');
        print('   1. Le service AccountApiService est-il bien injecté ?');
        print('   2. Y a-t-il une exception silencieuse dans getComptesClients() ?');
        print('   3. Le token d\'authentification est-il présent ?');
        print('   4. La méthode _getCustomerDebtsData() est-elle bien appelée ?');
        print('   5. Y a-t-il une erreur dans le binding des dépendances ?');
        
      } else {
        print('\n⚠️  AUCUNE DETTE CALCULÉE - Problème dans les données');
      }
      
    } else {
      print('❌ Erreur simulation Flutter: ${response.statusCode}');
      print('Body: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Exception simulation Flutter: $e');
  }
}