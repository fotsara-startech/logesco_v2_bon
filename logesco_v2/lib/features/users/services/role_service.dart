import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../models/role_model.dart';

/// Service pour la gestion des rôles utilisateur via API
class RoleService extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();
  static const String _endpoint = '/roles';

  /// Récupérer tous les rôles
  Future<List<UserRole>> getAllRoles() async {
    try {
      print('🔍 [RoleService] Début getAllRoles()');

      final response = await _apiClient.get<Map<String, dynamic>>(_endpoint);

      print('📡 [RoleService] Response success: ${response.isSuccess}');
      print('📄 [RoleService] Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final dynamic dataField = response.data!['data'];
        print('📋 [RoleService] Data Field: $dataField');

        if (dataField is List) {
          final List<dynamic> data = dataField;
          print('✅ [RoleService] Data is List with ${data.length} items');

          final roles = data.map((json) {
            print('👤 [RoleService] Processing role: $json');
            return UserRole.fromJson(json as Map<String, dynamic>);
          }).toList();

          print('✅ [RoleService] Successfully parsed ${roles.length} roles');
          return roles;
        } else {
          print('❌ [RoleService] Data field is not a List: ${dataField.runtimeType}');
          throw Exception('Data field is not a List: ${dataField.runtimeType}');
        }
      } else {
        print('❌ [RoleService] API Error: ${response.message}');
        throw Exception('Erreur lors de la récupération des rôles: ${response.message}');
      }
    } catch (e) {
      print('❌ [RoleService] Exception: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer un rôle par ID
  Future<UserRole> getRoleById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_endpoint/$id');

    if (response.isSuccess && response.data != null) {
      return UserRole.fromJson(response.data!['data']);
    } else {
      if (response.message?.contains('404') == true || response.message?.contains('non trouvé') == true) {
        throw Exception('Rôle non trouvé');
      }
      throw Exception('Erreur lors de la récupération du rôle: ${response.message}');
    }
  }

  /// Créer un nouveau rôle
  Future<UserRole> createRole(UserRole role) async {
    final body = role.toJson();

    print('🔍 [RoleService] Creating role with data: $body');
    print('🔍 [RoleService] Endpoint: $_endpoint');

    final response = await _apiClient.post<Map<String, dynamic>>(_endpoint, body);

    if (response.isSuccess && response.data != null) {
      return UserRole.fromJson(response.data!['data']);
    } else {
      throw Exception(response.message ?? 'Erreur lors de la création du rôle');
    }
  }

  /// Mettre à jour un rôle
  Future<UserRole> updateRole(int id, UserRole role) async {
    final body = role.toJson();
    body.remove('id'); // Retirer l'ID du body

    final response = await _apiClient.put<Map<String, dynamic>>('$_endpoint/$id', body);

    if (response.isSuccess && response.data != null) {
      return UserRole.fromJson(response.data!['data']);
    } else {
      throw Exception(response.message ?? 'Erreur lors de la mise à jour du rôle');
    }
  }

  /// Supprimer un rôle
  Future<void> deleteRole(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>('$_endpoint/$id');

    if (!response.isSuccess) {
      if (response.message?.contains('404') == true || response.message?.contains('non trouvé') == true) {
        throw Exception('Rôle non trouvé');
      } else {
        throw Exception(response.message ?? 'Erreur lors de la suppression du rôle');
      }
    }
  }

  /// Vérifier si un nom de rôle est disponible
  Future<bool> isRoleNameAvailable(String nom, {int? excludeId}) async {
    try {
      final roles = await getAllRoles();
      return !roles.any((role) => role.nom.toLowerCase() == nom.toLowerCase() && (excludeId == null || role.id != excludeId));
    } catch (e) {
      // En cas d'erreur, on considère que le nom est disponible
      return true;
    }
  }
}
