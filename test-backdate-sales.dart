import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test de la fonctionnalité d'antidatage des ventes
void main() async {
  print('🧪 Test de la fonctionnalité d\'antidatage des ventes');

  const baseUrl = 'http://localhost:8080/api/v1';

  // 1. Test de connexion avec un utilisateur admin
  print('\n1. Connexion en tant qu\'admin...');
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'nomUtilisateur': 'admin', 'motDePasse': 'admin123'}),
  );

  if (loginResponse.statusCode != 200) {
    print('❌ Échec de la connexion: ${loginResponse.body}');
    return;
  }

  final loginData = json.decode(loginResponse.body);
  final token = loginData['data']['token'];
  print('✅ Connexion réussie');

  // 2. Vérifier les privilèges de l'utilisateur
  print('\n2. Vérification des privilèges...');
  final userResponse = await http.get(
    Uri.parse('$baseUrl/auth/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (userResponse.statusCode == 200) {
    final userData = json.decode(userResponse.body);
    final user = userData['data'];
    print('✅ Utilisateur: ${user['nomUtilisateur']}');
    print('✅ Admin: ${user['isAdmin']}');

    if (user['role'] != null && user['role']['privileges'] != null) {
      final privileges = user['role']['privileges'];
      if (privileges['sales'] != null) {
        final salesPrivileges = List<String>.from(privileges['sales']);
        print('✅ Privilèges ventes: $salesPrivileges');

        if (salesPrivileges.contains('BACKDATE')) {
          print('✅ Privilège BACKDATE présent');
        } else {
          print('⚠️ Privilège BACKDATE manquant');
        }
      }
    }
  }

  // 3. Récupérer la liste des produits
  print('\n3. Récupération des produits...');
  final productsResponse = await http.get(
    Uri.parse('$baseUrl/products'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (productsResponse.statusCode != 200) {
    print('❌ Échec de récupération des produits: ${productsResponse.body}');
    return;
  }

  final productsData = json.decode(productsResponse.body);
  final products = productsData['data'] as List;

  if (products.isEmpty) {
    print('❌ Aucun produit disponible');
    return;
  }

  final firstProduct = products.first;
  print('✅ Produit trouvé: ${firstProduct['nom']} (ID: ${firstProduct['id']})');

  // 4. Test de création de vente avec date antérieure
  print('\n4. Test de création de vente antidatée...');

  // Date d'hier
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  final saleRequest = {
    'clientId': null,
    'modePaiement': 'comptant',
    'montantRemise': 0.0,
    'montantPaye': firstProduct['prixUnitaire'],
    'dateVente': yesterday.toIso8601String(),
    'details': [
      {
        'produitId': firstProduct['id'],
        'quantite': 1,
        'prixUnitaire': firstProduct['prixUnitaire'],
        'prixAffiche': firstProduct['prixUnitaire'],
        'remiseAppliquee': 0.0,
        'justificationRemise': null,
      }
    ]
  };

  print('📅 Date de vente: ${yesterday.day.toString().padLeft(2, '0')}/${yesterday.month.toString().padLeft(2, '0')}/${yesterday.year}');

  final saleResponse = await http.post(
    Uri.parse('$baseUrl/sales'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode(saleRequest),
  );

  print('📊 Statut de réponse: ${saleResponse.statusCode}');
  print('📊 Corps de réponse: ${saleResponse.body}');

  if (saleResponse.statusCode == 201) {
    final saleData = json.decode(saleResponse.body);
    final sale = saleData['data'];
    print('✅ Vente antidatée créée avec succès!');
    print('✅ Numéro de vente: ${sale['numeroVente']}');
    print('✅ Date de vente: ${sale['dateVente']}');
    print('✅ Montant: ${sale['montantTotal']} FCFA');
  } else {
    print('❌ Échec de création de vente antidatée');
    final errorData = json.decode(saleResponse.body);
    print('❌ Erreur: ${errorData['message']}');
  }

  // 5. Test avec un utilisateur sans privilège (si disponible)
  print('\n5. Test avec utilisateur sans privilège...');

  // Créer un utilisateur de test sans privilège BACKDATE
  final testUserRequest = {
    'nomUtilisateur': 'testuser',
    'email': 'test@example.com',
    'motDePasse': 'test123',
    'roleId': 2, // Supposons que le rôle 2 n'a pas le privilège BACKDATE
  };

  final createUserResponse = await http.post(
    Uri.parse('$baseUrl/users'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode(testUserRequest),
  );

  if (createUserResponse.statusCode == 201) {
    print('✅ Utilisateur de test créé');

    // Se connecter avec cet utilisateur
    final testLoginResponse = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'nomUtilisateur': 'testuser', 'motDePasse': 'test123'}),
    );

    if (testLoginResponse.statusCode == 200) {
      final testLoginData = json.decode(testLoginResponse.body);
      final testToken = testLoginData['data']['token'];

      // Essayer de créer une vente antidatée
      final testSaleResponse = await http.post(
        Uri.parse('$baseUrl/sales'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $testToken',
        },
        body: json.encode(saleRequest),
      );

      if (testSaleResponse.statusCode == 403) {
        print('✅ Accès refusé pour utilisateur sans privilège (attendu)');
      } else {
        print('⚠️ Utilisateur sans privilège a pu créer une vente antidatée');
      }
    }
  }

  print('\n🎯 Test terminé!');
}
