import 'package:get/get.dart';
import '../services/auth_service.dart';
import 'permission_service.dart';

/// Service de gestion des autorisations basées sur les rôles
/// DÉPRÉCIÉ: Utilise maintenant PermissionService en interne
class AuthorizationService extends GetxService {
  final AuthService _authService = Get.put(AuthService());

  /// Service de permissions (nouveau système)
  PermissionService get _permissionService => Get.find<PermissionService>();

  /// Utilisateur actuellement connecté (délègue au PermissionService)
  get currentUser => _permissionService.currentUser;

  /// Rôle de l'utilisateur actuel (délègue au PermissionService)
  get currentUserRole => _permissionService.currentUserRole;

  /// Vérifie si l'utilisateur est administrateur
  bool get isAdmin => _permissionService.isAdmin;

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => _authService.isAuthenticated && currentUser != null;

  /// Indique si le service est en cours de chargement
  bool get isLoading => false; // Simplifié

  /// Simuler la connexion d'un utilisateur spécifique (pour les tests)
  /// DÉPRÉCIÉ: Utilise PermissionService à la place
  Future<void> loginAsUser(String username) async {
    // Cette méthode est conservée pour compatibilité mais ne fait rien
    // Le PermissionService gère maintenant l'authentification
    print('⚠️ [AuthorizationService] loginAsUser est déprécié, utilisez PermissionService');
  }

  // ==================== GESTION DES UTILISATEURS ====================

  /// Peut gérer les utilisateurs (créer, modifier, supprimer)
  bool get canManageUsers => _permissionService.canManageUsers;

  /// Peut voir la liste des utilisateurs
  bool get canViewUsers => _permissionService.canViewUsers;

  /// Peut créer des utilisateurs
  bool get canCreateUsers => _permissionService.canManageUsers;

  /// Peut modifier des utilisateurs
  bool get canEditUsers => _permissionService.canManageUsers;

  /// Peut supprimer des utilisateurs
  bool get canDeleteUsers => _permissionService.canManageUsers;

  /// Peut modifier les rôles des utilisateurs
  bool get canManageUserRoles => _permissionService.isAdmin;

  // ==================== GESTION DES PRODUITS ====================

  /// Peut gérer les produits
  bool get canManageProducts => _permissionService.canManageProducts;

  /// Peut voir les produits (pour les ventes uniquement si pas de gestion)
  bool get canViewProducts => _permissionService.canViewProducts;

  /// Peut voir les produits dans le contexte des ventes
  bool get canViewProductsForSales => _permissionService.canViewProducts || _permissionService.canMakeSales;

  /// Peut créer des produits
  bool get canCreateProducts => _permissionService.canManageProducts;

  /// Peut modifier des produits
  bool get canEditProducts => _permissionService.canManageProducts;

  /// Peut supprimer des produits
  bool get canDeleteProducts => _permissionService.canManageProducts;

  // ==================== DÉLÉGATION AU PERMISSION SERVICE ====================
  // Toutes les méthodes délèguent maintenant au PermissionService

  bool get canManageSales => _permissionService.canManageSales;
  bool get canMakeSales => _permissionService.canMakeSales;
  bool get canViewSales => _permissionService.canViewSales;
  bool get canCancelSales => _permissionService.canManageSales;
  bool get canApplyDiscounts => _permissionService.canManageSales;

  bool get canManageInventory => _permissionService.canManageInventory;
  bool get canViewInventory => _permissionService.canViewInventory;
  bool get canCreateInventory => _permissionService.canManageInventory;
  bool get canEditInventory => _permissionService.canManageInventory;
  bool get canCloseInventory => _permissionService.canManageInventory;

  bool get canManageStock => _permissionService.canManageInventory;
  bool get canViewStock => _permissionService.canViewInventory;
  bool get canAdjustStock => _permissionService.canManageInventory;
  bool get canViewStockMovements => _permissionService.canViewInventory;

  bool get canManageReports => _permissionService.canManageReports;
  bool get canViewReports => _permissionService.canViewReports;
  bool get canExportReports => _permissionService.canManageReports;
  bool get canViewFinancialReports => _permissionService.canViewFinancialReports;

  bool get canManageCashRegisters => _permissionService.canManageCashRegisters;
  bool get canOperateCashRegisters => _permissionService.canOperateCashRegisters;
  bool get canViewCashMovements => _permissionService.canViewCashRegisters;

  bool get canManageCompanySettings => _permissionService.canManageCompanySettings;
  bool get canEditCompanyInfo => _permissionService.canManageCompanySettings;
  bool get canManageSystemSettings => _permissionService.isAdmin;

  bool get canManageCustomers => _permissionService.canManageSales || _permissionService.canManageProducts;
  bool get canViewCustomers => canManageCustomers || _permissionService.canMakeSales;
  bool get canManageSuppliers => _permissionService.canManageProducts || _permissionService.isAdmin;
  bool get canViewSuppliers => canManageSuppliers;

  // ==================== MÉTHODES UTILITAIRES ====================

  /// Vérifie si l'utilisateur a une permission spécifique (délègue au PermissionService)
  bool hasPermission(String permission) {
    // Convertir le format ancien vers le nouveau si nécessaire
    final parts = permission.split('.');
    if (parts.length == 2) {
      return _permissionService.hasPermission(parts[0], parts[1].toUpperCase());
    }

    // Fallback pour l'ancien format
    return _permissionService.isAdmin;
  }

  /// Vérifie si l'utilisateur a toutes les permissions spécifiées
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  /// Vérifie si l'utilisateur a au moins une des permissions spécifiées
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  /// Lance une exception si l'utilisateur n'a pas la permission
  void requirePermission(String permission) {
    if (!hasPermission(permission)) {
      throw UnauthorizedException('Permission requise: $permission');
    }
  }

  /// Lance une exception si l'utilisateur n'est pas administrateur
  void requireAdmin() {
    if (!isAdmin) {
      throw UnauthorizedException('Privilèges administrateur requis');
    }
  }

  /// Vérifie si l'utilisateur peut accéder à une route
  bool canAccessRoute(String route) {
    // Définir les permissions requises pour chaque route
    final routePermissions = <String, List<String>>{
      '/users': ['users.view'],
      '/users/create': ['users.create'],
      '/users/:id/edit': ['users.edit'],
      '/products': ['products.view'],
      '/products/create': ['products.create'],
      '/products/:id/edit': ['products.edit'],
      '/sales': ['sales.view'],
      '/sales/create': ['sales.make'],
      '/inventory': ['inventory.view'],
      '/stock-inventory': ['inventory.view'],
      '/stock-inventory/create': ['inventory.create'],
      '/reports': ['reports.view'],
      '/settings': ['settings.company'],
      '/customers': ['customers.view'],
      '/suppliers': ['suppliers.view'],
    };

    final permissions = routePermissions[route];
    if (permissions == null) return true; // Route publique

    return hasAnyPermission(permissions);
  }
}

/// Exception lancée quand l'utilisateur n'a pas les permissions requises
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}
