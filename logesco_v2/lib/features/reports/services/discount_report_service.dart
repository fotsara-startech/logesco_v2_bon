import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/api_response.dart';
import '../models/discount_report.dart';

class DiscountReportService {
  final AuthService _authService;

  DiscountReportService(this._authService);

  /// Récupère le résumé des remises avec groupement
  Future<ApiResponse<DiscountReport>> getDiscountSummary({
    String groupBy = 'vendeur',
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final queryParams = <String, String>{
        'groupBy': groupBy,
      };

      if (dateDebut != null) {
        queryParams['dateDebut'] = dateDebut.toIso8601String();
      }
      if (dateFin != null) {
        queryParams['dateFin'] = dateFin.toIso8601String();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/discount-reports/summary').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Discount Summary API Response Status: ${response.statusCode}');
      print('📊 Discount Summary API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final report = DiscountReport.fromJson(jsonData['data']);
        return ApiResponse.success(report);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          message: errorData['message'] ?? 'Erreur lors de la récupération du résumé des remises',
        );
      }
    } catch (e) {
      print('❌ Erreur récupération résumé remises: $e');
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Récupère les remises par vendeur
  Future<ApiResponse<VendorDiscountReport>> getDiscountsByVendor({
    int? vendeurId,
    DateTime? dateDebut,
    DateTime? dateFin,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (vendeurId != null) {
        queryParams['vendeurId'] = vendeurId.toString();
      }
      if (dateDebut != null) {
        queryParams['dateDebut'] = dateDebut.toIso8601String();
      }
      if (dateFin != null) {
        queryParams['dateFin'] = dateFin.toIso8601String();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/discount-reports/by-vendor').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Vendor Discounts API Response Status: ${response.statusCode}');
      print('📊 Vendor Discounts API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final report = VendorDiscountReport.fromJson(jsonData['data']);
        return ApiResponse.success(report);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          message: errorData['message'] ?? 'Erreur lors de la récupération des remises par vendeur',
        );
      }
    } catch (e) {
      print('❌ Erreur récupération remises par vendeur: $e');
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Récupère le top des remises
  Future<ApiResponse<List<TopDiscount>>> getTopDiscounts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/discount-reports/top-discounts').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Top Discounts API Response Status: ${response.statusCode}');
      print('📊 Top Discounts API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final discountsList = jsonData['data'] as List;
        final discounts = discountsList.map((item) => TopDiscount.fromJson(item as Map<String, dynamic>)).toList();
        return ApiResponse.success(discounts);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          message: errorData['message'] ?? 'Erreur lors de la récupération du top des remises',
        );
      }
    } catch (e) {
      print('❌ Erreur récupération top remises: $e');
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Valide une remise avant application
  Future<ApiResponse<Map<String, dynamic>>> validateDiscount({
    required int produitId,
    required double remiseAppliquee,
    String? justificationRemise,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final requestBody = {
        'produitId': produitId,
        'remiseAppliquee': remiseAppliquee,
        if (justificationRemise != null) 'justificationRemise': justificationRemise,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/sales/validate-discount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📊 Validate Discount API Response Status: ${response.statusCode}');
      print('📊 Validate Discount API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ApiResponse.success(jsonData['data'] as Map<String, dynamic>);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          message: errorData['message'] ?? 'Erreur lors de la validation de la remise',
        );
      }
    } catch (e) {
      print('❌ Erreur validation remise: $e');
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }
}
