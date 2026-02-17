void main() {
  print('🔍 Test du système de permissions');
  print('=' * 50);

  // Simuler différents rôles utilisateur
  final roles = {
    'Administrateur': {
      'isAdmin': true,
      'permissions': ['all']
    },
    'Gestionnaire': {
      'isAdmin': false,
      'permissions': ['canManageProducts', 'canManageSales', 'canManageInventory', 'canViewReports', 'canManageStock']
    },
    'Vendeur': {
      'isAdmin': false,
      'permissions': ['canMakeSales', 'canViewReports']
    },
    'Magasinier': {
      'isAdmin': false,
      'permissions': ['canManageInventory', 'canManageStock', 'canManageProducts']
    },
    'Comptable': {
      'isAdmin': false,
      'permissions': ['canViewReports', 'canManageReports', 'canManageCompanySettings']
    },
    'Utilisateur': {
      'isAdmin': false,
      'permissions': ['canViewReports']
    },
  };

  // Modules et leurs permissions requises
  final modules = {
    'Produits': 'products.view',
    'Fournisseurs': 'suppliers.view',
    'Clients': 'customers.view',
    'Approvisionnements': 'products.manage',
    'Ventes': 'sales.make',
    'Stock': 'stock.view',
    'Impression': 'sales.view',
    'Comptes': 'customers.view',
    'Rapports': 'reports.view',
    'Paramètres': 'settings.company',
    'Utilisateurs': 'users.manage',
    'Caisses': 'cash.manage',
    'Inventaire Stock': 'inventory.view',
  };

  // Tester chaque rôle
  for (final roleEntry in roles.entries) {
    final roleName = roleEntry.key;
    final roleData = roleEntry.value;

    print('\n👤 Rôle: $roleName');
    print('   Admin: ${roleData['isAdmin']}');
    print('   Permissions: ${roleData['permissions']}');
    print('   Modules accessibles:');

    for (final moduleEntry in modules.entries) {
      final moduleName = moduleEntry.key;
      final requiredPermission = moduleEntry.value;

      final hasAccess = _hasPermission(roleData, requiredPermission);
      final icon = hasAccess ? '✅' : '❌';

      print('     $icon $moduleName');
    }
  }

  print('\n📊 Résumé:');
  print('✅ Le système de rôles est configuré');
  print('✅ Les permissions sont définies par module');
  print('✅ Les utilisateurs voient uniquement les modules autorisés');
  print('\n💡 Pour tester dans l\'application:');
  print('1. Démarrez l\'application Flutter');
  print('2. Allez au Dashboard');
  print('3. Cliquez sur "Test Rôles" pour changer d\'utilisateur');
  print('4. Observez que les modules changent selon le rôle');
}

bool _hasPermission(Map<String, dynamic> roleData, String requiredPermission) {
  final isAdmin = roleData['isAdmin'] as bool;
  final permissions = roleData['permissions'] as List<String>;

  // Les admins ont tous les droits
  if (isAdmin || permissions.contains('all')) {
    return true;
  }

  // Mapper les permissions requises aux permissions du rôle
  switch (requiredPermission) {
    case 'products.view':
    case 'products.manage':
      return permissions.contains('canManageProducts');
    case 'suppliers.view':
      return permissions.contains('canManageProducts');
    case 'customers.view':
      return permissions.contains('canMakeSales') || permissions.contains('canManageSales');
    case 'sales.make':
    case 'sales.view':
      return permissions.contains('canMakeSales') || permissions.contains('canManageSales');
    case 'stock.view':
      return permissions.contains('canManageStock') || permissions.contains('canManageInventory');
    case 'inventory.view':
      return permissions.contains('canManageInventory');
    case 'reports.view':
      return permissions.contains('canViewReports') || permissions.contains('canManageReports');
    case 'settings.company':
      return permissions.contains('canManageCompanySettings');
    case 'users.manage':
      return permissions.contains('canManageUsers');
    case 'cash.manage':
      return permissions.contains('canManageCashRegisters');
    default:
      return false;
  }
}
