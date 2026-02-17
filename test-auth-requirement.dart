import 'dart:io';
import 'dart:convert';

/// Test pour vérifier si l'authentification est requise pour l'endpoint accounts/customers
void main() async {
  print('🔐 Test des exigences d\'authentification');
  print('=' * 50);

  await testWithoutAuth();
  await testWithFakeAuth();
  await testWithValidAuth();
}

/// Test sans authentification
Future<void> testWithoutAuth() async {
  print('\n1️⃣ Test SANS authentification');
  print('-' * 30);

  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://localhost:8080/api/v1/accounts/customers?limit=5')
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status sans auth: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ Pas d\'auth requise - données récupérées');
      final data = json.decode(responseBody);
      final comptes = data['data'] as List;
      print('   ${comptes.length} comptes récupérés');
    } else if (response.statusCode == 401) {
      print('🔒 Auth requise (401)');
    } else {
      print('❌ Erreur: ${response.statusCode}');
      print('Body: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Exception: $e');
  }
}

/// Test avec fausse authentification
Future<void> testWithFakeAuth() async {
  print('\n2️⃣ Test avec FAUSSE authentification');
  print('-' * 30);

  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://localhost:8080/api/v1/accounts/customers?limit=5')
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    request.headers.set('Authorization', 'Bearer fake-token-12345');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status avec fausse auth: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ Fausse auth acceptée - données récupérées');
      final data = json.decode(responseBody);
      final comptes = data['data'] as List;
      print('   ${comptes.length} comptes récupérés');
    } else if (response.statusCode == 401) {
      print('🔒 Fausse auth rejetée (401)');
    } else {
      print('❌ Erreur: ${response.statusCode}');
      print('Body: $responseBody');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Exception: $e');
  }
}

/// Test avec authentification valide (si possible)
Future<void> testWithValidAuth() async {
  print('\n3️⃣ Test avec authentification VALIDE');
  print('-' * 30);

  try {
    // D'abord, essayer de se connecter pour obtenir un token valide
    final authClient = HttpClient();
    final authRequest = await authClient.postUrl(
      Uri.parse('http://localhost:8080/api/v1/auth/login')
    );
    
    authRequest.headers.set('Content-Type', 'application/json');
    
    final loginData = {
      'email': 'admin@logesco.com',
      'password': 'admin123'
    };
    
    authRequest.write(json.encode(loginData));
    
    final authResponse = await authRequest.close();
    final authResponseBody = await authResponse.transform(utf8.decoder).join();
    
    print('Login status: ${authResponse.statusCode}');
    
    if (authResponse.statusCode == 200) {
      final authData = json.decode(authResponseBody);
      final token = authData['data']['token'];
      
      print('✅ Login réussi, token obtenu');
      
      // Maintenant tester avec le vrai token
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://localhost:8080/api/v1/accounts/customers?limit=5')
      );
      
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Accept', 'application/json');
      request.headers.set('Authorization', 'Bearer \$token');
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('Status avec vraie auth: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Vraie auth fonctionne - données récupérées');
        final data = json.decode(responseBody);
        final comptes = data['data'] as List;
        print('   ${comptes.length} comptes récupérés');
      } else {
        print('❌ Erreur avec vraie auth: ${response.statusCode}');
        print('Body: $responseBody');
      }
      
      client.close();
      
    } else {
      print('❌ Login échoué: ${authResponse.statusCode}');
      print('Body: $authResponseBody');
    }
    
    authClient.close();
    
  } catch (e) {
    print('❌ Exception: $e');
  }
}