import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/role_controller.dart';
import '../models/role_model.dart';
import 'role_form_page.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';

/// Page de gestion des rôles utilisateur
class RolesPage extends GetView<RoleController> {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('roles_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
            tooltip: 'users_refresh'.tr,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.roles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('roles_loading'.tr),
              ],
            ),
          );
        }

        if (controller.error.value.isNotEmpty && controller.roles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'roles_loading_error'.tr,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.error.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.loadRoles,
                  icon: const Icon(Icons.refresh),
                  label: Text('roles_retry'.tr),
                ),
              ],
            ),
          );
        }

        if (controller.roles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'roles_no_roles'.tr,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'roles_no_roles_hint'.tr,
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showCreateRoleDialog,
                  icon: const Icon(Icons.add),
                  label: Text('roles_create_role'.tr),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildStatsCard(),
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: Obx(() {
                  final filtered = controller.filteredRoles;
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'roles_no_results'.tr,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final role = filtered[index];
                      return _buildRoleCard(context, role);
                    },
                  );
                }),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoleDialog,
        tooltip: 'roles_add_role'.tr,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        onChanged: (value) => controller.searchQuery.value = value,
        decoration: InputDecoration(
          hintText: 'roles_search_hint'.tr,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.searchQuery.value = '';
                  },
                )
              : const SizedBox.shrink()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = controller.getRoleStats();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'roles_stats_total'.tr,
                  stats['total'].toString(),
                  Icons.admin_panel_settings,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'roles_stats_admin'.tr,
                  stats['admin'].toString(),
                  Icons.security,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'roles_stats_standard'.tr,
                  stats['standard'].toString(),
                  Icons.person,
                  Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(BuildContext context, UserRole role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: role.isAdmin ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
          radius: 24,
          child: Icon(
            role.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: role.isAdmin ? Colors.red : Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          role.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${'roles_code'.tr}: ${role.nom}',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (role.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'roles_admin_badge'.tr,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  ..._buildPrivilegeChips(role),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 10, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        role.userCount == 1 ? '1 ${'roles_user_singular'.tr}' : '${role.userCount} ${'roles_user_plural'.tr}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleRoleAction(action, role),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: const Icon(Icons.visibility, size: 20),
                title: Text('roles_view_details'.tr),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit, size: 20),
                title: Text('roles_modify'.tr),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red, size: 20),
                title: Text('roles_delete'.tr, style: const TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showRoleDetails(role),
      ),
    );
  }

  List<Widget> _buildPrivilegeChips(UserRole role) {
    final totalPrivileges = role.privileges.values.expand((privileges) => privileges).length;

    if (totalPrivileges == 0) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'roles_no_privileges'.tr,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ),
      ];
    }

    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          totalPrivileges > 1 ? 'roles_privileges_count_plural'.trParams({'count': totalPrivileges.toString()}) : 'roles_privileges_count'.trParams({'count': totalPrivileges.toString()}),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];
  }

  void _handleRoleAction(String action, UserRole role) {
    switch (action) {
      case 'view':
        _showRoleDetails(role);
        break;
      case 'edit':
        _showEditRoleDialog(role);
        break;
      case 'delete':
        _showDeleteRoleDialog(role);
        break;
    }
  }

  void _showCreateRoleDialog() {
    controller.selectRole(null);
    Get.to(() => const RoleFormPage());
  }

  void _showEditRoleDialog(UserRole role) {
    controller.selectRole(role);
    Get.to(() => RoleFormPage(role: role));
  }

  void _showRoleDetails(UserRole role) {
    Get.dialog(
      AlertDialog(
        title: Text(role.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('roles_code'.tr, role.nom),
              _buildDetailRow('roles_type'.tr, role.isAdmin ? 'roles_administrator'.tr : 'roles_stats_standard'.tr),
              const SizedBox(height: 16),
              if (!role.isAdmin) ...[
                Text(
                  'roles_privileges_by_module'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...role.privileges.entries.map((entry) {
                  if (entry.value.isEmpty) return const SizedBox.shrink();
                  final moduleName = (ModulePrivileges.moduleDisplayNames[entry.key] ?? entry.key).tr;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moduleName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Wrap(
                          spacing: 4,
                          children: entry.value.map((privilege) {
                            final displayName = (ModulePrivileges.privilegeDisplayNames[privilege] ?? privilege).tr;
                            return Chip(
                              label: Text(displayName),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('roles_close'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showEditRoleDialog(role);
            },
            child: Text('roles_modify'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoleDialog(UserRole role) {
    Get.dialog(
      AlertDialog(
        title: Text('roles_delete_confirm_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('roles_delete_confirm_message'.tr),
            const SizedBox(height: 8),
            Text(
              '"${role.displayName}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'roles_delete_irreversible'.tr,
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_cancel'.tr),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final success = await controller.deleteRole(role);
                        if (success) {
                          Get.back();
                          SnackbarHelper.success('roles_deleted_success'.tr);
                        } else {
                          SnackbarHelper.error(controller.error.value.isNotEmpty ? controller.error.value : 'roles_delete_error'.tr);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('roles_delete'.tr),
              )),
        ],
      ),
    );
  }
}
