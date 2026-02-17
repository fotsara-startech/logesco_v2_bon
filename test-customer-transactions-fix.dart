import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 DIAGNOSTIC: Problème transactions client LETO GAZO (ID #29)');
  print('================================================================');
  
  final client = HttpClient();
  
  try {
    // Test 1: Vérifier si le client existe
    print('\n📋 Test 1: Vérification existence du client ID #29...');
    
    final clientRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/customers/29'));
    clientRequest.headers.set('Content-Type', 'application/json');
    final clientResponse = await clientRequest.close();
    final clientBody = await clientResponse.transform(utf8.decoder).join();
    
    print('Status client: ${clientResponse.statusCode}');
    if (clientResponse.statusCode == 200) {
      final clientData = json.decode(clientBody);
      print('✅ Client trouvé: ${clientData['data']['nom']} ${clientData['data']['prenom'] ?? ''}');
    } else {
      print('❌ Client non trouvé: $clientBody');
      return;
    }
    
    // Test 2: Vérifier les ventes avec ce client
    print('\n📋 Test 2: Vérification des ventes avec client ID #29...');
    
    final salesRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/sales?clientId=29'));
    salesRequest.headers.set('Content-Type', 'application/json');
    final salesResponse = await salesRequest.close();
    final salesBody = await salesResponse.transform(utf8.decoder).join();
    
    print('Status ventes: ${salesResponse.statusCode}');
    if (salesResponse.statusCode == 200) {
      final salesData = json.decode(salesBody);
      final ventes = salesData['data'] as List;
      print('✅ Ventes trouvées: ${ventes.length}');
      
      for (final vente in ventes) {
        print('  - Vente ID: ${vente['id']}, Montant: ${vente['montantTotal']}, Mode: ${vente['modePaiement']}, Client: ${vente['clientId']}');
      }
    } else {
      print('❌ Erreur ventes: $salesBody');
    }
    
    // Test 3: Vérifier le compte client
    print('\n📋 Test 3: Vérification du compte client ID #29...');
    
    final accountRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/accounts/customers/29/balance'));
    accountRequest.headers.set('Content-Type', 'application/json');
    final accountResponse = await accountRequest.close();
    final accountBody = await accountResponse.transform(utf8.decoder).join();
    
    print('Status compte: ${accountResponse.statusCode}');
    if (accountResponse.statusCode == 200) {
      final accountData = json.decode(accountBody);
      print('✅ Compte trouvé:');
      print('  - Solde actuel: ${accountData['data']['soldeActuel']} FCFA');
      print('  - Limite crédit: ${accountData['data']['limiteCredit']} FCFA');
      print('  - En dépassement: ${accountData['data']['estEnDepassement']}');
    } else {
      print('❌ Erreur compte: $accountBody');
    }
    
    // Test 4: Vérifier les transactions du compte
    print('\n📋 Test 4: Vérification des transactions du compte client ID #29...');
    
    final transactionsRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/accounts/customers/29/transactions'));
    transactionsRequest.headers.set('Content-Type', 'application/json');
    final transactionsResponse = await transactionsRequest.close();
    final transactionsBody = await transactionsResponse.transform(utf8.decoder).join();
    
    print('Status transactions: ${transactionsResponse.statusCode}');
    if (transactionsResponse.statusCode == 200) {
      final transactionsData = json.decode(transactionsBody);
      final transactions = transactionsData['data'] as List;
      print('✅ Transactions trouvées: ${transactions.length}');
      
      for (final transaction in transactions) {
        print('  - Transaction ID: ${transaction['id']}, Type: ${transaction['typeTransaction']}, Montant: ${transaction['montant']}, Date: ${transaction['dateTransaction']}');
      }
    } else {
      print('❌ Erreur transactions: $transactionsBody');
    }
    
    // Test 5: Vérifier la liste des comptes clients
    print('\n📋 Test 5: Vérification de la liste des comptes clients...');
    
    final accountsListRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/accounts/customers'));
    accountsListRequest.headers.set('Content-Type', 'application/json');
    final accountsListResponse = await accountsListRequest.close();
    final accountsListBody = await accountsListResponse.transform(utf8.decoder).join();
    
    print('Status liste comptes: ${accountsListResponse.statusCode}');
    if (accountsListResponse.statusCode == 200) {
      final accountsListData = json.decode(accountsListBody);
      final comptes = accountsListData['data'] as List;
      print('✅ Comptes clients trouvés: ${comptes.length}');
      
      // Chercher le compte du client ID #29
      final compteClient29 = comptes.where((compte) => compte['clientId'] == 29).toList();
      if (compteClient29.isNotEmpty) {
        print('✅ Compte client #29 trouvé dans la liste:');
        for (final compte in compteClient29) {
          print('  - Compte ID: ${compte['id']}, Client: ${compte['client']['nomComplet']}, Solde: ${compte['soldeActuel']}');
        }
      } else {
        print('❌ Compte client #29 NON trouvé dans la liste des comptes');
      }
    } else {
      print('❌ Erreur liste comptes: $accountsListBody');
    }
    
    // Test 6: Diagnostic des problèmes potentiels
    print('\n🔧 DIAGNOSTIC DES PROBLÈMES POTENTIELS:');
    print('─────────────────────────────────────────');
    
    print('1. SYNCHRONISATION COMPTE:');
    print('   - Le compte client est-il créé automatiquement lors de la vente ?');
    print('   - Les transactions sont-elles enregistrées dans TransactionCompte ?');
    
    print('\n2. CACHE FLUTTER:');
    print('   - L\'interface Flutter utilise-t-elle un cache ?');
    print('   - Le contrôleur GetX est-il mis à jour après la vente ?');
    
    print('\n3. FILTRAGE API:');
    print('   - Les paramètres de recherche filtrent-ils le client #29 ?');
    print('   - La pagination inclut-elle tous les comptes ?');
    
    print('\n4. TIMING:');
    print('   - Y a-t-il un délai entre la création de la vente et la mise à jour du compte ?');
    print('   - L\'interface est-elle rafraîchie après la vente ?');
    
    print('\n📋 ACTIONS RECOMMANDÉES:');
    print('─────────────────────────');
    print('✓ Vérifier si le compte client #29 apparaît dans la liste API');
    print('✓ Forcer un refresh du contrôleur Flutter après la vente');
    print('✓ Vérifier les logs de création automatique du compte');
    print('✓ Tester la recherche par nom "LETO GAZO" dans l\'interface');
    
  } catch (e) {
    print('❌ Erreur lors du diagnostic: $e');
  } finally {
    client.close();
  }
}