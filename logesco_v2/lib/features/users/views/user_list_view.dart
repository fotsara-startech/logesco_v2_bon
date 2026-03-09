import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import '../../../core/widgets/permission_widget.dart';
import 'user_form_view.dart';

/// Vue de la liste des utilisateurs
class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController controller = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('users_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Get.toNamed('/roles'),
            tooltip: 'users_manage_roles'.tr,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadUsers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(controller),

          // Liste des utilisateurs
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = controller.filteredUsers;

              if (users.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.loadUsers,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(context, user, controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final hasRoles = controller.availableRoles.isNotEmpty;

        if (!hasRoles) return const SizedBox.shrink();

        return PermissionWidget(
          module: 'users',
          privilege: 'CREATE',
          child: FloatingActionButton(
            onPressed: () => _navigateToUserForm(context, controller),
            tooltip: 'Ajouter un utilisateur',
            child: const Icon(Icons.add),
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar(UserController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'users_search_hint'.tr,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final UserController controller = Get.find<UserController>();

    return Obx(() {
      final hasRoles = controller.availableRoles.isNotEmpty;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasRoles ? Icons.people_outline : Icons.admin_panel_settings_outlined,
              size: 64,
              color: hasRoles ? Colors.grey.shade400 : Colors.orange.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasRoles ? 'users_no_users'.tr : 'users_no_roles_configured'.tr,
              style: TextStyle(
                fontSize: 18,
                color: hasRoles ? Colors.grey.shade600 : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (hasRoles) ...[
              Text(
                'users_no_users_hint'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ] else ...[
              Text(
                'users_must_create_roles'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      'users_roles_info'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed('/roles'),
                icon: const Icon(Icons.admin_panel_settings),
                label: Text('users_manage_roles'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'users_create_custom_roles'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildUserCard(BuildContext context, User user, UserController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            user.role.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: user.isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        title: Text(
          user.nomUtilisateur,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: user.isActive ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.role.isAdmin ? Colors.amber.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: user.role.isAdmin ? Colors.amber.shade800 : Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'users_active'.tr : 'users_inactive'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: user.isActive ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, user, controller),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text('roles_modify'.tr),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(user.isActive ? Icons.block : Icons.check_circle),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'users_deactivate'.tr : 'users_activate'.tr),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'change_password',
              child: Row(
                children: [
                  const Icon(Icons.lock_reset),
                  const SizedBox(width: 8),
                  Text('users_change_password_action'.tr),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('users_delete'.tr, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToUserForm(context, controller, user: user),
      ),
    );
  }

  void _handleMenuAction(String action, User user, UserController controller) {
    switch (action) {
      case 'edit':
        _navigateToUserForm(Get.context!, controller, user: user);
        break;
      case 'toggle_status':
        controller.toggleUserStatus(user);
        break;
      case 'change_password':
        _showChangePasswordDialog(user, controller);
        break;
      case 'delete':
        controller.confirmDeleteUser(user);
        break;
    }
  }

  void _navigateToUserForm(BuildContext context, UserController controller, {User? user}) {
    controller.selectUser(user);
    Get.to(() => const UserFormView());
  }

  void _showChangePasswordDialog(User user, UserController controller) {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('users_change_password_title'.trParams({'username': user.nomUtilisateur})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'users_new_password'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'users_confirm_password'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isEmpty) {
                Get.snackbar('common_error'.tr, 'users_password_empty'.tr);
                return;
              }
              if (passwordController.text != confirmPasswordController.text) {
                Get.snackbar('common_error'.tr, 'users_passwords_not_match'.tr);
                return;
              }
              Get.back();
              controller.changePassword(user.id!, passwordController.text);
            },
            child: Text('users_change_password_action'.tr),
          ),
        ],
      ),
    );
  }
}
