import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/discount_report.dart';
import '../services/discount_report_service.dart';

class DiscountReportController extends GetxController {
  final DiscountReportService _reportService = Get.find<DiscountReportService>();

  // Observables pour les données
  final RxBool isLoading = false.obs;
  final RxBool isLoadingVendors = false.obs;
  final RxBool isLoadingTopDiscounts = false.obs;

  final Rx<DiscountReport?> discountSummary = Rx<DiscountReport?>(null);
  final Rx<VendorDiscountReport?> vendorReport = Rx<VendorDiscountReport?>(null);
  final RxList<TopDiscount> topDiscounts = <TopDiscount>[].obs;

  // Filtres
  final RxString selectedGroupBy = 'vendeur'.obs;
  final Rx<DateTime?> dateDebut = Rx<DateTime?>(null);
  final Rx<DateTime?> dateFin = Rx<DateTime?>(null);
  final RxInt selectedVendeurId = 0.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 20.obs;

  // Contrôleurs de date
  late final TextEditingController dateDebutController;
  late final TextEditingController dateFinController;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _loadInitialData();
  }

  @override
  void onClose() {
    dateDebutController.dispose();
    dateFinController.dispose();
    super.onClose();
  }

  void _initializeControllers() {
    dateDebutController = TextEditingController();
    dateFinController = TextEditingController();
  }

  /// Charge les données initiales
  Future<void> _loadInitialData() async {
    await Future.wait([
      loadDiscountSummary(),
      loadVendorReport(),
      loadTopDiscounts(),
    ]);
  }

  /// Charge le résumé des remises
  Future<void> loadDiscountSummary() async {
    try {
      isLoading.value = true;

      final response = await _reportService.getDiscountSummary(
        groupBy: selectedGroupBy.value,
        dateDebut: dateDebut.value,
        dateFin: dateFin.value,
      );

      if (response.success && response.data != null) {
        discountSummary.value = response.data;
      } else {
        _showError('Erreur lors du chargement du résumé des remises', response.message);
      }
    } catch (e) {
      _showError('Erreur lors du chargement du résumé des remises', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge le rapport par vendeur
  Future<void> loadVendorReport() async {
    try {
      isLoadingVendors.value = true;

      final response = await _reportService.getDiscountsByVendor(
        vendeurId: selectedVendeurId.value > 0 ? selectedVendeurId.value : null,
        dateDebut: dateDebut.value,
        dateFin: dateFin.value,
        page: currentPage.value,
        limit: itemsPerPage.value,
      );

      if (response.success && response.data != null) {
        vendorReport.value = response.data;
      } else {
        _showError('Erreur lors du chargement du rapport par vendeur', response.message);
      }
    } catch (e) {
      _showError('Erreur lors du chargement du rapport par vendeur', e.toString());
    } finally {
      isLoadingVendors.value = false;
    }
  }

  /// Charge le top des remises
  Future<void> loadTopDiscounts() async {
    try {
      isLoadingTopDiscounts.value = true;

      final response = await _reportService.getTopDiscounts(
        page: 1,
        limit: 10,
      );

      if (response.success && response.data != null) {
        topDiscounts.assignAll(response.data!);
      } else {
        _showError('Erreur lors du chargement du top des remises', response.message);
      }
    } catch (e) {
      _showError('Erreur lors du chargement du top des remises', e.toString());
    } finally {
      isLoadingTopDiscounts.value = false;
    }
  }

  /// Met à jour le groupement
  void updateGroupBy(String groupBy) {
    selectedGroupBy.value = groupBy;
    loadDiscountSummary();
  }

  /// Met à jour la date de début
  void updateDateDebut(DateTime? date) {
    dateDebut.value = date;
    if (date != null) {
      dateDebutController.text = _formatDate(date);
    } else {
      dateDebutController.clear();
    }
    _refreshData();
  }

  /// Met à jour la date de fin
  void updateDateFin(DateTime? date) {
    dateFin.value = date;
    if (date != null) {
      dateFinController.text = _formatDate(date);
    } else {
      dateFinController.clear();
    }
    _refreshData();
  }

  /// Met à jour le vendeur sélectionné
  void updateSelectedVendeur(int? vendeurId) {
    selectedVendeurId.value = vendeurId ?? 0;
    loadVendorReport();
  }

  /// Efface les filtres de date
  void clearDateFilters() {
    dateDebut.value = null;
    dateFin.value = null;
    dateDebutController.clear();
    dateFinController.clear();
    _refreshData();
  }

  /// Actualise toutes les données
  Future<void> refreshAllData() async {
    await _loadInitialData();
  }

  /// Actualise les données avec les filtres actuels
  void _refreshData() {
    Future.wait([
      loadDiscountSummary(),
      loadVendorReport(),
    ]);
  }

  /// Change de page pour le rapport par vendeur
  void changePage(int page) {
    currentPage.value = page;
    loadVendorReport();
  }

  /// Formate une date pour l'affichage
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Affiche un message d'erreur
  void _showError(String title, String? message) {
    Get.snackbar(
      title,
      message ?? 'Une erreur est survenue',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      duration: const Duration(seconds: 4),
    );
  }

  /// Calcule les statistiques dérivées
  Map<String, dynamic> get summaryStats {
    final summary = discountSummary.value;
    if (summary == null) return {};

    return {
      'totalRemises': summary.totaux.totalRemises,
      'nombreRemises': summary.totaux.nombreRemises,
      'remiseMoyenne': summary.totaux.remiseMoyenneGlobale,
      'nombreGroupes': summary.groupes.length,
    };
  }

  /// Obtient les données pour le graphique en secteurs
  List<Map<String, dynamic>> get pieChartData {
    final summary = discountSummary.value;
    if (summary == null || summary.groupes.isEmpty) return [];

    return summary.groupes.map((group) {
      final percentage = summary.totaux.totalRemises > 0 ? (group.totalRemises / summary.totaux.totalRemises * 100) : 0.0;

      return {
        'label': group.groupe,
        'value': group.totalRemises,
        'percentage': percentage,
        'count': group.nombreRemises,
      };
    }).toList();
  }

  /// Obtient les données pour le graphique en barres
  List<Map<String, dynamic>> get barChartData {
    final summary = discountSummary.value;
    if (summary == null || summary.groupes.isEmpty) return [];

    return summary.groupes
        .map((group) => {
              'label': group.groupe,
              'totalRemises': group.totalRemises,
              'nombreRemises': group.nombreRemises.toDouble(),
              'remiseMoyenne': group.remiseMoyenne,
            })
        .toList();
  }

  /// Vérifie si des données sont disponibles
  bool get hasData {
    return discountSummary.value != null && discountSummary.value!.groupes.isNotEmpty;
  }

  /// Obtient le texte de la période sélectionnée
  String get selectedPeriodText {
    if (dateDebut.value == null && dateFin.value == null) {
      return 'Toutes les périodes';
    }

    final debut = dateDebut.value != null ? _formatDate(dateDebut.value!) : 'Début';
    final fin = dateFin.value != null ? _formatDate(dateFin.value!) : 'Fin';

    return 'Du $debut au $fin';
  }
}
