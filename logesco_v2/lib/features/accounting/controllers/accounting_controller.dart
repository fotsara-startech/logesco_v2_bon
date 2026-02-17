import 'package:get/get.dart';
import '../models/financial_balance.dart';
import '../services/accounting_service.dart';
import '../../../core/services/auth_service.dart';

/// Contrôleur pour la gestion de la comptabilité et des bilans financiers
class AccountingController extends GetxController {
  final AccountingService _accountingService = AccountingService(Get.find<AuthService>());

  // États observables
  final isLoading = false.obs;
  final currentBalance = Rxn<FinancialBalance>();
  final quickSummary = <String, dynamic>{}.obs;
  final kpiIndicators = Rxn<KPIIndicators>();

  // Période sélectionnée
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  // Filtre par catégorie de produit
  final selectedCategoryId = Rxn<int>();
  final productCategories = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDefaultPeriod();
    loadProductCategories();
    loadQuickSummary();
    // Charger le bilan pour la période par défaut
    loadFinancialBalance();
  }

  /// Initialise la période par défaut (mois en cours)
  void _initializeDefaultPeriod() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = DateTime(now.year, now.month + 1, 0);
  }

  /// Charge le bilan financier pour la période sélectionnée
  Future<void> loadFinancialBalance() async {
    if (startDate.value == null || endDate.value == null) {
      print('⚠️ Période non définie pour le chargement du bilan');
      return;
    }

    try {
      isLoading.value = true;
      print('📊 Chargement du bilan pour la période: ${periodFormatted}');
      if (selectedCategoryId.value != null) {
        print('   Filtre catégorie: ${selectedCategoryId.value}');
      }

      final balance = await _accountingService.calculateFinancialBalance(
        startDate: startDate.value!,
        endDate: endDate.value!,
        categoryId: selectedCategoryId.value,
      );

      currentBalance.value = balance;
      print('✅ Bilan chargé: ${balance.totalRevenue} FCFA de revenus, ${balance.totalExpenses} FCFA de dépenses');

      // Charger aussi les KPI
      await loadKPIs();
    } catch (e) {
      print('❌ Erreur lors du chargement du bilan: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger le bilan financier: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge les catégories de produits
  Future<void> loadProductCategories() async {
    try {
      final categories = await _accountingService.getProductCategories();
      productCategories.assignAll(categories);
      print('✅ ${categories.length} catégories de produits chargées');
    } catch (e) {
      print('❌ Erreur lors du chargement des catégories: $e');
    }
  }

  /// Définit le filtre de catégorie
  void setCategoryFilter(int? categoryId) {
    selectedCategoryId.value = categoryId;
    loadFinancialBalance();
  }

  /// Charge le résumé rapide de rentabilité
  Future<void> loadQuickSummary() async {
    try {
      final summary = await _accountingService.getQuickProfitabilitySummary();
      quickSummary.value = summary;
    } catch (e) {
      print('❌ Erreur lors du chargement du résumé: $e');
    }
  }

  /// Charge les indicateurs KPI
  Future<void> loadKPIs({double? initialInvestment}) async {
    if (startDate.value == null || endDate.value == null) return;

    try {
      final kpis = await _accountingService.calculateKPIs(
        startDate: startDate.value!,
        endDate: endDate.value!,
        initialInvestment: initialInvestment,
      );

      kpiIndicators.value = kpis;
    } catch (e) {
      print('❌ Erreur lors du chargement des KPI: $e');
    }
  }

  /// Définit une période prédéfinie
  void setPredefinedPeriod(PredefinedPeriod period) {
    final now = DateTime.now();

    switch (period) {
      case PredefinedPeriod.today:
        startDate.value = DateTime(now.year, now.month, now.day);
        endDate.value = DateTime(now.year, now.month, now.day);
        break;

      case PredefinedPeriod.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        startDate.value = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate.value = DateTime(yesterday.year, yesterday.month, yesterday.day);
        break;

      case PredefinedPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate.value = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate.value = DateTime(now.year, now.month, now.day);
        break;

      case PredefinedPeriod.lastWeek:
        final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
        final endOfLastWeek = now.subtract(Duration(days: now.weekday));
        startDate.value = DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day);
        endDate.value = DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day);
        break;

      case PredefinedPeriod.thisMonth:
        startDate.value = DateTime(now.year, now.month, 1);
        endDate.value = DateTime(now.year, now.month + 1, 0);
        break;

      case PredefinedPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate.value = lastMonth;
        endDate.value = DateTime(now.year, now.month, 0);
        break;

      case PredefinedPeriod.thisQuarter:
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        startDate.value = quarterStart;
        endDate.value = DateTime(now.year, now.month, now.day);
        break;

      case PredefinedPeriod.thisYear:
        startDate.value = DateTime(now.year, 1, 1);
        endDate.value = DateTime(now.year, now.month, now.day);
        break;
    }
  }

  /// Actualise toutes les données
  Future<void> refreshAllData() async {
    await Future.wait([
      loadFinancialBalance(),
      loadQuickSummary(),
    ]);
  }

  /// Vérifie si une période est sélectionnée
  bool get hasPeriodSelected => startDate.value != null && endDate.value != null;

  /// Vérifie si des données sont disponibles
  bool get hasData => currentBalance.value != null;

  /// Obtient le nombre de jours dans la période
  int get periodDays {
    if (!hasPeriodSelected) return 0;
    return endDate.value!.difference(startDate.value!).inDays + 1;
  }

  /// Formate la période sélectionnée
  String get periodFormatted {
    if (!hasPeriodSelected) return 'Aucune période sélectionnée';

    final start = startDate.value!;
    final end = endDate.value!;

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  /// Obtient la couleur du statut de rentabilité
  String get profitabilityColor {
    final summary = quickSummary;
    return summary['statusColor'] ?? '#6B7280';
  }

  /// Obtient le message de statut de rentabilité
  String get profitabilityMessage {
    final summary = quickSummary;
    return summary['statusMessage'] ?? 'Statut inconnu';
  }

  /// Vérifie si l'activité est rentable
  bool get isProfitable {
    final summary = quickSummary;
    return summary['isProfitable'] ?? false;
  }
}

/// Périodes prédéfinies pour l'analyse
enum PredefinedPeriod {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisQuarter,
  thisYear,
}

/// Extension pour obtenir le libellé des périodes
extension PredefinedPeriodExtension on PredefinedPeriod {
  String get label {
    switch (this) {
      case PredefinedPeriod.today:
        return 'Aujourd\'hui';
      case PredefinedPeriod.yesterday:
        return 'Hier';
      case PredefinedPeriod.thisWeek:
        return 'Cette semaine';
      case PredefinedPeriod.lastWeek:
        return 'Semaine dernière';
      case PredefinedPeriod.thisMonth:
        return 'Ce mois';
      case PredefinedPeriod.lastMonth:
        return 'Mois dernier';
      case PredefinedPeriod.thisQuarter:
        return 'Ce trimestre';
      case PredefinedPeriod.thisYear:
        return 'Cette année';
    }
  }
}
