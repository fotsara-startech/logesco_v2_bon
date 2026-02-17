import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/role_controller.dart';
import '../models/role_model.dart';
import 'role_form_page.dart';

/// Page de gestion des rôles utilisateur
class RolesPage extends GetView<RoleController> {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des rôles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.roles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des rôles...'),
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
                  'Erreur de chargement',
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
                  label: const Text('Réessayer'),
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
                  'Aucun rôle',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par créer votre premier rôle',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showCreateRoleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un rôle'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildStatsCard(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.roles.length,
                  itemBuilder: (context, index) {
                    final role = controller.roles[index];
                    return _buildRoleCard(context, role);
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoleDialog,
        tooltip: 'Ajouter un rôle',
        child: const Icon(Icons.add),
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
                  'Total',
                  stats['total'].toString(),
                  Icons.admin_panel_settings,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Admin',
                  stats['admin'].toString(),
                  Icons.security,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Standard',
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
          backgroundColor: role.isAdmin ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
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
              'Code: ${role.nom}',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            if (role.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'ADMINISTRATEUR',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: _buildPrivilegeChips(role),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleRoleAction(action, role),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility, size: 20),
                title: Text('Voir les détails'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red, size: 20),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
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
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Aucun privilège',
            style: TextStyle(
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
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$totalPrivileges privilège${totalPrivileges > 1 ? 's' : ''}',
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
              _buildDetailRow('Code', role.nom),
              _buildDetailRow('Type', role.isAdmin ? 'Administrateur' : 'Standard'),
              const SizedBox(height: 16),
              if (!role.isAdmin) ...[
                const Text(
                  'Privilèges par module:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...role.privileges.entries.map((entry) {
                  if (entry.value.isEmpty) return const SizedBox.shrink();
                  final moduleName = ModulePrivileges.moduleDisplayNames[entry.key] ?? entry.key;
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
                            final displayName = ModulePrivileges.privilegeDisplayNames[privilege] ?? privilege;
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
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showEditRoleDialog(role);
            },
            child: const Text('Modifier'),
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
        title: const Text('Supprimer le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir supprimer le rôle :'),
            const SizedBox(height: 8),
            Text(
              '"${role.displayName}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action est irréversible.',
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final success = await controller.deleteRole(role);
                        if (success) {
                          Get.back();
                          Get.snackbar(
                            'Succès',
                            'Rôle supprimé avec succès',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green[100],
                            colorText: Colors.green[800],
                          );
                        } else {
                          Get.snackbar(
                            'Erreur',
                            controller.error.value.isNotEmpty ? controller.error.value : 'Erreur lors de la suppression',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red[100],
                            colorText: Colors.red[800],
                          );
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
                    : const Text('Supprimer'),
              )),
        ],
      ),
    );
  }
}
