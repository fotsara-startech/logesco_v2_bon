import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/role_model.dart' as role_model;
import '../services/user_service.dart';
import '../../../core/widgets/permission_widget.dart';

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
        Get.snackbar(
          'Accès refusé',
          'Vous n\'avez pas les permissions pour voir les utilisateurs',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return;
      }

      print('🚀 [UserController] Début loadUsers()');

      isLoading.value = true;

      final userList = await _userService.getAllUsers();

      print('✅ [UserController] Reçu ${userList.length} utilisateurs');
      users.assignAll(userList);
      print('✅ [UserController] Utilisateurs assignés avec succès');
    } catch (e) {
      print('❌ [UserController] Erreur dans loadUsers: $e');
      print('❌ [UserController] Type d\'erreur: ${e.runtimeType}');
      print('❌ [UserController] Stack trace: ${StackTrace.current}');

      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement de la liste des users: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      print('🏁 [UserController] Fin loadUsers()');
    }
  }

  /// Charger tous les rôles disponibles
  Future<void> loadRoles() async {
    try {
      print('🔐 [UserController] Début loadRoles()');
      final roleList = await _userService.getAllRoles();
      print('🔐 [UserController] Rôles récupérés: ${roleList.length}');

      if (roleList.isEmpty) {
        print('⚠️ [UserController] Aucun rôle trouvé en base de données');
        Get.snackbar(
          'Attention',
          'Aucun rôle trouvé. Veuillez créer des rôles via l\'interface de gestion des rôles.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      } else {
        roleList.forEach((role) => print('   - ${role.displayName} (${role.nom})'));
      }

      availableRoles.assignAll(roleList);
      print('✅ [UserController] Rôles assignés avec succès');
    } catch (e) {
      print('❌ [UserController] Erreur loadRoles: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les rôles: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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
          user.email.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          user.role.displayName.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  /// Créer un nouvel utilisateur
  Future<bool> createUser(User user, {String? motDePasse}) async {
    try {
      // Vérifier les permissions
      requirePermission('users.create');

      print('👤 [UserController] Début createUser pour: ${user.nomUtilisateur}');
      isLoading.value = true;

      final newUser = await _userService.createUser(user, motDePasse ?? 'password123');

      print('✅ [UserController] Utilisateur créé: ${newUser.nomUtilisateur}');
      users.add(newUser);

      Get.snackbar(
        'Succès',
        'Utilisateur créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      print('✅ [UserController] createUser terminé avec succès');
      return true;
    } catch (e) {
      print('❌ [UserController] Erreur createUser: $e');
      print('❌ [UserController] Type d\'erreur: ${e.runtimeType}');

      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'utilisateur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
      print('🏁 [UserController] createUser finally block');
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

      Get.snackbar(
        'Succès',
        'Utilisateur mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'utilisateur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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

      Get.snackbar(
        'Succès',
        'Utilisateur supprimé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer l\'utilisateur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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

      Get.snackbar(
        'Succès',
        'Statut de l\'utilisateur modifié avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Changer le mot de passe d'un utilisateur
  Future<bool> changePassword(int userId, String newPassword) async {
    try {
      await _userService.changePassword(userId, newPassword);

      Get.snackbar(
        'Succès',
        'Mot de passe modifié avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de changer le mot de passe: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur "${user.nomUtilisateur}" ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
