import 'package:get/get.dart';
import '../services/dashboard_stats_service.dart';

/// Contrôleur pour le dashboard
class DashboardController extends GetxController {
  final DashboardStatsService _statsService = Get.find<DashboardStatsService>();

  // Observables pour les statistiques
  final RxMap<String, dynamic> generalStats = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> salesStats = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> recentActivities = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> salesChartData = <Map<String, dynamic>>[].obs;

  // États de chargement
  final RxBool isLoadingStats = false.obs;
  final RxBool isLoadingSales = false.obs;
  final RxBool isLoadingActivities = false.obs;
  final RxBool isLoadingChart = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  /// Charger toutes les données du dashboard
  Future<void> loadAllData() async {
    await Future.wait([
      loadGeneralStats(),
      loadSalesStats(),
      loadRecentActivities(),
      loadSalesChart(),
    ]);
  }

  /// Charger les statistiques générales
  Future<void> loadGeneralStats() async {
    try {
      isLoadingStats.value = true;
      final stats = await _statsService.getGeneralStats();
      generalStats.value = stats;
    } catch (e) {
      print('❌ Erreur chargement stats générales: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Charger les statistiques de ventes
  Future<void> loadSalesStats() async {
    try {
      isLoadingSales.value = true;
      final stats = await _statsService.getSalesStats();
      salesStats.value = stats;
    } catch (e) {
      print('❌ Erreur chargement stats ventes: $e');
    } finally {
      isLoadingSales.value = false;
    }
  }

  /// Charger les activités récentes
  Future<void> loadRecentActivities() async {
    try {
      isLoadingActivities.value = true;
      final activities = await _statsService.getRecentActivities();
      recentActivities.value = activities;
    } catch (e) {
      print('❌ Erreur chargement activités: $e');
    } finally {
      isLoadingActivities.value = false;
    }
  }

  /// Charger les données du graphique
  Future<void> loadSalesChart() async {
    try {
      isLoadingChart.value = true;
      final chartData = await _statsService.getSalesChartData();
      salesChartData.value = chartData;
    } catch (e) {
      print('❌ Erreur chargement graphique: $e');
    } finally {
      isLoadingChart.value = false;
    }
  }

  /// Actualiser toutes les données
  Future<void> refresh() async {
    await loadAllData();
  }

  /// Obtenir le pourcentage de croissance
  double get growthPercentage {
    return (generalStats['monthlyGrowth'] ?? 0.0).toDouble();
  }

  /// Obtenir le statut de croissance (positif/négatif)
  bool get isGrowthPositive {
    return growthPercentage >= 0;
  }

  /// Obtenir la couleur selon la croissance
  String get growthColor {
    return isGrowthPositive ? 'green' : 'red';
  }

  /// Obtenir l'icône selon la croissance
  String get growthIcon {
    return isGrowthPositive ? 'trending_up' : 'trending_down';
  }
}
