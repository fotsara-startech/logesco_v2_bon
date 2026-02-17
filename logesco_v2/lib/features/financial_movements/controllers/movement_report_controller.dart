import 'package:get/get.dart';
import '../models/loading_state.dart';
import '../services/movement_report_service.dart';
import '../services/financial_report_pdf_service.dart';
import '../utils/financial_error_handler.dart';

/// Contrôleur pour la gestion des rapports de mouvements financiers
class MovementReportController extends GetxController with LoadingStateMixin {
  final MovementReportService _reportService = Get.find<MovementReportService>();

  // État observable
  final RxBool isLoading = false.obs;
  final RxBool isGeneratingReport = false.obs;
  final RxBool isExporting = false.obs;
  final RxString error = ''.obs;

  // États de chargement spécifiques
  final RxBool isLoadingSummary = false.obs;
  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingDaily = false.obs;

  // Données des rapports
  final Rx<MovementSummary?> currentSummary = Rx<MovementSummary?>(null);
  final RxList<CategorySummary> categorySummaries = <CategorySummary>[].obs;
  final RxList<DailySummary> dailySummaries = <DailySummary>[].obs;
  final Rx<MovementReport?> currentReport = Rx<MovementReport?>(null);

  // Paramètres de période
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  // Paramètres pour la comparaison de périodes
  final Rx<DateTime?> comparisonStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> comparisonEndDate = Rx<DateTime?>(null);
  final Rx<PeriodComparison?> currentComparison = Rx<PeriodComparison?>(null);
  final RxBool isLoadingComparison = false.obs;

  // Filtres pour les rapports
  final RxList<int> selectedCategoryIds = <int>[].obs;
  final RxBool includeDetails = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialise avec la période du mois en cours
    _initializeDefaultPeriod();
  }

  /// Initialise la période par défaut (mois en cours)
  void _initializeDefaultPeriod() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = DateTime(now.year, now.month + 1, 0);
  }

  /// Charge le résumé pour la période sélectionnée
  Future<void> loadSummary({bool forceRefresh = false}) async {
    if (startDate.value == null || endDate.value == null) {
      error.value = 'Veuillez sélectionner une période';
      setError(
        message: 'Veuillez sélectionner une période',
        operation: 'loadSummary',
      );
      return;
    }

    await executeWithLoadingState<void>(
      () async {
        isLoadingSummary.value = true;
        isLoading.value = true;

        final summary = await _reportService.getSummary(
          startDate.value!,
          endDate.value!,
        );

        currentSummary.value = summary;
        isLoadingSummary.value = false;
        isLoading.value = false;
        print('✅ Résumé chargé avec succès');
      },
      loadingState: LoadingState.loading(
        message: 'Chargement du résumé...',
        operation: 'loadSummary',
      ),
      successMessage: null, // Pas de message de succès pour éviter le spam
      errorMessage: 'Erreur lors du chargement du résumé',
      autoResetAfterSuccess: true,
    ).catchError((e) {
      isLoadingSummary.value = false;
      isLoading.value = false;

      if (e is Exception) {
        error.value = e.toString().replaceFirst('Exception: ', '');
      } else {
        error.value = 'Erreur lors du chargement du résumé';
      }

      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: error.value,
          code: 'LOAD_SUMMARY_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        ),
        operation: 'loadSummary',
      );
      print('❌ Erreur chargement résumé: ${error.value}');
    });
  }

  /// Charge les statistiques par catégorie
  Future<void> loadCategorySummaries({bool forceRefresh = false}) async {
    if (startDate.value == null || endDate.value == null) {
      error.value = 'Veuillez sélectionner une période';
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      final summaries = await _reportService.getCategorySummary(
        startDate.value!,
        endDate.value!,
      );

      categorySummaries.value = summaries;
      print('✅ Résumés par catégorie chargés avec succès');
    } on Exception catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: error.value,
          code: 'LOAD_CATEGORY_SUMMARIES_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        ),
        operation: 'loadCategorySummaries',
      );
      print('❌ Erreur chargement résumés catégories: ${error.value}');
    } catch (e) {
      error.value = 'Erreur lors du chargement des statistiques par catégorie';
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: e.toString(),
          code: 'LOAD_CATEGORY_SUMMARIES_UNKNOWN_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.unknownError,
        ),
        operation: 'loadCategorySummaries',
      );
      print('❌ Erreur inconnue chargement résumés catégories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge les statistiques quotidiennes
  Future<void> loadDailySummaries({bool forceRefresh = false}) async {
    if (startDate.value == null || endDate.value == null) {
      error.value = 'Veuillez sélectionner une période';
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      final summaries = await _reportService.getDailySummary(
        startDate.value!,
        endDate.value!,
      );

      dailySummaries.value = summaries;
      print('✅ Résumés quotidiens chargés avec succès');
    } on Exception catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: error.value,
          code: 'LOAD_DAILY_SUMMARIES_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        ),
        operation: 'loadDailySummaries',
      );
      print('❌ Erreur chargement résumés quotidiens: ${error.value}');
    } catch (e) {
      error.value = 'Erreur lors du chargement des statistiques quotidiennes';
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: e.toString(),
          code: 'LOAD_DAILY_SUMMARIES_UNKNOWN_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.unknownError,
        ),
        operation: 'loadDailySummaries',
      );
      print('❌ Erreur inconnue chargement résumés quotidiens: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Génère un rapport complet
  Future<void> generateCompleteReport() async {
    if (startDate.value == null || endDate.value == null) {
      error.value = 'Veuillez sélectionner une période';
      return;
    }

    try {
      isGeneratingReport.value = true;
      error.value = '';

      final report = await _reportService.generateCompleteReport(
        startDate.value!,
        endDate.value!,
      );

      currentReport.value = report;

      // Met à jour les données individuelles aussi
      currentSummary.value = report.summary;
      categorySummaries.value = report.categorySummaries;
      dailySummaries.value = report.dailySummaries;

      print('✅ Rapport complet généré avec succès');
    } on Exception catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: error.value,
          code: 'GENERATE_REPORT_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        ),
        operation: 'generateCompleteReport',
      );
      print('❌ Erreur génération rapport: ${error.value}');
    } catch (e) {
      error.value = 'Erreur lors de la génération du rapport';
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: e.toString(),
          code: 'GENERATE_REPORT_UNKNOWN_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.unknownError,
        ),
        operation: 'generateCompleteReport',
      );
      print('❌ Erreur inconnue génération rapport: $e');
    } finally {
      isGeneratingReport.value = false;
    }
  }

  /// Exporte le rapport au format PDF (génération locale)
  Future<String?> exportToPdf({String? customTitle}) async {
    if (startDate.value == null || endDate.value == null) {
      error.value = 'Veuillez sélectionner une période';
      setError(
        message: 'Veuillez sélectionner une période',
        operation: 'exportToPdf',
      );
      return null;
    }

    try {
      isExporting.value = true;
      error.value = '';

      // Vérifier que nous avons les données nécessaires
      if (currentSummary.value == null) {
        await loadSummary();
      }
      if (categorySummaries.isEmpty) {
        await loadCategorySummaries();
      }
      if (dailySummaries.isEmpty) {
        await loadDailySummaries();
      }

      // Vérifier à nouveau après le chargement
      if (currentSummary.value == null) {
        throw Exception('Impossible de charger les données du résumé');
      }

      print('📄 Génération PDF du rapport financier...');

      // Générer et imprimer le PDF localement
      await FinancialReportPdfService.printFinancialReport(
        startDate: startDate.value!,
        endDate: endDate.value!,
        summary: currentSummary.value!,
        categorySummaries: categorySummaries.toList(),
        dailySummaries: dailySummaries.toList(),
      );

      isExporting.value = false;
      print('✅ PDF généré et ouvert avec succès');

      // Retourner un message de succès au lieu d'un chemin de fichier
      return 'PDF généré avec succès';
    } catch (e) {
      isExporting.value = false;
      error.value = 'Erreur lors de la génération du PDF: $e';

      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: error.value,
          code: 'EXPORT_PDF_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        ),
        operation: 'exportToPdf',
      );

      print('❌ Erreur export PDF: ${error.value}');
      return null;
    }
  }

  /// Exporte le rapport au format Excel
  Future<String?> exportToExcel({String? customTitle}) async {
    if (startDate.value == null || endDate.value == null) {
      error.value = 'Veuillez sélectionner une période';
      return null;
    }

    try {
      isExporting.value = true;
      error.value = '';

      final title = customTitle ?? 'Rapport Mouvements Financiers ${_formatPeriod()}';

      final request = MovementReportRequest(
        startDate: startDate.value!,
        endDate: endDate.value!,
        title: title,
        categoryIds: selectedCategoryIds.isNotEmpty ? selectedCategoryIds.toList() : null,
        includeDetails: includeDetails.value,
        format: 'excel',
      );

      final filePath = await _reportService.exportReportToExcel(request);

      print('✅ Export Excel réussi: $filePath');
      return filePath;
    } on Exception catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: error.value,
          code: 'EXPORT_EXCEL_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        ),
        operation: 'exportToExcel',
      );
      print('❌ Erreur export Excel: ${error.value}');
      return null;
    } catch (e) {
      error.value = 'Erreur lors de l\'export Excel';
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: e.toString(),
          code: 'EXPORT_EXCEL_UNKNOWN_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.unknownError,
        ),
        operation: 'exportToExcel',
      );
      print('❌ Erreur inconnue export Excel: $e');
      return null;
    } finally {
      isExporting.value = false;
    }
  }

  /// Définit la période du rapport
  void setPeriod(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;

    // Efface les données précédentes
    _clearCurrentData();
  }

  /// Définit une période prédéfinie
  void setPredefinedPeriod(String period) {
    final now = DateTime.now();

    switch (period) {
      case 'today':
        startDate.value = DateTime(now.year, now.month, now.day);
        endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        startDate.value = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate.value = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'thisWeek':
        final weekday = now.weekday;
        final startOfWeek = now.subtract(Duration(days: weekday - 1));
        startDate.value = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'lastWeek':
        final weekday = now.weekday;
        final startOfLastWeek = now.subtract(Duration(days: weekday + 6));
        final endOfLastWeek = now.subtract(Duration(days: weekday));
        startDate.value = DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day);
        endDate.value = DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day, 23, 59, 59);
        break;
      case 'thisMonth':
        startDate.value = DateTime(now.year, now.month, 1);
        endDate.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate.value = lastMonth;
        endDate.value = DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59);
        break;
      case 'thisYear':
        startDate.value = DateTime(now.year, 1, 1);
        endDate.value = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'lastYear':
        startDate.value = DateTime(now.year - 1, 1, 1);
        endDate.value = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      default:
        _initializeDefaultPeriod();
    }

    // Efface les données précédentes
    _clearCurrentData();
  }

  /// Ajoute ou retire une catégorie des filtres
  void toggleCategoryFilter(int categoryId) {
    if (selectedCategoryIds.contains(categoryId)) {
      selectedCategoryIds.remove(categoryId);
    } else {
      selectedCategoryIds.add(categoryId);
    }
  }

  /// Efface tous les filtres de catégories
  void clearCategoryFilters() {
    selectedCategoryIds.clear();
  }

  /// Bascule l'inclusion des détails
  void toggleIncludeDetails() {
    includeDetails.value = !includeDetails.value;
  }

  /// Charge toutes les données du rapport
  Future<void> loadAllReportData() async {
    await Future.wait([
      loadSummary(),
      loadCategorySummaries(),
      loadDailySummaries(),
    ]);
  }

  /// Rafraîchit toutes les données du rapport
  Future<void> refreshAllReportData() async {
    await Future.wait([
      loadSummary(forceRefresh: true),
      loadCategorySummaries(forceRefresh: true),
      loadDailySummaries(forceRefresh: true),
    ]);
  }

  /// Compare deux périodes
  Future<void> comparePeriods() async {
    if (startDate.value == null || endDate.value == null || comparisonStartDate.value == null || comparisonEndDate.value == null) {
      error.value = 'Veuillez sélectionner les deux périodes à comparer';
      setError(
        message: 'Veuillez sélectionner les deux périodes à comparer',
        operation: 'comparePeriods',
      );
      return;
    }

    await executeWithLoadingState<void>(
      () async {
        isLoadingComparison.value = true;

        final comparison = await _reportService.comparePeriods(
          startDate.value!,
          endDate.value!,
          comparisonStartDate.value!,
          comparisonEndDate.value!,
        );

        currentComparison.value = comparison;
        isLoadingComparison.value = false;
        print('✅ Comparaison de périodes générée avec succès');
      },
      loadingState: LoadingState.loading(
        message: 'Comparaison des périodes en cours...',
        operation: 'comparePeriods',
      ),
      successMessage: 'Comparaison générée avec succès',
      errorMessage: 'Erreur lors de la comparaison des périodes',
      autoResetAfterSuccess: true,
    ).catchError((e) {
      isLoadingComparison.value = false;

      if (e is Exception) {
        error.value = e.toString().replaceFirst('Exception: ', '');
      } else {
        error.value = 'Erreur lors de la comparaison des périodes';
      }

      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: error.value,
          code: 'COMPARE_PERIODS_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.serverError,
        ),
        operation: 'comparePeriods',
      );
      print('❌ Erreur comparaison périodes: ${error.value}');
    });
  }

  /// Définit la période de comparaison
  void setComparisonPeriod(DateTime start, DateTime end) {
    comparisonStartDate.value = start;
    comparisonEndDate.value = end;

    // Efface la comparaison précédente
    currentComparison.value = null;
  }

  /// Définit une période de comparaison prédéfinie basée sur la période principale
  void setComparisonPredefinedPeriod(String period) {
    if (startDate.value == null || endDate.value == null) {
      error.value = 'Veuillez d\'abord sélectionner la période principale';
      return;
    }

    final mainStart = startDate.value!;
    final mainEnd = endDate.value!;
    final periodDuration = mainEnd.difference(mainStart);

    switch (period) {
      case 'previous':
        // Période précédente de même durée
        comparisonEndDate.value = mainStart.subtract(const Duration(days: 1));
        comparisonStartDate.value = comparisonEndDate.value!.subtract(periodDuration);
        break;
      case 'previousMonth':
        // Mois précédent
        final previousMonth = DateTime(mainStart.year, mainStart.month - 1, 1);
        comparisonStartDate.value = previousMonth;
        comparisonEndDate.value = DateTime(previousMonth.year, previousMonth.month + 1, 0);
        break;
      case 'previousYear':
        // Même période l'année précédente
        comparisonStartDate.value = DateTime(mainStart.year - 1, mainStart.month, mainStart.day);
        comparisonEndDate.value = DateTime(mainEnd.year - 1, mainEnd.month, mainEnd.day);
        break;
      case 'previousQuarter':
        // Trimestre précédent
        final currentQuarter = ((mainStart.month - 1) ~/ 3) + 1;
        final previousQuarter = currentQuarter == 1 ? 4 : currentQuarter - 1;
        final previousQuarterYear = currentQuarter == 1 ? mainStart.year - 1 : mainStart.year;
        final quarterStartMonth = (previousQuarter - 1) * 3 + 1;

        comparisonStartDate.value = DateTime(previousQuarterYear, quarterStartMonth, 1);
        comparisonEndDate.value = DateTime(previousQuarterYear, quarterStartMonth + 3, 0);
        break;
      default:
        // Période précédente par défaut
        comparisonEndDate.value = mainStart.subtract(const Duration(days: 1));
        comparisonStartDate.value = comparisonEndDate.value!.subtract(periodDuration);
    }

    // Efface la comparaison précédente
    currentComparison.value = null;
  }

  /// Échange les périodes principale et de comparaison
  void swapPeriods() {
    final tempStart = startDate.value;
    final tempEnd = endDate.value;

    startDate.value = comparisonStartDate.value;
    endDate.value = comparisonEndDate.value;

    comparisonStartDate.value = tempStart;
    comparisonEndDate.value = tempEnd;

    // Efface les données précédentes
    _clearCurrentData();
    currentComparison.value = null;
  }

  /// Efface les données actuelles
  void _clearCurrentData() {
    currentSummary.value = null;
    categorySummaries.clear();
    dailySummaries.clear();
    currentReport.value = null;
    currentComparison.value = null;
    error.value = '';
  }

  /// Formate la période pour l'affichage
  String _formatPeriod() {
    if (startDate.value == null || endDate.value == null) {
      return '';
    }

    final start = startDate.value!;
    final end = endDate.value!;

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  /// Formate la période de comparaison pour l'affichage
  String _formatComparisonPeriod() {
    if (comparisonStartDate.value == null || comparisonEndDate.value == null) {
      return '';
    }

    final start = comparisonStartDate.value!;
    final end = comparisonEndDate.value!;

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  /// Obtient la période formatée
  String get formattedPeriod => _formatPeriod();

  /// Obtient la période de comparaison formatée
  String get formattedComparisonPeriod => _formatComparisonPeriod();

  /// Vérifie si une période est sélectionnée
  bool get hasPeriodSelected => startDate.value != null && endDate.value != null;

  /// Vérifie si une période de comparaison est sélectionnée
  bool get hasComparisonPeriodSelected => comparisonStartDate.value != null && comparisonEndDate.value != null;

  /// Vérifie si les deux périodes sont sélectionnées pour la comparaison
  bool get canCompare => hasPeriodSelected && hasComparisonPeriodSelected;

  /// Vérifie si des données sont disponibles
  bool get hasData => currentSummary.value != null || categorySummaries.isNotEmpty || dailySummaries.isNotEmpty;

  /// Vérifie si une comparaison est disponible
  bool get hasComparison => currentComparison.value != null;

  /// Obtient le nombre de jours dans la période
  int get periodDayCount {
    if (startDate.value == null || endDate.value == null) return 0;
    return endDate.value!.difference(startDate.value!).inDays + 1;
  }

  /// Obtient les statistiques de base
  Map<String, dynamic> get basicStats {
    final summary = currentSummary.value;
    if (summary == null) return {};

    return {
      'totalAmount': summary.totalAmountFormatted,
      'totalCount': summary.totalCount,
      'averageAmount': summary.averageAmountFormatted,
      'periodDays': periodDayCount,
      'dailyAverage': periodDayCount > 0 ? '${(summary.totalAmount / periodDayCount).toStringAsFixed(2)} FCFA' : '0 FCFA',
    };
  }

  /// Réinitialise le contrôleur
  void reset() {
    _initializeDefaultPeriod();
    _clearCurrentData();
    clearCategoryFilters();
    includeDetails.value = true;
    comparisonStartDate.value = null;
    comparisonEndDate.value = null;
  }
}
