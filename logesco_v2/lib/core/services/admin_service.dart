import 'package:get/get.dart';
import '../api/api_client.dart';

/// Service pour s'assurer qu'un utilisateur admin existe toujours
class AdminService extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Vérifie et crée l'utilisateur admin si nécessaire
  Future<void> ensureAdminExists() async {
    try {
      print('🔍 [AdminService] Vérification de l\'existence de l\'utilisateur admin...');

      // 1. Vérifier si des rôles existent
      final rolesResponse = await _apiClient.get<Map<String, dynamic>>('/roles');

      if (rolesResponse.isSuccess && rolesResponse.data != null) {
        final List<dynamic> roles = rolesResponse.data!['data'] ?? [];

        // 2. Vérifier si le rôle admin existe
        final adminRole = roles.firstWhereOrNull((role) => role['nom'] == 'admin');

        if (adminRole == null) {
          print('📝 [AdminService] Création du rôle admin...');
          await _createAdminRole();
        } else {
          print('✅ [AdminService] Rôle admin existe déjà');
        }
      }

      // 3. Vérifier si des utilisateurs existent
      final usersResponse = await _apiClient.get<Map<String, dynamic>>('/users');

      if (usersResponse.isSuccess && usersResponse.data != null) {
        final List<dynamic> users = usersResponse.data!['data'] ?? [];

        // 4. Vérifier si l'utilisateur admin existe
        final adminUser = users.firstWhereOrNull((user) => user['nomUtilisateur'] == 'admin');

        if (adminUser == null) {
          print('👤 [AdminService] Création de l\'utilisateur admin...');
          await _createAdminUser();
        } else {
          print('✅ [AdminService] Utilisateur admin existe déjà');
        }
      }

      print('🎉 [AdminService] Vérification admin terminée avec succès');
    } catch (e) {
      print('⚠️ [AdminService] Erreur lors de la vérification admin: $e');
      // Ne pas faire échouer l'application si la vérification admin échoue
      // L'utilisateur pourra créer manuellement les rôles et utilisateurs
    }
  }

  /// Crée le rôle admin
  Future<void> _createAdminRole() async {
    try {
      final roleData = {
        'nom': 'admin',
        'displayName': 'Administrateur',
        'isAdmin': true,
        'privileges': {
          'users': ['CREATE', 'READ', 'UPDATE', 'DELETE'],
          'products': ['CREATE', 'READ', 'UPDATE', 'DELETE'],
          'sales': ['CREATE', 'READ', 'UPDATE', 'DELETE'],
          'inventory': ['CREATE', 'READ', 'UPDATE', 'DELETE', 'ADJUST'],
          'reports': ['READ', 'EXPORT'],
          'company_settings': ['UPDATE'],
          'cash_registers': ['CREATE', 'READ', 'UPDATE', 'DELETE'],
          'dashboard': ['STATS'],
          'stock_inventory': ['COUNT'],
          'financial_movements': ['CREATE', 'READ', 'UPDATE', 'DELETE']
        }
      };

      final response = await _apiClient.post<Map<String, dynamic>>('/roles', roleData);

      if (response.isSuccess) {
        print('✅ [AdminService] Rôle admin créé avec succès');
      } else {
        throw Exception('Erreur lors de la création du rôle admin: ${response.message}');
      }
    } catch (e) {
      print('❌ [AdminService] Erreur création rôle admin: $e');
      rethrow;
    }
  }

  /// Crée l'utilisateur admin
  Future<void> _createAdminUser() async {
    try {
      // D'abord, récupérer l'ID du rôle admin
      final rolesResponse = await _apiClient.get<Map<String, dynamic>>('/roles');

      if (!rolesResponse.isSuccess || rolesResponse.data == null) {
        throw Exception('Impossible de récupérer les rôles');
      }

      final List<dynamic> roles = rolesResponse.data!['data'] ?? [];
      final adminRole = roles.firstWhereOrNull((role) => role['nom'] == 'admin');

      if (adminRole == null) {
        throw Exception('Rôle admin non trouvé');
      }

      final userData = {
        'nomUtilisateur': 'admin',
        'email': 'admin@logesco.com',
        'motDePasse': 'admin123',
        'role': {
          'id': adminRole['id'],
          'nom': adminRole['nom'],
        },
        'isActive': true,
      };

      final response = await _apiClient.post<Map<String, dynamic>>('/users', userData);

      if (response.isSuccess) {
        print('✅ [AdminService] Utilisateur admin créé avec succès');
        print('🔑 [AdminService] Identifiants: admin / admin123');
      } else {
        throw Exception('Erreur lors de la création de l\'utilisateur admin: ${response.message}');
      }
    } catch (e) {
      print('❌ [AdminService] Erreur création utilisateur admin: $e');
      rethrow;
    }
  }

  /// Vérifie si l'application a au moins un utilisateur actif
  Future<bool> hasActiveUsers() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/users');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> users = response.data!['data'] ?? [];
        return users.any((user) => user['isActive'] == true);
      }

      return false;
    } catch (e) {
      print('❌ [AdminService] Erreur vérification utilisateurs actifs: $e');
      return false;
    }
  }

  /// Affiche les informations de connexion admin
  void showAdminInfo() {
    print('\n📋 [AdminService] Informations de connexion admin:');
    print('   - Nom d\'utilisateur: admin');
    print('   - Mot de passe: admin123');
    print('   - Email: admin@logesco.com');
    print('   - Privilèges: Administrateur complet\n');
  }
}
