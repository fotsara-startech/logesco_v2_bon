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
        final raw = response.data!['data'] ?? {};
        final stats = Map<String, dynamic>.from(raw as Map);
        print('✅ [DashboardStatsService] Statistiques reçues: $stats');
        return {
          'totalProducts': (stats['totalProducts'] as num? ?? 0).toInt(),
          'totalUsers': (stats['totalUsers'] as num? ?? 0).toInt(),
          'activeUsers': (stats['activeUsers'] as num? ?? 0).toInt(),
          'totalSales': (stats['totalSales'] as num? ?? 0).toInt(),
          'totalRevenue': (stats['totalRevenue'] as num? ?? 0).toDouble(),
          'pendingOrders': (stats['pendingOrders'] as num? ?? 0).toInt(),
          'lowStockProducts': (stats['lowStockProducts'] as num? ?? 0).toInt(),
          'monthlyGrowth': (stats['monthlyGrowth'] as num? ?? 0).toDouble(),
        };
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
        final raw = response.data!['data'] ?? {};
        // Normaliser les valeurs numériques pour éviter les erreurs de cast int/double
        final stats = Map<String, dynamic>.from(raw as Map);
        return {
          'todaySales': stats['todaySales'] ?? 0,
          'todayRevenue': (stats['todayRevenue'] as num? ?? 0).toDouble(),
          'weekSales': stats['weekSales'] ?? 0,
          'weekRevenue': (stats['weekRevenue'] as num? ?? 0).toDouble(),
          'monthSales': stats['monthSales'] ?? 0,
          'monthRevenue': (stats['monthRevenue'] as num? ?? 0).toDouble(),
          'topProducts': stats['topProducts'] ?? <Map<String, dynamic>>[],
        };
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
        final List<dynamic> rawList = response.data!['data'] ?? [];
        return rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
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
        final List<dynamic> rawList = response.data!['data'] ?? [];
        // Normaliser chaque entrée pour éviter les erreurs de cast
        return rawList.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return {
            'date': m['date']?.toString() ?? '',
            'sales': (m['sales'] as num? ?? 0).toInt(),
            'revenue': (m['revenue'] as num? ?? 0).toDouble(),
          };
        }).toList();
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
