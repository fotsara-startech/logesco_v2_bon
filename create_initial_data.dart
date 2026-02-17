import 'dart:convert';
import 'dart:io';

/// Script pour créer des données initiales
void main() async {
  print('🚀 Création des données initiales LOGESCO');
  print('=========================================');

  final client = HttpClient();

  try {
    // Créer les rôles de base
    print('\n🔐 Création des rôles...');

    final roles = [
      {
        'nom': 'admin',
        'displayName': 'Administrateur',
        'isAdmin': true,
        'privileges': json.encode({
          'canManageUsers': true,
          'canManageProducts': true,
          'canManageSales': true,
          'canManageInventory': true,
          'canManageReports': true,
          'canManageCompanySettings': true,
          'canManageCashRegisters': true,
        })
      },
      {
        'nom': 'manager',
        'displayName': 'Manager',
        'isAdmin': false,
        'privileges': json.encode({
          'canManageUsers': false,
          'canManageProducts': true,
          'canManageSales': true,
          'canManageInventory': true,
          'canManageReports': true,
          'canManageCompanySettings': false,
          'canManageCashRegisters': true,
        })
      },
      {
        'nom': 'cashier',
        'displayName': 'Caissier',
        'isAdmin': false,
        'privileges': json.encode({
          'canManageUsers': false,
          'canManageProducts': false,
          'canManageSales': true,
          'canManageInventory': false,
          'canManageReports': false,
          'canManageCompanySettings': false,
          'canManageCashRegisters': true,
        })
      },
      {
        'nom': 'stock_manager',
        'displayName': 'Gestionnaire de Stock',
        'isAdmin': false,
        'privileges': json.encode({
          'canManageUsers': false,
          'canManageProducts': true,
          'canManageSales': false,
          'canManageInventory': true,
          'canManageReports': true,
          'canManageCompanySettings': false,
          'canManageCashRegisters': false,
        })
      }
    ];

    for (final role in roles) {
      try {
        final request = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/roles'));
        request.headers.set('Content-Type', 'application/json');
        request.write(json.encode(role));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 201) {
          print('✅ Rôle "${role['displayName']}" créé');
        } else {
          print('⚠️  Rôle "${role['displayName']}" existe déjà ou erreur: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Erreur création rôle "${role['displayName']}": $e');
      }
    }

    // Créer des caisses de base
    print('\n💰 Création des caisses...');

    final caisses = [
      {'nom': 'Caisse Principale', 'description': 'Caisse principale du magasin', 'soldeInitial': 1000.0, 'isActive': true},
      {'nom': 'Caisse Secondaire', 'description': 'Caisse secondaire pour les périodes de forte affluence', 'soldeInitial': 500.0, 'isActive': false}
    ];

    for (final caisse in caisses) {
      try {
        final request = await client.postUrl(Uri.parse('http://localhost:3002/api/v1/cash-registers'));
        request.headers.set('Content-Type', 'application/json');
        request.write(json.encode(caisse));

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode == 201) {
          print('✅ Caisse "${caisse['nom']}" créée');
        } else {
          print('⚠️  Caisse "${caisse['nom']}" existe déjà ou erreur: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Erreur création caisse "${caisse['nom']}": $e');
      }
    }

    print('\n🎉 Données initiales créées avec succès!');
  } catch (e) {
    print('❌ Erreur générale: $e');
  } finally {
    client.close();
  }
}
