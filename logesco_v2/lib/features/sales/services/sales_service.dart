import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/api_response.dart';
import '../models/sale.dart';

class SalesService {
  final AuthService _authService;

  SalesService(this._authService);

  Future<ApiResponse<List<Sale>>> getSales({
    int page = 1,
    int limit = 20,
    int? clientId,
    String? statut,
    String? modePaiement,
    DateTime? dateDebut,
    DateTime? dateFin,
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

      if (clientId != null) queryParams['clientId'] = clientId.toString();
      if (statut != null) queryParams['statut'] = statut;
      if (modePaiement != null) queryParams['modePaiement'] = modePaiement;
      if (dateDebut != null) queryParams['dateDebut'] = dateDebut.toIso8601String();
      if (dateFin != null) queryParams['dateFin'] = dateFin.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Vérification de sécurité pour éviter l'erreur "Null is not a subtype of list"
        final salesData = jsonData['data'];
        if (salesData == null) {
          return ApiResponse.success(<Sale>[], pagination: null);
        }

        final salesList = salesData as List;

        final sales = <Sale>[];
        for (int i = 0; i < salesList.length; i++) {
          try {
            final saleData = salesList[i] as Map<String, dynamic>;

            // Vérifier et corriger les détails si nécessaire
            if (saleData['details'] == null) {
              saleData['details'] = <Map<String, dynamic>>[];
            }

            final sale = Sale.fromJson(saleData);
            sales.add(sale);
          } catch (e, stackTrace) {
            print('❌ Error parsing sale $i: $e');
            rethrow;
          }
        }

        // Parse pagination de manière sécurisée
        Pagination? pagination;
        try {
          if (jsonData['pagination'] != null) {
            final paginationData = jsonData['pagination'] as Map<String, dynamic>;
            pagination = _parsePaginationSafely(paginationData);
          }
        } catch (e) {
          pagination = null;
        }

        return ApiResponse.success(
          sales,
          pagination: pagination,
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la récupération des ventes');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  Future<ApiResponse<Sale>> getSale(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final sale = Sale.fromJson(jsonData['data']);
        return ApiResponse.success(sale);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la récupération de la vente');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  Future<ApiResponse<Sale>> createSale(CreateSaleRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      print('Creating sale with data: ${json.encode(request.toJson())}');
      print('API URL: ${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}');

      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas. Vérifiez que le serveur backend est démarré sur le port 8080.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final sale = Sale.fromJson(jsonData['data']);
        return ApiResponse.success(
          sale,
          message: jsonData['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la création de la vente');
      }
    } catch (e) {
      print('Error creating sale: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez que le serveur backend est démarré.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur. Vérifiez que le serveur backend est démarré sur le port 8080.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  Future<ApiResponse<Sale>> updateSale(int id, Map<String, dynamic> updates) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final sale = Sale.fromJson(jsonData['data']);
        return ApiResponse.success(
          sale,
          message: jsonData['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la modification de la vente');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  Future<ApiResponse<Sale>> addPayment(int id, SalePaymentRequest payment) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}/$id/payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payment.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final sale = Sale.fromJson(jsonData['data']);
        return ApiResponse.success(
          sale,
          message: jsonData['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de l\'enregistrement du paiement');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  Future<ApiResponse<void>> cancelSale(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ApiResponse.success(
          null,
          message: jsonData['message'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de l\'annulation de la vente');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Parse la pagination de manière sécurisée en gérant les valeurs null
  Pagination _parsePaginationSafely(Map<String, dynamic> data) {
    return Pagination(
      page: _safeInt(data['page']) ?? 1,
      limit: _safeInt(data['limit']) ?? 20,
      total: _safeInt(data['total']) ?? 0,
      totalPages: _safeInt(data['pages']) ?? _safeInt(data['totalPages']) ?? 1,
      hasNext: _safeBool(data['hasNext']) ?? false,
      hasPrev: _safeBool(data['hasPrev']) ?? false,
    );
  }

  /// Convertit une valeur en int de manière sécurisée
  int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Convertit une valeur en bool de manière sécurisée
  bool? _safeBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return null;
  }
}
