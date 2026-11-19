import 'package:get/get.dart';
import '../models/financial_balance.dart';
import '../services/accounting_service.dart';
import '../services/accounting_export_service.dart';
import '../../../core/services/auth_service.dart';
import '../../boutiques/controllers/boutique_controller.dart';
import '../../../core/utils/snackbar_helper.dart';

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
    loadFinancialBalance();

    // Réagir aux changements de boutique active
    ever(Get.find<BoutiqueController>().boutiquesActive, (_) => refreshAllData());
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
      print('');
      if (selectedCategoryId.value != null) {
        print('   Filtre catégorie: ${selectedCategoryId.value}');
      }

      final balance = await _accountingService.calculateFinancialBalance(
        startDate: startDate.value!,
        endDate: endDate.value!,
        categoryId: selectedCategoryId.value,
      );

      currentBalance.value = balance;
      print(' Bilan chargé: ${balance.totalRevenue} FCFA de revenus, ${balance.totalExpenses} FCFA de dépenses');

      // Charger aussi les KPI
      await loadKPIs();
    } catch (e) {
      SnackbarHelper.error('accounting_impossible_charger_bilan_financier'.trParams({'toString': '${e.toString()}'}));
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge les catégories de produits
  Future<void> loadProductCategories() async {
    try {
      final categories = await _accountingService.getProductCategories();
      productCategories.assignAll(categories);
      print(' ${categories.length} catégories de produits chargées');
    } catch (e) {
      print(' Erreur lors du chargement des catégories: $e');
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
      print(' Erreur lors du chargement du résumé: $e');
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
      print(' Erreur lors du chargement des KPI: $e');
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

  /// Exporte le bilan en PDF
  Future<void> exportToPdf() async {
    if (currentBalance.value == null) {
      SnackbarHelper.warning('accounting_aucune_donnee_exporter_chargez_bilan_abord'.tr);
      return;
    }
    try {
      final boutiqueName = Get.find<BoutiqueController>().boutiquesActive.value?.nom;
      await AccountingExportService.exportToPdf(
        balance: currentBalance.value!,
        boutiqueName: boutiqueName,
      );
    } catch (e) {
      SnackbarHelper.error('accounting_erreur_lors_generation_pdf'.trParams({'e': '${e}'}));
    }
  }

  /// Exporte le bilan en Excel
  Future<void> exportToExcel() async {
    if (currentBalance.value == null) {
      SnackbarHelper.warning('accounting_aucune_donnee_exporter_chargez_bilan_abord'.tr);
      return;
    }
    try {
      final boutiqueName = Get.find<BoutiqueController>().boutiquesActive.value?.nom;
      final path = await AccountingExportService.exportToExcel(
        balance: currentBalance.value!,
        boutiqueName: boutiqueName,
      );
      if (path != null) {
        SnackbarHelper.success('accounting_fichier_excel_genere_avec_succes'.tr);
      }
    } catch (e) {
      SnackbarHelper.error('accounting_erreur_lors_generation_fichier_excel'.trParams({'e': '${e}'}));
    }
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
    if (!hasPeriodSelected) return 'accounting_aucune_periode_selectionnee'.tr;

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
        return 'sales_this_week'.tr;
      case PredefinedPeriod.lastWeek:
        return 'sales_last_week'.tr;
      case PredefinedPeriod.thisMonth:
        return 'analytics_this_month'.tr;
      case PredefinedPeriod.lastMonth:
        return 'Mois dernier';
      case PredefinedPeriod.thisQuarter:
        return 'reports_period_this_quarter'.tr;
      case PredefinedPeriod.thisYear:
        return 'analytics_this_year'.tr;
    }
  }
}
