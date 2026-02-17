import '../../../core/services/api_service.dart';
import '../models/product_analytics.dart';

class AnalyticsService {
  final ApiService _apiService;

  AnalyticsService(this._apiService);

  /// Récupère l'analyse des ventes par produit
  Future<ProductAnalyticsResponse> getProductAnalytics({
    String? dateDebut,
    String? dateFin,
    int? categorieId,
    int limit = 50,
    bool includeServices = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'includeServices': includeServices.toString(),
      };

      if (dateDebut != null) {
        queryParams['dateDebut'] = dateDebut;
      }
      if (dateFin != null) {
        queryParams['dateFin'] = dateFin;
      }
      if (categorieId != null) {
        queryParams['categorieId'] = categorieId;
      }

      final response = await _apiService.get(
        '/sales/analytics/products',
        queryParams: queryParams.map((key, value) => MapEntry(key, value.toString())),
      );

      if (response.success) {
        return ProductAnalyticsResponse.fromJson(response.data);
      } else {
        throw Exception(response.message ?? 'Erreur lors de la récupération des analytics');
      }
    } catch (e) {
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Récupère l'analyse des ventes par produit pour une période prédéfinie
  Future<ProductAnalyticsResponse> getProductAnalyticsForPeriod(String period) async {
    final now = DateTime.now();
    String? dateDebut;
    String? dateFin = now.toIso8601String().split('T')[0];

    switch (period) {
      case '7days':
        dateDebut = now.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];
        break;
      case '30days':
        dateDebut = now.subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
        break;
      case '90days':
        dateDebut = now.subtract(const Duration(days: 90)).toIso8601String().split('T')[0];
        break;
      case 'thisMonth':
        dateDebut = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
        break;
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        dateDebut = lastMonth.toIso8601String().split('T')[0];
        dateFin = DateTime(now.year, now.month, 0).toIso8601String().split('T')[0];
        break;
      case 'thisYear':
        dateDebut = DateTime(now.year, 1, 1).toIso8601String().split('T')[0];
        break;
      default:
        // Pas de filtre de date pour 'all'
        dateDebut = null;
        dateFin = null;
    }

    return getProductAnalytics(
      dateDebut: dateDebut,
      dateFin: dateFin,
      limit: 100, // Augmenter la limite pour avoir plus de produits
    );
  }
}
