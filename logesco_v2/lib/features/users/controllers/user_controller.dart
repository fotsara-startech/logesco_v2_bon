import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/role_model.dart' as role_model;
import '../services/user_service.dart';
import '../../../core/widgets/permission_widget.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';

/// Contrôleur pour la gestion des utilisateurs
class UserController extends GetxController with PermissionMixin {
  // Services
  late final UserService _userService;

  // État des données
  final RxList<User> users = <User>[].obs;
  final RxList<role_model.UserRole> availableRoles = <role_model.UserRole>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Utilisateur sélectionné pour modification
  final Rx<User?> selectedUser = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    _userService = Get.find<UserService>();
    loadUsers();
    loadRoles();
  }

  /// Charger tous les utilisateurs
  Future<void> loadUsers() async {
    try {
      // Vérifier les permissions
      if (!hasPermission('users.view')) {
        SnackbarHelper.info('users_vous_n_avez_pas_permissions_voir'.tr, title: 'suppliers_access_denied'.tr);
        return;
      }

      print('👥 [UserController] Début loadUsers()');

      isLoading.value = true;

      final userList = await _userService.getAllUsers();

      print('✅ [UserController] Reçu ${userList.length} utilisateurs');
      users.assignAll(userList);
      print('✅ [UserController] Utilisateurs assignés avec succès');
    } catch (e) {
      print('❌ [UserController] Erreur dans loadUsers: $e');
      print('❌ [UserController] Type d\'erreur: ${e.runtimeType}');
      print('❌ [UserController] Stack trace: ${StackTrace.current}');

      SnackbarHelper.error('users_erreur_lors_chargement_liste_users'.trParams({'e': '${e}'}));
    } finally {
      isLoading.value = false;
      print('🏁 [UserController] Fin loadUsers()');
    }
  }

  /// Charger tous les rôles disponibles
  Future<void> loadRoles() async {
    try {
      print('🔑 [UserController] Début loadRoles()');
      final roleList = await _userService.getAllRoles();
      print('🔑 [UserController] Rôles récupérés: ${roleList.length}');

      if (roleList.isEmpty) {
        print('⚠️ [UserController] Aucun rôle trouvé en base de données');
        SnackbarHelper.warning('users_aucun_role_trouve_veuillez_creer_roles'.tr);
      } else {
        roleList.forEach((role) => print('   - ${role.displayName} (${role.nom})'));
      }

      availableRoles.assignAll(roleList);
      print('✅ [UserController] Rôles assignés avec succès');
    } catch (e) {
      print('❌ [UserController] Erreur loadRoles: $e');
      SnackbarHelper.error('users_impossible_charger_roles'.trParams({'e': '${e}'}));
      availableRoles.clear();
    }
  }

  /// Utilisateurs filtrés selon la recherche
  List<User> get filteredUsers {
    if (searchQuery.value.isEmpty) {
      return users;
    }
    return users.where((user) {
      return user.nomUtilisateur.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          (user.email?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false) ||
          user.role.displayName.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  /// Créer un nouvel utilisateur
  Future<bool> createUser(User user, {String? motDePasse}) async {
    try {
      // Vérifier les permissions
      requirePermission('users.create');

      isLoading.value = true;

      final newUser = await _userService.createUser(user, motDePasse ?? 'password123');

      users.add(newUser);
      // Stocker le dernier utilisateur créé pour récupérer son ID
      selectedUser.value = newUser;

      SnackbarHelper.success('users_created_success'.tr);
      return true;
    } catch (e) {
      SnackbarHelper.error('users_impossible_creer_utilisateur'.trParams({'e': '${e}'}));
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mettre à jour un utilisateur
  Future<bool> updateUser(User user, {String? motDePasse}) async {
    try {
      // Vérifier les permissions
      requirePermission('users.edit');

      isLoading.value = true;
      final updatedUser = await _userService.updateUser(user.id!, user, motDePasse: motDePasse);

      final index = users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        users[index] = updatedUser;
      }

      SnackbarHelper.success('users_utilisateur_mis_jour_avec_succes'.tr);
      return true;
    } catch (e) {
      SnackbarHelper.error('users_impossible_mettre_jour_utilisateur'.trParams({'e': '${e}'}));
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprimer un utilisateur
  Future<bool> deleteUser(int userId) async {
    try {
      // Vérifier les permissions
      requirePermission('users.delete');

      await _userService.deleteUser(userId);
      users.removeWhere((user) => user.id == userId);

      SnackbarHelper.success('users_deleted_success'.tr);
      return true;
    } catch (e) {
      SnackbarHelper.error('users_impossible_supprimer_utilisateur'.trParams({'e': '${e}'}));
      return false;
    }
  }

  /// Activer/Désactiver un utilisateur
  Future<void> toggleUserStatus(User user) async {
    try {
      final updatedUser = await _userService.toggleUserStatus(user.id!, !user.isActive);

      final index = users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        users[index] = updatedUser;
      }

      SnackbarHelper.success('users_statut_utilisateur_modifie_avec_succes'.tr);
    } catch (e) {
      SnackbarHelper.error('users_impossible_modifier_statut'.trParams({'e': '${e}'}));
    }
  }

  /// Changer le mot de passe d'un utilisateur
  Future<bool> changePassword(int userId, String newPassword) async {
    try {
      await _userService.changePassword(userId, newPassword);

      SnackbarHelper.success('users_password_changed_success'.tr);
      return true;
    } catch (e) {
      SnackbarHelper.error('users_impossible_changer_mot_passe'.trParams({'e': '${e}'}));
      return false;
    }
  }

  /// Récupérer les boutiques assignées à un utilisateur
  Future<List<Map<String, dynamic>>> getUserBoutiques(int userId) async {
    return _userService.getUserBoutiques(userId);
  }

  /// Mettre à jour les boutiques assignées à un utilisateur
  Future<bool> updateUserBoutiques(int userId, List<int> boutiqueIds) async {
    try {
      final success = await _userService.updateUserBoutiques(userId, boutiqueIds);
      if (success) SnackbarHelper.success('users_boutiques_assignees_mises_jour'.tr);
      return success;
    } catch (e) {
      SnackbarHelper.error('users_impossible_mettre_jour_boutiques'.trParams({'e': '${e}'}));
      return false;
    }
  }

  /// Sélectionner un utilisateur pour modification
  void selectUser(User? user) {
    selectedUser.value = user;
  }

  /// Mettre à jour la requête de recherche
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Confirmer la suppression d'un utilisateur
  void confirmDeleteUser(User user) {
    Get.dialog(
      AlertDialog(
        title: Text('users_delete_confirm_title'.tr),
        content: Text('users_etes_vous_sur_vouloir_supprimer_utilisateur'.trParams({'nomUtilisateur': '${user.nomUtilisateur}'})),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('suppliers_form_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              deleteUser(user.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('suppliers_delete'.tr),
          ),
        ],
      ),
    );
  }
}
