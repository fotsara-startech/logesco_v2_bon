import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

/// Widget d'accès rapide à la gestion des rôles
class RoleQuickAccess extends StatelessWidget {
  const RoleQuickAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Get.toNamed(AppRoutes.roles),
      icon: const Icon(Icons.admin_panel_settings),
      label: Text('roles_quick_access'.tr),
      backgroundColor: Colors.indigo,
      tooltip: 'roles_manage_tooltip'.tr,
    );
  }
}

/// Bouton compact pour les rôles
class RoleQuickButton extends StatelessWidget {
  const RoleQuickButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Get.toNamed(AppRoutes.roles),
      icon: const Icon(Icons.admin_panel_settings, size: 18),
      label: Text('roles_quick_access'.tr),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

/// Chip cliquable pour les rôles
class RoleAccessChip extends StatelessWidget {
  const RoleAccessChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.admin_panel_settings, size: 16),
      label: Text('roles_manage_privileges'.tr),
      onPressed: () => Get.toNamed(AppRoutes.roles),
      backgroundColor: Colors.indigo.withOpacity(0.1),
      side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
    );
  }
}

/// Tuile de menu pour les rôles
class RoleMenuTile extends StatelessWidget {
  const RoleMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
      title: Text('roles_manage_user_roles'.tr),
      subtitle: Text('roles_create_manage'.tr),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Get.toNamed(AppRoutes.roles),
    );
  }
}

/// Card d'accès aux rôles pour le dashboard
class RoleDashboardCard extends StatelessWidget {
  const RoleDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.roles),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 32,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'roles_quick_access'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'roles_manage_privileges'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
