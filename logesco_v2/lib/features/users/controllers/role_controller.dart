import 'package:get/get.dart';
import '../models/role_model.dart';
import '../services/role_service.dart';

/// Contrôleur pour la gestion des rôles utilisateur
class RoleController extends GetxController {
  final RoleService _roleService = Get.find<RoleService>();

  // Observables
  final RxList<UserRole> roles = <UserRole>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<UserRole?> selectedRole = Rx<UserRole?>(null);

  @override
  void onInit() {
    super.onInit();
    print('🏗️ RoleController initialisé');
    loadRoles();
  }

  /// Charge tous les rôles depuis l'API
  Future<void> loadRoles({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading.value = true;
      }
      error.value = '';

      print('🔍 Chargement des rôles...');
      final rolesList = await _roleService.getAllRoles();

      roles.value = rolesList;
      print('✅ ${rolesList.length} rôles chargés');
    } catch (e) {
      error.value = e.toString();
      print('❌ Erreur lors du chargement des rôles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Actualise la liste des rôles
  Future<void> refresh() async {
    await loadRoles(showLoading: false);
  }

  /// Sélectionne un rôle
  void selectRole(UserRole? role) {
    selectedRole.value = role;
  }

  /// Crée un nouveau rôle
  Future<bool> createRole(UserRole role) async {
    try {
      isLoading.value = true;
      error.value = '';

      print('➕ Création du rôle: ${role.nom}');
      final newRole = await _roleService.createRole(role);

      roles.add(newRole);
      print('✅ Rôle créé avec succès: ${newRole.nom}');

      return true;
    } catch (e) {
      error.value = e.toString();
      print('❌ Erreur lors de la création du rôle: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Met à jour un rôle existant
  Future<bool> updateRole(UserRole role) async {
    if (role.id == null) return false;

    try {
      isLoading.value = true;
      error.value = '';

      print('📝 Mise à jour du rôle: ${role.nom}');
      final updatedRole = await _roleService.updateRole(role.id!, role);

      final index = roles.indexWhere((r) => r.id == role.id);
      if (index != -1) {
        roles[index] = updatedRole;
      }

      print('✅ Rôle mis à jour avec succès: ${updatedRole.nom}');
      return true;
    } catch (e) {
      error.value = e.toString();
      print('❌ Erreur lors de la mise à jour du rôle: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprime un rôle
  Future<bool> deleteRole(UserRole role) async {
    if (role.id == null) return false;

    try {
      isLoading.value = true;
      error.value = '';

      print('🗑️ Suppression du rôle: ${role.nom}');
      await _roleService.deleteRole(role.id!);

      roles.removeWhere((r) => r.id == role.id);

      if (selectedRole.value?.id == role.id) {
        selectedRole.value = null;
      }

      print('✅ Rôle supprimé avec succès: ${role.nom}');
      return true;
    } catch (e) {
      error.value = e.toString();
      print('❌ Erreur lors de la suppression du rôle: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Vérifie si un nom de rôle est disponible
  Future<bool> isRoleNameAvailable(String nom, {int? excludeId}) async {
    return await _roleService.isRoleNameAvailable(nom, excludeId: excludeId);
  }

  /// Obtient un rôle par ID
  UserRole? getRoleById(int id) {
    return roles.firstWhereOrNull((role) => role.id == id);
  }

  /// Filtre les rôles par nom
  List<UserRole> searchRoles(String query) {
    if (query.isEmpty) return roles;

    final lowerQuery = query.toLowerCase();
    return roles.where((role) => role.nom.toLowerCase().contains(lowerQuery) || role.displayName.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Obtient les statistiques des rôles
  Map<String, dynamic> getRoleStats() {
    final totalRoles = roles.length;
    final adminRoles = roles.where((r) => r.isAdmin).length;
    final activeRoles = roles.length; // Tous les rôles sont considérés comme actifs

    return {
      'total': totalRoles,
      'admin': adminRoles,
      'standard': totalRoles - adminRoles,
      'active': activeRoles,
    };
  }
}
