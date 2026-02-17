import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/permission_service.dart';

/// Widget qui affiche son contenu seulement si l'utilisateur a les permissions requises
class PermissionWidget extends StatelessWidget {
  final String module;
  final String privilege;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const PermissionWidget({
    super.key,
    required this.module,
    required this.privilege,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = Get.find<PermissionService>();

    if (permissionService.hasPermission(module, privilege)) {
      return child;
    }

    if (showFallback && fallback != null) {
      return fallback!;
    }

    return const SizedBox.shrink();
  }
}

/// Widget qui affiche son contenu seulement pour les administrateurs
class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const AdminOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = Get.find<PermissionService>();

    if (permissionService.isAdmin) {
      return child;
    }

    if (showFallback && fallback != null) {
      return fallback!;
    }

    return const SizedBox.shrink();
  }
}

/// Mixin pour ajouter des méthodes de vérification de permissions aux contrôleurs
mixin PermissionMixin on GetxController {
  PermissionService get _permissionService => Get.find<PermissionService>();

  /// Vérifie si l'utilisateur a une permission
  bool hasPermission(String permission) {
    final parts = permission.split('.');
    if (parts.length != 2) return false;

    return _permissionService.hasPermission(parts[0], parts[1]);
  }

  /// Lève une exception si l'utilisateur n'a pas la permission
  void requirePermission(String permission) {
    final parts = permission.split('.');
    if (parts.length != 2) {
      throw Exception('Format de permission invalide: $permission');
    }

    _permissionService.requirePermission(parts[0], parts[1]);
  }

  /// Vérifie si l'utilisateur est administrateur
  bool get isAdmin => _permissionService.isAdmin;
}

/// Extension pour faciliter l'utilisation des permissions dans les widgets
extension PermissionExtension on Widget {
  /// Affiche ce widget seulement si l'utilisateur a la permission
  Widget requirePermission(String module, String privilege, {Widget? fallback}) {
    return PermissionWidget(
      module: module,
      privilege: privilege,
      fallback: fallback,
      showFallback: fallback != null,
      child: this,
    );
  }

  /// Affiche ce widget seulement pour les administrateurs
  Widget adminOnly({Widget? fallback}) {
    return AdminOnlyWidget(
      fallback: fallback,
      showFallback: fallback != null,
      child: this,
    );
  }
}
