import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/modern_stat_card.dart';
import '../widgets/recent_activities_widget.dart';
import '../widgets/sales_chart_widget.dart';
import '../widgets/accounting_summary_widget.dart';
import '../widgets/profitability_stat_card.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/permission_service.dart';
import '../../subscription/widgets/subscription_status_widget.dart';
import '../../subscription/views/subscription_status_page.dart';
import '../../cash_registers/widgets/cash_session_indicator.dart';

class ModernDashboardPage extends StatelessWidget {
  const ModernDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final DashboardController dashboardController = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const CashSessionIndicator(),
          const SubscriptionAppBarWidget(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.business, size: 30, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'LOGESCO v2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'dashboard_subtitle'.tr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuSection('menu_sales_customers'.tr, [
                    if (_hasPermission('sales', 'READ')) _buildMenuItem(Icons.point_of_sale, 'sales_title'.tr, Colors.green, () => Get.toNamed(AppRoutes.sales)),
                    if (_hasPermission('customers', 'READ')) _buildMenuItem(Icons.people, 'customers_title'.tr, Colors.blue, () => Get.toNamed(AppRoutes.customers)),
                    // if (_hasPermission('sales', 'READ')) _buildMenuItem(Icons.receipt_long, 'receipts_title'.tr, Colors.orange, () {}),
                  ]),
                  _buildMenuSection('menu_stock_products'.tr, [
                    if (_hasPermission('products', 'READ')) _buildMenuItem(Icons.inventory_2, 'products_title'.tr, Colors.purple, () => Get.toNamed(AppRoutes.products)),
                    if (_hasPermission('products', 'READ')) _buildMenuItem(Icons.category, 'categories_title'.tr, Colors.indigo, () => Get.toNamed(AppRoutes.categories)),
                    if (_hasPermission('inventory', 'READ')) _buildMenuItem(Icons.warehouse, 'inventory_stock'.tr, Colors.teal, () => Get.toNamed(AppRoutes.inventory)),
                    if (_hasPermission('stock_inventory', 'READ')) _buildMenuItem(Icons.assignment, 'inventory_title'.tr, Colors.cyan, () => Get.toNamed(AppRoutes.stockInventory)),
                  ]),
                  _buildMenuSection('menu_procurement'.tr, [
                    if (_hasPermission('suppliers', 'READ')) _buildMenuItem(Icons.local_shipping, 'suppliers_title'.tr, Colors.brown, () => Get.toNamed(AppRoutes.suppliers)),
                    if (_hasPermission('procurement', 'READ')) _buildMenuItem(Icons.shopping_cart, 'menu_orders'.tr, Colors.deepOrange, () => Get.toNamed(AppRoutes.procurement)),
                    // if (_hasPermission('procurement', 'READ')) _buildMenuItem(Icons.input, 'menu_receptions'.tr, Colors.green.shade700, () {}),
                  ]),
                  _buildMenuSection('menu_financial'.tr, [
                    if (_hasPermission('accounting', 'READ')) _buildMenuItem(Icons.analytics, 'menu_accounting'.tr, Colors.green, () => Get.toNamed(AppRoutes.accounting)),
                    if (_hasPermission('cash_registers', 'READ')) _buildMenuItem(Icons.account_balance, 'menu_cash_registers'.tr, Colors.amber, () => Get.toNamed(AppRoutes.cashRegisters)),
                    _buildMenuItem(Icons.history, 'menu_cash_sessions'.tr, Colors.blue, () => Get.toNamed(AppRoutes.cashSessionHistory)),
                  ]),
                  _buildMenuSection('menu_expenses'.tr, [
                    if (_hasPermission('expenses', 'READ')) _buildMenuItem(Icons.category, 'categories_title'.tr, Colors.teal, () => Get.toNamed(AppRoutes.expenseCategories)),
                    if (_hasPermission('financial_movements', 'READ')) _buildMenuItem(Icons.account_balance_wallet, 'menu_movements'.tr, Colors.pink, () => Get.toNamed(AppRoutes.financialMovements)),
                  ]),
                  _buildMenuSection('menu_reports'.tr, [
                    if (_hasPermission('reports', 'READ')) _buildMenuItem(Icons.assessment, 'menu_balance_sheet'.tr, Colors.green, () => Get.toNamed(AppRoutes.activityReport)),
                    if (_hasPermission('reports', 'READ')) _buildMenuItem(Icons.discount, 'menu_discount_reports'.tr, Colors.deepOrange, () => Get.toNamed(AppRoutes.discountReports)),
                    if (_hasPermission('reports', 'READ')) _buildMenuItem(Icons.bar_chart, 'menu_product_analytics'.tr, Colors.blue, () => Get.toNamed(AppRoutes.productAnalytics)),
                  ]),
                  _buildMenuSection('menu_administration'.tr, [
                    if (_hasPermission('users', 'READ')) _buildMenuItem(Icons.people_outline, 'users_title'.tr, Colors.grey, () => Get.toNamed(AppRoutes.users)),
                    if (_hasPermission('users', 'ROLES')) _buildMenuItem(Icons.admin_panel_settings, 'roles_title'.tr, Colors.indigo, () => Get.toNamed(AppRoutes.roles)),
                    if (_hasPermission('company_settings', 'READ')) _buildMenuItem(Icons.business, 'menu_company'.tr, Colors.blueGrey, () => Get.toNamed(AppRoutes.companySettings)),
                    // if (_hasPermission('printing', 'READ')) _buildMenuItem(Icons.print, 'menu_printing'.tr, Colors.deepPurple, () => Get.toNamed(AppRoutes.printing)),
                    _buildMenuItem(Icons.card_membership, 'menu_subscription'.tr, Colors.deepOrange, () {
                      Get.to(() => const SubscriptionStatusPage());
                    }),
                  ]),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text('auth_logout_button'.tr),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: dashboardController.refresh,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bannière de notification d'abonnement
                const SubscriptionNotificationBanner(),

                // En-tête moderne avec informations utilisateur
                _buildModernHeader(authController),

                const SizedBox(height: 24),

                // Statut d'abonnement
                const SubscriptionStatusWidget(showDetails: false),

                const SizedBox(height: 16),

                // Actions rapides
                _buildQuickActions(),

                const SizedBox(height: 24),

                // Statistiques principales
                _buildMainStats(dashboardController),

                const SizedBox(height: 24),

                // Résumé comptable
                const AccountingSummaryWidget(),

                const SizedBox(height: 24),

                // Graphique et activités récentes
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Graphique des ventes (60% de la largeur)
                    Expanded(
                      flex: 3,
                      child: Obx(() => SalesChartWidget(
                            chartData: dashboardController.salesChartData,
                            isLoading: dashboardController.isLoadingChart.value,
                          )),
                    ),

                    const SizedBox(width: 20),

                    // Activités récentes (40% de la largeur)
                    Expanded(
                      flex: 2,
                      child: Obx(() => RecentActivitiesWidget(
                            activities: dashboardController.recentActivities,
                            isLoading: dashboardController.isLoadingActivities.value,
                          )),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Statistiques détaillées des ventes
                _buildSalesStats(dashboardController),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createSale),
        icon: const Icon(Icons.add),
        label: Text('dashboard_new_sale'.tr),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 8,
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildQuickAccessCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(AuthController authController) {
    return Obx(() {
      final user = authController.currentUser.value;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dashboard_title'.tr,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'dashboard_welcome_message'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildHeaderButton(
                      '+ ${'dashboard_new_sale'.tr}',
                      Colors.green,
                      () => Get.toNamed(AppRoutes.createSale),
                    ),
                    // const SizedBox(width: 12),
                    // _buildHeaderButton(
                    //   'Importer Données',
                    //   Colors.white.withOpacity(0.2),
                    //   () {},
                    //   textColor: Colors.white,
                    // ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'dashboard_welcome'.tr + ', ${user?.nomUtilisateur ?? 'Utilisateur'} !',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHeaderButton(String text, Color color, VoidCallback onPressed, {Color? textColor}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard_quick_actions'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_hasPermission('sales', 'CREATE'))
                _buildQuickActionCard(
                  Icons.point_of_sale,
                  'sales_new'.tr,
                  Colors.green,
                  () => Get.toNamed(AppRoutes.createSale),
                ),
              if (_hasPermission('productS', 'CREATE'))
                _buildQuickActionCard(
                  Icons.add_box,
                  'dashboard_new_product'.tr,
                  Colors.blue,
                  () => Get.toNamed(AppRoutes.createProduct),
                ),
              if (_hasPermission('customerS', 'CREATE'))
                _buildQuickActionCard(
                  Icons.person_add,
                  'dashboard_new_customer'.tr,
                  Colors.orange,
                  () => Get.toNamed(AppRoutes.createCustomer),
                ),
              if (_hasPermission('procurement', 'CREATE'))
                _buildQuickActionCard(
                  Icons.shopping_cart,
                  'dashboard_new_order'.tr,
                  Colors.purple,
                  () => Get.toNamed(AppRoutes.createProcurement),
                ),
              if (_hasPermission('financial_movements', 'CREATE'))
                _buildQuickActionCard(
                  Icons.account_balance_wallet,
                  'dashboard_financial_movement'.tr,
                  Colors.pink,
                  () => Get.toNamed(AppRoutes.createFinancialMovement),
                ),
              if (_hasPermission('accounting', 'READ'))
                _buildQuickActionCard(
                  Icons.analytics,
                  'dashboard_accounting'.tr,
                  Colors.green,
                  () => Get.toNamed(AppRoutes.accounting),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainStats(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard_overview'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final stats = controller.generalStats;
          final isLoading = controller.isLoadingStats.value;

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              ModernStatCard(
                title: 'dashboard_total_products'.tr,
                value: '${stats['totalProducts'] ?? 0}',
                subtitle: 'dashboard_in_stock'.tr,
                icon: Icons.inventory_2,
                color: const Color(0xFF4CAF50),
                isLoading: isLoading,
                onTap: () => Get.toNamed(AppRoutes.products),
                trailing: const TrendIndicator(
                  percentage: 12.5,
                  isPositive: true,
                ),
              ),
              ModernStatCard(
                title: 'dashboard_completed_sales'.tr,
                value: '${stats['totalSales'] ?? 0}',
                subtitle: 'dashboard_this_month'.tr,
                icon: Icons.trending_up,
                color: const Color(0xFF2196F3),
                isLoading: isLoading,
                onTap: () => Get.toNamed(AppRoutes.sales),
              ),
              ModernStatCard(
                title: 'dashboard_pending_sales'.tr,
                value: '${stats['pendingOrders'] ?? 0}',
                subtitle: 'dashboard_to_process'.tr,
                icon: Icons.pending_actions,
                color: const Color(0xFFFF9800),
                isLoading: isLoading,
              ),
              const ProfitabilityStatCard(),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSalesStats(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard_sales_stats'.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final stats = controller.salesStats;
          final isLoading = controller.isLoadingSales.value;

          return Row(
            children: [
              Expanded(
                child: ModernStatCard(
                  title: 'dashboard_today_sales_count'.tr,
                  value: '${stats['todaySales'] ?? 0}',
                  subtitle: '${(stats['todayRevenue'] as num? ?? 0).toDouble().toStringAsFixed(2)} FCFA',
                  icon: Icons.today,
                  color: const Color(0xFF4CAF50),
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernStatCard(
                  title: 'dashboard_week_sales'.tr,
                  value: '${stats['weekSales'] ?? 0}',
                  subtitle: '${(stats['weekRevenue'] as num? ?? 0).toDouble().toStringAsFixed(2)} FCFA',
                  icon: Icons.date_range,
                  color: const Color(0xFF2196F3),
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernStatCard(
                  title: 'dashboard_month_sales'.tr,
                  value: '${stats['monthSales'] ?? 0}',
                  subtitle: '${(stats['monthRevenue'] as num? ?? 0).toDouble().toStringAsFixed(2)} FCFA',
                  icon: Icons.calendar_month,
                  color: const Color(0xFFFF9800),
                  isLoading: isLoading,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    Get.dialog(
      AlertDialog(
        title: Text('auth_logout_button'.tr),
        content: Text('auth_logout_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Fermer le dialog
              await authController.logout(); // Nettoyer les données et rediriger automatiquement
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('auth_logout_button'.tr),
          ),
        ],
      ),
    );
  }

  /// Vérifie si l'utilisateur a une permission spécifique
  bool _hasPermission(String module, String privilege) {
    try {
      final permissionService = Get.find<PermissionService>();
      return permissionService.hasPermission(module, privilege);
    } catch (e) {
      // Si le service n'est pas disponible, refuser l'accès par sécurité
      print('⚠️ PermissionService non disponible pour $module.$privilege');
      return false;
    }
  }
}
