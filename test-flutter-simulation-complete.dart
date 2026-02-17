import 'dart:io';
import 'dart:convert';

/// Simulation complète du processus Flutter pour identifier le problème exact
void main() async {
  print('🔍 SIMULATION COMPLÈTE DU PROCESSUS FLUTTER');
  print('=' * 60);

  await simulateFlutterApiClient();
  await simulateAccountApiService();
  await simulateActivityReportService();
}

/// Simulation de l'ApiClient Flutter
Future<Map<String, dynamic>?> simulateFlutterApiClient() async {
  print('\n1️⃣ Simulation ApiClient Flutter');
  print('-' * 40);

  try {
    // Simulation exacte de ce que fait ApiClient.get()
    final client = HttpClient();
    
    // URL exacte comme dans EnvironmentConfig
    final url = Uri.parse('http://localhost:8080/api/v1/accounts/customers');
    final queryParams = {'page': '1', 'limit': '100'};
    final finalUrl = url.replace(queryParameters: queryParams);
    
    print('📡 URL finale: $finalUrl');
    
    final request = await client.getUrl(finalUrl);
    
    // Headers exactement comme ApiClient
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    // Pas de token d'auth car _authToken est null
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📡 Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      
      // Simulation de ApiResponse
      final apiResponse = {
        'isSuccess': true,
        'data': data,
        'message': data['message'],
        'errorCode': null,
      };
      
      print('✅ ApiClient simulation réussie');
      print('   - isSuccess: ${apiResponse['isSuccess']}');
      print('   - data type: ${apiResponse['data'].runtimeType}');
      print('   - comptes count: ${(apiResponse['data']['data'] as List).length}');
      
      return apiResponse;
      
    } else {
      print('❌ ApiClient simulation échouée: ${response.statusCode}');
      print('Body: $responseBody');
      return null;
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Exception ApiClient: $e');
    return null;
  }
}

/// Simulation de AccountApiService.getComptesClients()
Future<List<Map<String, dynamic>>> simulateAccountApiService() async {
  print('\n2️⃣ Simulation AccountApiService.getComptesClients()');
  print('-' * 40);

  try {
    // Appel API direct comme le fait AccountApiService
    final client = HttpClient();
    final url = Uri.parse('http://localhost:8080/api/v1/accounts/customers');
    final queryParams = {'page': '1', 'limit': '100'};
    final finalUrl = url.replace(queryParameters: queryParams);
    
    final request = await client.getUrl(finalUrl);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody) as Map<String, dynamic>;
      final comptesJson = data['data'] as List<dynamic>;
      
      print('✅ AccountApiService simulation réussie');
      print('   - ${comptesJson.length} comptes JSON récupérés');
      
      // Simulation de la conversion CompteClient.fromJson()
      final comptesClients = <Map<String, dynamic>>[];
      
      for (final compteJson in comptesJson) {
        final compte = compteJson as Map<String, dynamic>;
        
        // Simulation de CompteClient.fromJson() - parsing sécurisé
        final soldeActuel = _parseDouble(compte['soldeActuel']);
        final limiteCredit = _parseDouble(compte['limiteCredit']);
        final clientData = compte['client'] as Map<String, dynamic>;
        
        final compteClient = {
          'id': compte['id'],
          'clientId': compte['clientId'],
          'soldeActuel': soldeActuel,
          'limiteCredit': limiteCredit,
          'dateDerniereMaj': compte['dateDerniereMaj'],
          'client': {
            'id': clientData['id'],
            'nom': clientData['nom'],
            'prenom': clientData['prenom'],
            'nomComplet': clientData['nomComplet'] ?? 
                         (clientData['prenom'] != null ? 
                          '${clientData['nom']} ${clientData['prenom']}' : 
                          clientData['nom']),
          }
        };
        
        comptesClients.add(compteClient);
        
        print('   - ${compteClient['client']['nomComplet']}: ${compteClient['soldeActuel']} FCFA');
      }
      
      print('✅ Conversion CompteClient.fromJson() réussie');
      return comptesClients;
      
    } else {
      print('❌ AccountApiService simulation échouée: ${response.statusCode}');
      return [];
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Exception AccountApiService: $e');
    return [];
  }
}

/// Simulation de ActivityReportService._getCustomerDebtsData()
Future<void> simulateActivityReportService() async {
  print('\n3️⃣ Simulation ActivityReportService._getCustomerDebtsData()');
  print('-' * 40);

  try {
    // Récupérer les comptes comme le fait le service
    final comptesClients = await simulateAccountApiService();
    
    if (comptesClients.isEmpty) {
      print('❌ Aucun compte client récupéré');
      return;
    }
    
    print('📊 Analyse des dettes (logique exacte du service):');
    
    // Logique exacte de _getCustomerDebtsData()
    double totalOutstandingDebt = 0.0;
    int customersWithDebt = 0;
    final topDebtors = <Map<String, dynamic>>[];
    
    for (final compte in comptesClients) {
      final soldeActuel = compte['soldeActuel'] as double;
      final client = compte['client'] as Map<String, dynamic>;
      final nomComplet = client['nomComplet'] as String;
      
      print('   Analyse: $nomComplet = $soldeActuel FCFA');
      
      // Un solde positif = dette du client
      if (soldeActuel > 0) {
        totalOutstandingDebt += soldeActuel;
        customersWithDebt++;
        
        print('     ⚠️  DETTE: $soldeActuel FCFA');
        
        topDebtors.add({
          'customerName': nomComplet,
          'debtAmount': soldeActuel,
          'daysOverdue': 0, // Simplifié pour le test
        });
      } else if (soldeActuel < 0) {
        print('     ✅ CRÉDIT: ${-soldeActuel} FCFA');
      } else {
        print('     ➖ SOLDE NUL');
      }
    }
    
    final averageDebtPerCustomer = customersWithDebt > 0 ? totalOutstandingDebt / customersWithDebt : 0.0;
    
    // Création de CustomerDebtsData (simulation)
    final customerDebtsData = {
      'totalOutstandingDebt': totalOutstandingDebt,
      'customersWithDebt': customersWithDebt,
      'averageDebtPerCustomer': averageDebtPerCustomer,
      'topDebtors': topDebtors,
    };
    
    print('\n🎯 RÉSULTAT FINAL CustomerDebtsData:');
    print('   - totalOutstandingDebt: ${customerDebtsData['totalOutstandingDebt']} FCFA');
    print('   - customersWithDebt: ${customerDebtsData['customersWithDebt']}');
    print('   - averageDebtPerCustomer: ${customerDebtsData['averageDebtPerCustomer']} FCFA');
    print('   - topDebtors count: ${(customerDebtsData['topDebtors'] as List).length}');
    
    if (totalOutstandingDebt > 0) {
      print('\n✅ LA SIMULATION FONCTIONNE PARFAITEMENT !');
      print('   Les dettes sont correctement calculées: ${totalOutstandingDebt.toStringAsFixed(2)} FCFA');
      print('\n🔍 Le problème doit être dans:');
      print('   1. L\'injection de dépendances (Get.find<AccountApiService>())');
      print('   2. Une exception silencieuse dans Flutter');
      print('   3. Un problème de binding ou de timing');
      print('   4. L\'affichage dans l\'interface utilisateur');
    } else {
      print('\n❌ Aucune dette calculée - problème dans les données');
    }
    
  } catch (e) {
    print('❌ Exception ActivityReportService: $e');
  }
}

/// Helper pour parser les doubles de manière sécurisée (comme dans CompteClient.fromJson)
double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) {
    return value.isNaN || value.isInfinite ? defaultValue : value;
  }
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return defaultValue;
    }
    return parsed;
  }
  return defaultValue;
}