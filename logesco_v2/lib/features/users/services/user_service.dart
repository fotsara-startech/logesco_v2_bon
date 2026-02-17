import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../models/user_model.dart';
import '../models/role_model.dart' as role_model;

/// Service pour la gestion des utilisateurs via API
class UserService extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();
  static const String _endpoint = '/users';

  /// Récupérer tous les utilisateurs
  Future<List<User>> getAllUsers() async {
    try {
      print('🔍 [UserService] Début getAllUsers()');
      print('🔑 [UserService] Token présent: ${_apiClient.hasAuthToken}');

      final response = await _apiClient.get<Map<String, dynamic>>(_endpoint);

      print('📡 [UserService] Response success: ${response.isSuccess}');
      print('📄 [UserService] Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final dynamic dataField = response.data!['data'];
        print('📋 [UserService] Data Field: $dataField');
        print('� [UserSvervice] Data Field Type: ${dataField.runtimeType}');

        if (dataField is List) {
          final List<dynamic> data = dataField;
          print('✅ [UserService] Data is List with ${data.length} items');

          final users = data.map((json) {
            print('👤 [UserService] Processing user: $json');
            return User.fromJson(json as Map<String, dynamic>);
          }).toList();

          print('✅ [UserService] Successfully parsed ${users.length} users');
          return users;
        } else {
          print('❌ [UserService] Data field is not a List: ${dataField.runtimeType}');
          throw Exception('Data field is not a List: ${dataField.runtimeType}');
        }
      } else {
        print('❌ [UserService] API Error: ${response.message}');
        throw Exception('Erreur lors de la récupération des utilisateurs: ${response.message}');
      }
    } catch (e) {
      print('❌ [UserService] Exception: $e');
      print('❌ [UserService] Exception Type: ${e.runtimeType}');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer un utilisateur par ID
  Future<User> getUserById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_endpoint/$id');

    if (response.isSuccess && response.data != null) {
      return User.fromJson(response.data!['data']);
    } else {
      if (response.message?.contains('404') == true || response.message?.contains('non trouvé') == true) {
        throw Exception('Utilisateur non trouvé');
      }
      throw Exception('Erreur lors de la récupération de l\'utilisateur: ${response.message}');
    }
  }

  /// Créer un nouvel utilisateur
  Future<User> createUser(User user, String motDePasse) async {
    final body = {
      'nomUtilisateur': user.nomUtilisateur,
      'email': user.email,
      'motDePasse': motDePasse,
      'role': {
        'id': user.role.id,
        'nom': user.role.nom,
      },
      'isActive': user.isActive,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(_endpoint, body);

    if (response.isSuccess && response.data != null) {
      return User.fromJson(response.data!['data']);
    } else {
      throw Exception(response.message ?? 'Erreur lors de la création de l\'utilisateur');
    }
  }

  /// Mettre à jour un utilisateur
  Future<User> updateUser(int id, User user, {String? motDePasse}) async {
    final body = {
      'nomUtilisateur': user.nomUtilisateur,
      'email': user.email,
      'role': {
        'id': user.role.id,
        'nom': user.role.nom,
      },
      'isActive': user.isActive,
    };

    if (motDePasse != null && motDePasse.isNotEmpty) {
      body['motDePasse'] = motDePasse;
    }

    final response = await _apiClient.put<Map<String, dynamic>>('$_endpoint/$id', body);

    if (response.isSuccess && response.data != null) {
      return User.fromJson(response.data!['data']);
    } else {
      throw Exception(response.message ?? 'Erreur lors de la mise à jour de l\'utilisateur');
    }
  }

  /// Supprimer un utilisateur
  Future<void> deleteUser(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>('$_endpoint/$id');

    if (!response.isSuccess) {
      if (response.message?.contains('404') == true || response.message?.contains('non trouvé') == true) {
        throw Exception('Utilisateur non trouvé');
      } else {
        throw Exception(response.message ?? 'Erreur lors de la suppression de l\'utilisateur');
      }
    }
  }

  /// Activer/Désactiver un utilisateur
  Future<User> toggleUserStatus(int id, bool isActive) async {
    final body = {'isActive': isActive};

    final response = await _apiClient.put<Map<String, dynamic>>('$_endpoint/$id/status', body);

    if (response.isSuccess && response.data != null) {
      return User.fromJson(response.data!['data']);
    } else {
      throw Exception(response.message ?? 'Erreur lors de la modification du statut');
    }
  }

  /// Changer le mot de passe d'un utilisateur
  Future<void> changePassword(int id, String newPassword) async {
    final body = {'motDePasse': newPassword};

    final response = await _apiClient.put<Map<String, dynamic>>('$_endpoint/$id/password', body);

    if (!response.isSuccess) {
      throw Exception(response.message ?? 'Erreur lors du changement de mot de passe');
    }
  }

  /// Récupérer tous les rôles disponibles
  Future<List<role_model.UserRole>> getAllRoles() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/roles');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> roles = response.data!['data'] ?? [];

        // Retourner les rôles de la base de données (peut être vide)
        return roles.map((json) => role_model.UserRole.fromJson(json)).toList();
      } else {
        // En cas d'erreur API, retourner liste vide
        return [];
      }
    } catch (e) {
      // En cas d'erreur de connexion, retourner liste vide
      print('❌ [UserService] Erreur getAllRoles: $e');
      return [];
    }
  }

  /// Rechercher des utilisateurs
  Future<List<User>> searchUsers(String query) async {
    try {
      final users = await getAllUsers();

      if (query.isEmpty) {
        return users;
      }

      final lowerQuery = query.toLowerCase();
      return users.where((user) {
        return user.nomUtilisateur.toLowerCase().contains(lowerQuery) || user.email.toLowerCase().contains(lowerQuery) || user.role.displayName.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir des statistiques sur les utilisateurs
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final users = await getAllUsers();

      final activeUsers = users.where((u) => u.isActive).length;
      final inactiveUsers = users.where((u) => !u.isActive).length;
      final adminUsers = users.where((u) => u.role.isAdmin).length;

      final roleStats = <String, int>{};
      for (final user in users) {
        roleStats[user.role.displayName] = (roleStats[user.role.displayName] ?? 0) + 1;
      }

      return {
        'total': users.length,
        'active': activeUsers,
        'inactive': inactiveUsers,
        'admins': adminUsers,
        'roleStats': roleStats,
        'lastCreated': users.isNotEmpty ? users.map((u) => u.dateCreation).reduce((a, b) => a!.isAfter(b!) ? a : b) : null,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}
