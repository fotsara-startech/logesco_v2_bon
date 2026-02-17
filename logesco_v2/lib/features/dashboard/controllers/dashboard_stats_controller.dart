import 'package:get/get.dart';

/// Contrôleur pour gérer les statistiques du dashboard
class DashboardStatsController extends GetxController {
  // Statistiques observables
  final RxString todaySales = '0'.obs;
  final RxString todaySalesCount = '0'.obs;
  final RxString totalProducts = '0'.obs;
  final RxString totalCategories = '0'.obs;
  final RxString activeCustomers = '0'.obs;
  final RxString newCustomersThisMonth = '0'.obs;
  final RxString monthlyExpenses = '0'.obs;
  final RxString monthlyExpensesCount = '0'.obs;
  final RxString stockValue = '0'.obs;
  final RxString totalSuppliers = '0'.obs;
  final RxString pendingOrders = '0'.obs;
  final RxString clientCredits = '0'.obs;
  final RxString openCashRegisters = '0'.obs;
  final RxString activeCashRegisters = '0'.obs;

  // Tendances (pourcentages)
  final RxString salesTrend = '0%'.obs;
  final RxString productsTrend = '0%'.obs;
  final RxString customersTrend = '0%'.obs;
  final RxString expensesTrend = '0%'.obs;
  final RxString stockTrend = '0%'.obs;
  final RxString creditsTrend = '0%'.obs;

  // État de chargement
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllStats();
  }

  /// Charge toutes les statistiques
  Future<void> loadAllStats() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Charger les statistiques en parallèle
      await Future.wait([
        _loadSalesStats(),
        _loadProductsStats(),
        _loadCustomersStats(),
        _loadFinancialStats(),
        _loadStockStats(),
        _loadSuppliersStats(),
        _loadAccountsStats(),
        _loadCashStats(),
      ]);
    } catch (e) {
      error.value = 'Erreur lors du chargement des statistiques: $e';
      print('❌ Erreur dashboard stats: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge les statistiques des ventes
  Future<void> _loadSalesStats() async {
    try {
      // TODO: Connecter à l'API des ventes
      await Future.delayed(const Duration(milliseconds: 500)); // Simulation

      todaySales.value = '125,000';
      todaySalesCount.value = '15';
      salesTrend.value = '+12%';
    } catch (e) {
      print('❌ Erreur stats ventes: $e');
    }
  }

  /// Charge les statistiques des produits
  Future<void> _loadProductsStats() async {
    try {
      // TODO: Connecter à l'API des produits
      await Future.delayed(const Duration(milliseconds: 300));

      totalProducts.value = '1,247';
      totalCategories.value = '23';
      productsTrend.value = '+5%';
    } catch (e) {
      print('❌ Erreur stats produits: $e');
    }
  }

  /// Charge les statistiques des clients
  Future<void> _loadCustomersStats() async {
    try {
      // TODO: Connecter à l'API des clients
      await Future.delayed(const Duration(milliseconds: 400));

      activeCustomers.value = '89';
      newCustomersThisMonth.value = '12';
      customersTrend.value = '+8%';
    } catch (e) {
      print('❌ Erreur stats clients: $e');
    }
  }

  /// Charge les statistiques financières
  Future<void> _loadFinancialStats() async {
    try {
      // TODO: Connecter à l'API financière
      await Future.delayed(const Duration(milliseconds: 600));

      monthlyExpenses.value = '45,000';
      monthlyExpensesCount.value = '67';
      expensesTrend.value = '-3%';
    } catch (e) {
      print('❌ Erreur stats financières: $e');
    }
  }

  /// Charge les statistiques du stock
  Future<void> _loadStockStats() async {
    try {
      // TODO: Connecter à l'API du stock
      await Future.delayed(const Duration(milliseconds: 350));

      stockValue.value = '2.1M';
      stockTrend.value = '+15%';
    } catch (e) {
      print('❌ Erreur stats stock: $e');
    }
  }

  /// Charge les statistiques des fournisseurs
  Future<void> _loadSuppliersStats() async {
    try {
      // TODO: Connecter à l'API des fournisseurs
      await Future.delayed(const Duration(milliseconds: 250));

      totalSuppliers.value = '24';
      pendingOrders.value = '3';
    } catch (e) {
      print('❌ Erreur stats fournisseurs: $e');
    }
  }

  /// Charge les statistiques des comptes
  Future<void> _loadAccountsStats() async {
    try {
      // TODO: Connecter à l'API des comptes
      await Future.delayed(const Duration(milliseconds: 450));

      clientCredits.value = '78,500';
      creditsTrend.value = '-5%';
    } catch (e) {
      print('❌ Erreur stats comptes: $e');
    }
  }

  /// Charge les statistiques des caisses
  Future<void> _loadCashStats() async {
    try {
      // TODO: Connecter à l'API des caisses
      await Future.delayed(const Duration(milliseconds: 200));

      openCashRegisters.value = '3';
      activeCashRegisters.value = '2';
    } catch (e) {
      print('❌ Erreur stats caisses: $e');
    }
  }

  /// Rafraîchit toutes les statistiques
  Future<void> refreshStats() async {
    await loadAllStats();
  }

  /// Formate un nombre avec des séparateurs
  String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Génère une tendance aléatoire pour les tests
  String generateRandomTrend() {
    final trends = ['+5%', '+12%', '-3%', '+8%', '+15%', '-2%', '+7%'];
    trends.shuffle();
    return trends.first;
  }
}
