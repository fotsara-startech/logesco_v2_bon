import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/users/models/role_model.dart' as role_model;
import '../../features/auth/models/user.dart' as auth_user;

/// Service pour gérer les permissions dans l'application
class PermissionService extends GetxService {
  static PermissionService get to => Get.find<PermissionService>();

  /// Obtient l'utilisateur connecté
  auth_user.User? get currentUser {
    try {
      final authController = Get.find<AuthController>();
      return authController.currentUser.value;
    } catch (e) {
      print('⚠️ [PermissionService] AuthController non disponible: $e');
      return null;
    }
  }

  /// Obtient le rôle de l'utilisateur connecté (directement depuis User)
  role_model.UserRole? get currentUserRole {
    final user = currentUser;
    if (user == null) return null;
    
    // Le rôle est maintenant directement un UserRole complet
    return user.role;
  }

  /// Vérifie si l'utilisateur a un privilège spécifique
  bool hasPermission(String module, String privilege) {
    final role = currentUserRole;
    if (role == null) {
      print('⚠️ [PermissionService] Aucun rôle trouvé pour $module.$privilege');
      return false;
    }

    final hasPriv = role.hasPrivilege(module, privilege);
    print('🔐 [PermissionService] $module.$privilege = $hasPriv (role: ${role.nom}, isAdmin: ${role.isAdmin})');
    return hasPriv;
  }

  /// Vérifie si l'utilisateur est administrateur
  bool get isAdmin {
    final role = currentUserRole;
    return role?.isAdmin ?? false;
  }

  /// Vérifie les permissions pour les modules principaux
  bool get canManageUsers => hasPermission('users', 'CREATE') || hasPermission('users', 'UPDATE') || hasPermission('users', 'DELETE');
  bool get canViewUsers => hasPermission('users', 'READ');

  bool get canManageProducts => hasPermission('products', 'CREATE') || hasPermission('products', 'UPDATE') || hasPermission('products', 'DELETE');
  bool get canViewProducts => hasPermission('products', 'READ');

  bool get canManageSales => hasPermission('sales', 'CREATE') || hasPermission('sales', 'UPDATE') || hasPermission('sales', 'DELETE');
  bool get canViewSales => hasPermission('sales', 'READ');
  bool get canMakeSales => hasPermission('sales', 'CREATE');

  bool get canManageInventory => hasPermission('inventory', 'CREATE') || hasPermission('inventory', 'UPDATE') || hasPermission('inventory', 'ADJUST');
  bool get canViewInventory => hasPermission('inventory', 'READ');

  bool get canManageReports => hasPermission('reports', 'READ') || hasPermission('reports', 'EXPORT');
  bool get canViewReports => hasPermission('reports', 'READ');

  bool get canManageCompanySettings => hasPermission('company_settings', 'UPDATE');
  bool get canViewCompanySettings => hasPermission('company_settings', 'READ');

  bool get canManageCashRegisters => hasPermission('cash_registers', 'CREATE') || hasPermission('cash_registers', 'UPDATE');
  bool get canViewCashRegisters => hasPermission('cash_registers', 'READ');
  bool get canOperateCashRegisters => hasPermission('cash_registers', 'OPEN') || hasPermission('cash_registers', 'CLOSE');

  bool get canViewDashboard => hasPermission('dashboard', 'READ');
  bool get canViewDashboardStats => hasPermission('dashboard', 'STATS');

  bool get canManageFinancialMovements => hasPermission('financial_movements', 'CREATE') || hasPermission('financial_movements', 'UPDATE');
  bool get canViewFinancialMovements => hasPermission('financial_movements', 'READ');
  bool get canViewFinancialReports => hasPermission('financial_movements', 'REPORTS');

  /// Lève une exception si l'utilisateur n'a pas la permission
  void requirePermission(String module, String privilege) {
    if (!hasPermission(module, privilege)) {
      throw Exception('Permission refusée: $module.$privilege');
    }
  }

  /// Vérifie si l'utilisateur peut accéder à une route
  bool canAccessRoute(String routeName) {
    switch (routeName) {
      case '/users':
        return canViewUsers;
      case '/users/create':
      case '/users/edit':
        return canManageUsers;
      case '/products':
        return canViewProducts;
      case '/products/create':
      case '/products/edit':
        return canManageProducts;
      case '/sales':
        return canViewSales;
      case '/sales/create':
        return canMakeSales;
      case '/inventory':
        return canViewInventory;
      case '/inventory/adjust':
        return canManageInventory;
      case '/reports':
        return canViewReports;
      case '/settings':
        return canViewCompanySettings;
      case '/cash-registers':
        return canViewCashRegisters;
      case '/dashboard':
        return canViewDashboard;
      case '/financial-movements':
        return canViewFinancialMovements;
      default:
        return true; // Par défaut, autoriser l'accès
    }
  }
}
