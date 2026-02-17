// import 'dart:convert';
// import 'dart:io';

// void main() async {
//   print('🧪 Test de création de rôle depuis Flutter...');

//   try {
//     // Simuler les données comme Flutter les enverrait
//     final roleData = {
//       'nom': 'FLUTTER_TEST',
//       'displayName': 'Test Flutter',
//       'isAdmin': false,
//       'privileges': {
//         'dashboard': ['READ', 'STATS'],
//         'products': ['READ', 'CREATE', 'UPDATE'],
//         'sales': ['READ', 'CREATE']
//       }
//     };

//     print('📤 Données à envoyer:', jsonEncode(roleData));

//     // Simuler un appel HTTP comme le ferait Flutter
//     final client = HttpClient();
//     final request = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/roles'));
//     request.headers.set('Content-Type', 'application/json');

//     final requestBody = jsonEncode(roleData);
//     request.write(requestBody);

//     final response = await request.close();

//     if (response.statusCode == 201) {
//       final responseBody = await response.transform(utf8.decoder).join();
//       final data = jsonDecode(responseBody);

//       print('✅ Rôle créé avec succès !');
//       print('📋 Réponse:', jsonEncode(data));

//       // Vérifier les privilèges
//       final createdRole = data['data'];
//       print('🔍 Privilèges sauvegardés:', createdRole['privileges']);

//       // Parser les privilèges pour vérifier
//       final savedPrivileges = jsonDecode(createdRole['privileges']);
//       print('✅ Privilèges parsés:', jsonEncode(savedPrivileges));
//     } else {
//       final responseBody = await response.transform(utf8.decoder).join();
//       print('❌ Erreur HTTP ${response.statusCode}: $responseBody');
//     }

//     client.close();
//   } catch (e) {
//     print('❌ Erreur: $e');
//   }
// }
