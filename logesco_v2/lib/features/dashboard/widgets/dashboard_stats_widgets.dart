import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'stats_card_widget.dart';
import '../controllers/dashboard_stats_controller.dart';
import '../../../core/routes/app_routes.dart';

/// Collection de widgets de statistiques pour le dashboard
class DashboardStatsWidgets {
  /// Obtient le contrôleur de statistiques avec fallback
  static DashboardStatsController? _getController() {
    try {
      return Get.find<DashboardStatsController>();
    } catch (e) {
      print('⚠️ Contrôleur de statistiques non trouvé: $e');
      return null;
    }
  }

  /// Widget de statistiques des ventes
  static Widget buildSalesStats() {
    final controller = _getController();
    if (controller == null) {
      return _buildFallbackWidget('Ventes du jour', '0 FCFA', '0 transactions', Icons.point_of_sale, Colors.green);
    }

    return Obx(() {
      return StatsCardWidget(
        title: 'Ventes du jour',
        value: '${controller.todaySales.value} FCFA',
        subtitle: '${controller.todaySalesCount.value} transactions',
        icon: Icons.point_of_sale,
        color: Colors.green,
        trend: controller.salesTrend.value,
        isLoading: controller.isLoading.value,
        onTap: () => Get.toNamed(AppRoutes.sales),
      );
    });
  }

  /// Widget de statistiques des produits
  static Widget buildProductsStats() {
    final controller = _getController();
    if (controller == null) {
      return _buildFallbackWidget('Produits en stock', '0', '0 catégories', Icons.inventory_2, Colors.blue);
    }

    return Obx(() {
      return StatsCardWidget(
        title: 'Produits en stock',
        value: controller.totalProducts.value,
        subtitle: '${controller.totalCategories.value} catégories',
        icon: Icons.inventory_2,
        color: Colors.blue,
        trend: controller.productsTrend.value,
        isLoading: controller.isLoading.value,
        onTap: () => Get.toNamed(AppRoutes.products),
      );
    });
  }

  /// Widget de statistiques des clients
  static Widget buildCustomersStats() {
    return _buildStatWidget(
      'Clients actifs',
      (controller) => controller.activeCustomers.value,
      (controller) => '${controller.newCustomersThisMonth.value} nouveaux ce mois',
      Icons.people,
      Colors.orange,
      (controller) => controller.customersTrend.value,
      () => Get.toNamed(AppRoutes.customers),
    );
  }

  /// Widget de statistiques financières
  static Widget buildFinancialStats() {
    return _buildStatWidget(
      'Dépenses du mois',
      (controller) => '${controller.monthlyExpenses.value} FCFA',
      (controller) => '${controller.monthlyExpensesCount.value} mouvements',
      Icons.account_balance_wallet,
      Colors.pink,
      (controller) => controller.expensesTrend.value,
      () => Get.toNamed(AppRoutes.financialMovements),
    );
  }

  /// Widget de statistiques du stock
  static Widget buildStockStats() {
    return _buildStatWidget(
      'Valeur du stock',
      (controller) => '${controller.stockValue.value} FCFA',
      (controller) => 'Valorisation totale',
      Icons.warehouse,
      Colors.teal,
      (controller) => controller.stockTrend.value,
      () => Get.toNamed(AppRoutes.inventory),
    );
  }

  /// Widget de statistiques des fournisseurs
  static Widget buildSuppliersStats() {
    return _buildStatWidget(
      'Fournisseurs',
      (controller) => controller.totalSuppliers.value,
      (controller) => '${controller.pendingOrders.value} commandes en cours',
      Icons.business,
      Colors.indigo,
      null, // Pas de tendance
      () => Get.toNamed(AppRoutes.suppliers),
    );
  }

  /// Widget de statistiques des comptes
  static Widget buildAccountsStats() {
    return _buildStatWidget(
      'Créances clients',
      (controller) => '${controller.clientCredits.value} FCFA',
      (controller) => 'À recouvrer',
      Icons.account_balance,
      Colors.deepOrange,
      (controller) => controller.creditsTrend.value,
      () => Get.toNamed(AppRoutes.accounts),
    );
  }

  /// Widget de statistiques des caisses
  static Widget buildCashStats() {
    return _buildStatWidget(
      'Caisses ouvertes',
      (controller) => controller.openCashRegisters.value,
      (controller) => '${controller.activeCashRegisters.value} actives',
      Icons.point_of_sale,
      Colors.amber,
      null, // Pas de tendance
      () => Get.toNamed(AppRoutes.cashRegisters),
    );
  }

  /// Méthode générique pour construire un widget de statistique
  static Widget _buildStatWidget(
    String title,
    String Function(DashboardStatsController) valueBuilder,
    String Function(DashboardStatsController) subtitleBuilder,
    IconData icon,
    Color color,
    String Function(DashboardStatsController)? trendBuilder,
    VoidCallback onTap,
  ) {
    final controller = _getController();
    if (controller == null) {
      return _buildFallbackWidget(title, '0', 'Chargement...', icon, color);
    }

    return Obx(() {
      return StatsCardWidget(
        title: title,
        value: valueBuilder(controller),
        subtitle: subtitleBuilder(controller),
        icon: icon,
        color: color,
        trend: trendBuilder?.call(controller),
        isLoading: controller.isLoading.value,
        onTap: onTap,
      );
    });
  }

  /// Widget de fallback quand le contrôleur n'est pas disponible
  static Widget _buildFallbackWidget(String title, String value, String subtitle, IconData icon, Color color) {
    return StatsCardWidget(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      color: color,
      isLoading: true,
      onTap: () {}, // Pas d'action si pas de contrôleur
    );
  }
}
