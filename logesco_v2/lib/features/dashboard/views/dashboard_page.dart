import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/authorization_service.dart';
import '../../financial_movements/widgets/daily_expenses_summary_widget.dart';
import '../../financial_movements/widgets/weekly_financial_summary_widget.dart';

/// Page principale du tableau de bord
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LOGESCO v2 - Tableau de bord'),
        actions: [
          // Informations utilisateur
          Obx(() {
            final user = authController.currentUser.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.nomUtilisateur ?? 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Menu de déconnexion
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, authController);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            _buildWelcomeSection(authController),

            const SizedBox(height: 16),

            // Accès rapide à l'impression
            _buildQuickAccessSection(authController),

            const SizedBox(height: 16),

            // Résumé des dépenses du jour
            _buildDailyExpensesSummary(authController),

            const SizedBox(height: 16),

            // Résumé hebdomadaire des finances
            _buildWeeklyFinancialSummary(authController),

            const SizedBox(height: 24),

            // Grille des modules principaux
            Expanded(
              child: _buildModulesGrid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AuthController authController) {
    return Obx(() {
      final user = authController.currentUser.value;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  size: 30,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue, ${user?.nomUtilisateur ?? 'Utilisateur'} !',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Gérez votre commerce efficacement avec LOGESCO v2',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user?.role.isAdmin == true ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: user?.role.isAdmin == true ? Colors.amber.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user?.role.isAdmin == true ? Icons.admin_panel_settings : Icons.person,
                                size: 12,
                                color: user?.role.isAdmin == true ? Colors.amber.shade700 : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user?.role.displayName ?? 'Utilisateur',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: user?.role.isAdmin == true ? Colors.amber.shade700 : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuickAccessSection(AuthController authController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Accès rapide',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickActionsRow(authController),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyExpensesSummary(AuthController authController) {
    // Vérifier si l'utilisateur a accès aux mouvements financiers
    if (!_hasPermissionFallback(authController, 'financial.view')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: Colors.pink.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Résumé financier',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.financialMovementReports),
              icon: const Icon(Icons.analytics, size: 16),
              label: const Text('Rapports'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.pink.shade600,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const DetailedDailyExpensesSummary(
          color: Colors.pink,
        ),
      ],
    );
  }

  Widget _buildWeeklyFinancialSummary(AuthController authController) {
    // Vérifier si l'utilisateur a accès aux mouvements financiers
    if (!_hasPermissionFallback(authController, 'financial.view')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.indigo.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Tendances hebdomadaires',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.financialMovements),
              icon: const Icon(Icons.list, size: 16),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.indigo.shade600,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const WeeklyFinancialSummaryWidget(
          primaryColor: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow(AuthController authController) {
    final List<Widget> actions = [
      Expanded(
        child: _buildQuickActionButton(
          icon: Icons.point_of_sale,
          label: 'Nouvelle vente',
          color: Colors.green,
          onTap: () => Get.toNamed(AppRoutes.createSale),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildQuickActionButton(
          icon: Icons.print,
          label: 'Réimprimer reçu',
          color: Colors.deepPurple,
          onTap: () => Get.toNamed(AppRoutes.printing),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildQuickActionButton(
          icon: Icons.inventory_2,
          label: 'Vérifier stock',
          color: Colors.teal,
          onTap: () => Get.toNamed(AppRoutes.inventory),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildQuickActionButton(
          icon: Icons.category,
          label: 'Catégories',
          color: Colors.purple,
          onTap: () {
            // print('🔍 Dashboard - Bouton Catégories cliqué');
            // print('🔍 Dashboard - Navigation vers les catégories');
            Get.toNamed(AppRoutes.categories);
          },
        ),
      ),
    ];

    // Ajouter l'accès rapide aux mouvements financiers si l'utilisateur a les permissions
    if (_hasPermissionFallback(authController, 'financial.view')) {
      actions.addAll([
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.account_balance_wallet,
            label: 'Nouvelle dépense',
            color: Colors.pink,
            onTap: () => Get.toNamed(AppRoutes.createFinancialMovement),
          ),
        ),
      ]);
    }

    // Ajouter l'accès rapide aux paramètres d'entreprise pour les administrateurs
    if (_canManageCompanySettings(authController)) {
      actions.addAll([
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.settings,
            label: 'Paramètres',
            color: Colors.amber,
            onTap: () => Get.toNamed(AppRoutes.companySettings),
            isAdminAction: true,
          ),
        ),
      ]);
    }

    // Ajouter le test des rôles en mode développement
    actions.addAll([
      const SizedBox(width: 12),
      Expanded(
        child: _buildQuickActionButton(
          icon: Icons.security,
          label: 'Test Rôles',
          color: Colors.red,
          onTap: () => Get.toNamed(AppRoutes.roleTest),
        ),
      ),
    ]);

    return Row(children: actions);
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isAdminAction = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                // Indicateur admin pour les actions administrateur
                if (isAdminAction)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isAdminAction) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.lock_outline,
                    size: 10,
                    color: color,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    // Définir tous les modules avec leurs permissions requises
    final allModules = [
      _ModuleItem(
        title: 'Produits',
        subtitle: 'Gérer le catalogue',
        icon: Icons.inventory_2,
        color: Colors.blue,
        route: AppRoutes.products,
        requiredPermission: 'products.view',
      ),
      _ModuleItem(
        title: 'Fournisseurs',
        subtitle: 'Gérer les fournisseurs',
        icon: Icons.business,
        color: Colors.green,
        route: AppRoutes.suppliers,
        requiredPermission: 'suppliers.view',
      ),
      _ModuleItem(
        title: 'Clients',
        subtitle: 'Gérer les clients',
        icon: Icons.people,
        color: Colors.orange,
        route: AppRoutes.customers,
        requiredPermission: 'customers.view',
      ),
      _ModuleItem(
        title: 'Approvisionnements',
        subtitle: 'Commandes fournisseurs',
        icon: Icons.shopping_cart,
        color: Colors.purple,
        route: AppRoutes.procurement,
        requiredPermission: 'products.manage',
      ),
      _ModuleItem(
        title: 'Ventes',
        subtitle: 'Point de vente',
        icon: Icons.point_of_sale,
        color: Colors.red,
        route: AppRoutes.sales,
        requiredPermission: 'sales.make',
      ),
      _ModuleItem(
        title: 'Stock',
        subtitle: 'Gestion du stock',
        icon: Icons.warehouse,
        color: Colors.teal,
        route: AppRoutes.inventory,
        requiredPermission: 'stock.view',
      ),
      _ModuleItem(
        title: 'Impression',
        subtitle: 'Reçus et réimpressions',
        icon: Icons.print,
        color: Colors.deepPurple,
        route: AppRoutes.printing,
        requiredPermission: 'sales.view',
      ),
      _ModuleItem(
        title: 'Comptes',
        subtitle: 'Crédits clients/fournisseurs',
        icon: Icons.account_balance,
        color: Colors.indigo,
        route: AppRoutes.accounts,
        requiredPermission: 'customers.view',
      ),
      _ModuleItem(
        title: 'Rapports',
        subtitle: 'Analyses et statistiques',
        icon: Icons.analytics,
        color: Colors.brown,
        route: AppRoutes.reports,
        requiredPermission: 'reports.view',
      ),
      _ModuleItem(
        title: 'Paramètres',
        subtitle: 'Configuration entreprise',
        icon: Icons.settings,
        color: Colors.grey,
        route: AppRoutes.companySettings,
        requiredPermission: 'settings.company',
        isAdminOnly: true,
      ),
      _ModuleItem(
        title: 'Utilisateurs',
        subtitle: 'Gestion des utilisateurs',
        icon: Icons.people,
        color: Colors.deepOrange,
        route: AppRoutes.users,
        requiredPermission: 'users.manage',
        isAdminOnly: true,
      ),
      _ModuleItem(
        title: 'Caisses',
        subtitle: 'Gestion des caisses',
        icon: Icons.point_of_sale,
        color: Colors.cyan,
        route: AppRoutes.cashRegisters,
        requiredPermission: 'cash.manage',
      ),
      _ModuleItem(
        title: 'Inventaire Stock',
        subtitle: 'Comptage et vérification',
        icon: Icons.inventory,
        color: Colors.lime,
        route: AppRoutes.stockInventory,
        requiredPermission: 'inventory.view',
      ),
      _ModuleItem(
        title: 'Mouvements Financiers',
        subtitle: 'Traçabilité des sorties',
        icon: Icons.account_balance_wallet,
        color: Colors.pink,
        route: AppRoutes.financialMovements,
        requiredPermission: 'financial.view',
      ),
    ];

    // Filtrer les modules selon les permissions de l'utilisateur
    final modules = allModules.where((module) {
      return _hasPermissionForModule(authController, module);
    }).toList();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleCard(context, module);
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildModuleCard(BuildContext context, _ModuleItem module) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToModule(module),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: module.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      module.icon,
                      size: 30,
                      color: module.color,
                    ),
                  ),
                  // Indicateur admin
                  if (module.isAdminOnly)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (module.isAdminOnly) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                module.subtitle,
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

  /// Vérifie si l'utilisateur peut gérer les paramètres d'entreprise
  bool _canManageCompanySettings(AuthController authController) {
    final user = authController.currentUser.value;
    if (user == null) return false;
    return user.role.canManageCompanySettings;
  }

  /// Vérifie si l'utilisateur a la permission pour accéder à un module
  bool _hasPermissionForModule(AuthController authController, _ModuleItem module) {
    // Si aucune permission spécifique n'est requise, autoriser l'accès
    if (module.requiredPermission == null) {
      return true;
    }

    // Utiliser le service d'autorisation pour vérifier la permission
    try {
      final authService = Get.find<AuthorizationService>();
      return authService.hasPermission(module.requiredPermission!);
    } catch (e) {
      // Si le service d'autorisation n'est pas disponible, utiliser les méthodes existantes
      print('⚠️ Service d\'autorisation non disponible, utilisation des méthodes de fallback');
      return _hasPermissionFallback(authController, module.requiredPermission!);
    }
  }

  /// Méthode de fallback pour vérifier les permissions
  bool _hasPermissionFallback(AuthController authController, String permission) {
    final user = authController.currentUser.value;
    if (user == null) return false;

    final role = user.role;

    // Si l'utilisateur est admin, autoriser tout
    if (role.isAdmin) return true;

    // Vérifier les permissions spécifiques
    switch (permission) {
      case 'products.view':
      case 'products.manage':
        return role.canManageProducts;
      case 'suppliers.view':
        return role.canManageProducts; // Les fournisseurs sont liés aux produits
      case 'customers.view':
        return role.canManageSales; // Les clients sont liés aux ventes
      case 'sales.make':
      case 'sales.view':
        return role.canManageSales;
      case 'stock.view':
        return role.canManageInventory;
      case 'inventory.view':
        return role.canManageInventory;
      case 'reports.view':
        return role.canManageReports;
      case 'settings.company':
        return role.canManageCompanySettings;
      case 'users.manage':
        return role.canManageUsers;
      case 'cash.manage':
        return role.canManageCashRegisters;
      case 'financial.view':
        return role.canManageReports; // Utilise la permission des rapports pour les mouvements financiers
      default:
        return false;
    }
  }

  void _navigateToModule(_ModuleItem module) {
    final AuthController authController = Get.find<AuthController>();

    // Vérifier les permissions pour le module
    if (!_hasPermissionForModule(authController, module)) {
      final user = authController.currentUser.value;
      Get.snackbar(
        'Accès refusé',
        'Votre rôle (${user?.role.displayName ?? 'Inconnu'}) ne permet pas d\'accéder à ce module',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.lock_outline, color: Colors.red),
      );
      return;
    }

    // Modules implémentés
    final implementedModules = {
      AppRoutes.products,
      AppRoutes.accounts,
      AppRoutes.customers,
      AppRoutes.suppliers,
      AppRoutes.inventory,
      AppRoutes.procurement,
      AppRoutes.sales,
      AppRoutes.companySettings,
      AppRoutes.printing, // Ajout du module d'impression
      AppRoutes.users, // Gestion des utilisateurs
      AppRoutes.cashRegisters, // Gestion des caisses
      AppRoutes.stockInventory, // Inventaire de stock
      AppRoutes.financialMovements, // Mouvements financiers
    };

    if (implementedModules.contains(module.route)) {
      print('🔄 Navigation vers module: ${module.title} (${module.route})');
      Get.toNamed(module.route);
    } else {
      Get.snackbar(
        'Module ${module.title}',
        'Cette fonctionnalité sera implémentée dans les prochaines tâches',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.info_outline, color: Colors.orange),
      );
    }
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await authController.logout(); // La redirection est maintenant gérée dans logout()
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final bool isAdminOnly;
  final String? requiredPermission;

  _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.isAdminOnly = false,
    this.requiredPermission,
  });
}
