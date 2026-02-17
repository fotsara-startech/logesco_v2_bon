import 'package:get/get.dart';
import '../../../core/api/api_client.dart';

/// Service pour récupérer les statistiques du dashboard
class DashboardStatsService extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Récupérer les statistiques générales
  Future<Map<String, dynamic>> getGeneralStats() async {
    try {
      print('📊 [DashboardStatsService] Récupération des statistiques générales...');
      final response = await _apiClient.get<Map<String, dynamic>>('/dashboard/stats');

      if (response.isSuccess && response.data != null) {
        final stats = response.data!['data'] ?? {};
        print('✅ [DashboardStatsService] Statistiques reçues: $stats');
        return stats;
      }

      print('⚠️ [DashboardStatsService] API non disponible, utilisation des données par défaut');
      return _getDefaultStats();
    } catch (e) {
      print('❌ [DashboardStatsService] Erreur récupération stats: $e');
      return _getDefaultStats();
    }
  }

  /// Récupérer les statistiques des ventes
  Future<Map<String, dynamic>> getSalesStats() async {
    try {
      print('💰 [DashboardStatsService] Récupération des statistiques de ventes...');
      final response = await _apiClient.get<Map<String, dynamic>>('/dashboard/sales-stats');

      if (response.isSuccess && response.data != null) {
        final stats = response.data!['data'] ?? {};
        print('✅ [DashboardStatsService] Stats ventes reçues: $stats');
        return stats;
      }

      print('⚠️ [DashboardStatsService] API ventes non disponible, utilisation des données par défaut');
      return _getDefaultSalesStats();
    } catch (e) {
      print('❌ [DashboardStatsService] Erreur récupération stats ventes: $e');
      return _getDefaultSalesStats();
    }
  }

  /// Récupérer les activités récentes
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/dashboard/recent-activities');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> activities = response.data!['data'] ?? [];
        return activities.cast<Map<String, dynamic>>();
      }

      return _getDefaultActivities();
    } catch (e) {
      print('❌ [DashboardStatsService] Erreur récupération activités: $e');
      return _getDefaultActivities();
    }
  }

  /// Récupérer les données du graphique des ventes
  Future<List<Map<String, dynamic>>> getSalesChartData() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/dashboard/sales-chart');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> chartData = response.data!['data'] ?? [];
        return chartData.cast<Map<String, dynamic>>();
      }

      return _getDefaultChartData();
    } catch (e) {
      print('❌ [DashboardStatsService] Erreur récupération graphique: $e');
      return _getDefaultChartData();
    }
  }

  /// Données par défaut pour les statistiques générales
  Map<String, dynamic> _getDefaultStats() {
    return {
      'totalProducts': 0,
      'totalUsers': 1, // Au moins l'admin
      'totalSales': 0,
      'totalRevenue': 0.0,
      'activeUsers': 1,
      'pendingOrders': 0,
      'lowStockProducts': 0,
      'monthlyGrowth': 0.0,
    };
  }

  /// Données par défaut pour les statistiques de ventes
  Map<String, dynamic> _getDefaultSalesStats() {
    return {
      'todaySales': 0,
      'todayRevenue': 0.0,
      'weekSales': 0,
      'weekRevenue': 0.0,
      'monthSales': 0,
      'monthRevenue': 0.0,
      'topProducts': <Map<String, dynamic>>[],
    };
  }

  /// Activités par défaut
  List<Map<String, dynamic>> _getDefaultActivities() {
    return [
      {
        'id': 1,
        'type': 'system',
        'title': 'Système initialisé',
        'description': 'L\'application a été configurée avec succès',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'icon': 'system',
        'color': 'blue',
      },
      {
        'id': 2,
        'type': 'user',
        'title': 'Utilisateur admin créé',
        'description': 'Compte administrateur configuré automatiquement',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        'icon': 'user',
        'color': 'green',
      },
    ];
  }

  /// Données par défaut pour le graphique
  List<Map<String, dynamic>> _getDefaultChartData() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return {
        'date': date.toIso8601String().split('T')[0],
        'sales': 0,
        'revenue': 0.0,
      };
    });
  }
}
