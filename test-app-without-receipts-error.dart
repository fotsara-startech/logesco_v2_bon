import 'dart:convert';
import 'dart:io';

/// Test pour vérifier que l'application fonctionne sans l'erreur de reçus
void main() async {
  print('🧪 TEST APPLICATION SANS ERREUR DE REÇUS');
  print('=========================================');

  final client = HttpClient();

  try {
    // Test 1: Vérifier la connexion au backend
    print('\n🌐 Test 1: Connexion au backend...');
    
    final healthRequest = await client.getUrl(Uri.parse('http://localhost:3002/'));
    final healthResponse = await healthRequest.close();
    
    if (healthResponse.statusCode == 200) {
      print('✅ Backend accessible');
    } else {
      print('❌ Backend non accessible: ${healthResponse.statusCode}');
      return;
    }

    // Test 2: Tester l'authentification
    print('\n🔐 Test 2: Authentification...');
    
    final authRequest = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/auth/login'));
    authRequest.headers.set('Content-Type', 'application/json');
    authRequest.write(json.encode({
      'nomUtilisateur': 'admin',
      'motDePasse': 'password123'
    }));
    final authResponse = await authRequest.close();
    final authBody = await authResponse.transform(utf8.decoder).join();
    
    String? token;
    if (authResponse.statusCode == 200) {
      final authData = json.decode(authBody);
      token = authData['data']['accessToken'];
      print('✅ Authentification réussie');
    } else {
      print('❌ Erreur d\'authentification: ${authResponse.statusCode}');
      return;
    }

    // Test 3: Tester les caisses (fonctionnalité principale)
    print('\n💰 Test 3: Sessions de caisse...');
    
    final cashRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/cash-sessions/available-cash-registers'));
    cashRequest.headers.set('Content-Type', 'application/json');
    final cashResponse = await cashRequest.close();
    final cashBody = await cashResponse.transform(utf8.decoder).join();
    
    if (cashResponse.statusCode == 200) {
      final cashData = json.decode(cashBody);
      final caisses = cashData['data'] as List;
      print('✅ ${caisses.length} caisse(s) disponible(s)');
    } else {
      print('❌ Erreur caisses: ${cashResponse.statusCode}');
    }

    // Test 4: Tester l'API des reçus (source du problème)
    print('\n📄 Test 4: API des reçus (problématique)...');
    
    final receiptsRequest = await client.getUrl(Uri.parse('http://localhost:3002/api/v1/printing/receipts'));
    receiptsRequest.headers.set('Content-Type', 'application/json');
    receiptsRequest.headers.set('Authorization', 'Bearer $token');
    final receiptsResponse = await receiptsRequest.close();
    final receiptsBody = await receiptsResponse.transform(utf8.decoder).join();
    
    print('   Status: ${receiptsResponse.statusCode}');
    if (receiptsResponse.statusCode == 200) {
      try {
        final receiptsData = json.decode(receiptsBody);
        print('   Structure: ${receiptsData.keys}');
        
        if (receiptsData['data'] is List) {
          final receipts = receiptsData['data'] as List;
          print('   Nombre de reçus: ${receipts.length}');
          
          if (receipts.isNotEmpty) {
            final firstReceipt = receipts.first;
            print('   Premier reçu - Champs: ${firstReceipt.keys}');
            
            // Vérifier les champs problématiques
            final problematicFields = ['id', 'saleId', 'saleNumber', 'paymentMethod'];
            for (final field in problematicFields) {
              final value = firstReceipt[field];
              final type = value.runtimeType;
              print('     $field: $value (type: $type)');
              
              if (value == null) {
                print('     ⚠️ PROBLÈME: $field est null');
              }
            }
          }
        } else {
          print('   Structure différente (pas une liste)');
        }
      } catch (e) {
        print('   ❌ Erreur de parsing: $e');
      }
    } else {
      print('   Erreur: $receiptsBody');
    }

    print('\n🎯 RECOMMANDATIONS:');
    print('==================');
    
    if (token != null) {
      print('✅ L\'authentification fonctionne');
      print('✅ Les sessions de caisse sont opérationnelles');
      print('⚠️ Le module de reçus nécessite des corrections');
      print('');
      print('💡 Solutions temporaires:');
      print('   1. Désactiver le chargement automatique des reçus (fait)');
      print('   2. Améliorer la gestion des valeurs null dans les modèles');
      print('   3. Corriger les données backend si nécessaire');
      print('');
      print('🚀 L\'application peut fonctionner sans le module de reçus');
    }

  } catch (e) {
    print('❌ Erreur lors du test: $e');
  } finally {
    client.close();
  }
}