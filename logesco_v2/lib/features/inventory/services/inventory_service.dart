import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/test_data_service.dart';
import '../../../core/models/api_response.dart';
import '../models/stock_model.dart';

class InventoryService {
  final AuthService _authService;

  InventoryService(this._authService);

  Future<ApiResponse<List<Stock>>> getStock({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print('⚠️ Token d\'authentification manquant');
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('📡 Réponse API: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📦 Données JSON reçues: ${jsonData.toString()}');

        try {
          final stocks = <Stock>[];

          // Vérification de la structure des données
          print('🔍 Structure JSON: ${jsonData.keys}');
          print('🔍 Type de data: ${jsonData['data'].runtimeType}');

          if (jsonData['data'] == null) {
            print('❌ jsonData[\'data\'] est null');
            return ApiResponse.error(message: 'Aucune donnée reçue de l\'API');
          }

          List<dynamic> dataList;
          try {
            dataList = jsonData['data'] as List;
          } catch (e) {
            print('❌ Impossible de convertir data en List: $e');
            print('📄 Type réel: ${jsonData['data'].runtimeType}');
            return ApiResponse.error(message: 'Format de données invalide');
          }

          for (int i = 0; i < dataList.length; i++) {
            try {
              print('🔍 Élément $i type: ${dataList[i].runtimeType}');
              print('🔍 Élément $i contenu: ${dataList[i]}');

              if (dataList[i] == null) {
                print('⚠️ Élément $i est null, ignoré');
                continue;
              }

              Map<String, dynamic> stockData;
              try {
                stockData = dataList[i] as Map<String, dynamic>;
              } catch (e) {
                print('❌ Impossible de convertir élément $i en Map: $e');
                continue;
              }

              // Essayer de créer un Stock avec gestion d'erreur robuste
              try {
                final stock = Stock.fromJson(stockData);
                stocks.add(stock);
              } catch (e) {
                // Créer manuellement un Stock avec extraction ultra-sécurisée
                try {
                  final stock = Stock(
                    id: _safeExtractInt(stockData, ['id']),
                    produitId: _safeExtractInt(stockData, ['produitId', 'productId', 'product_id']),
                    quantiteDisponible: _safeExtractInt(stockData, ['quantiteDisponible', 'quantite_disponible', 'availableQuantity', 'available_quantity']),
                    quantiteReservee: _safeExtractInt(stockData, ['quantiteReservee', 'quantite_reservee', 'reservedQuantity', 'reserved_quantity']),
                    derniereMaj: DateTime.now(),
                  );
                  stocks.add(stock);
                } catch (e2) {
                  // Impossible de créer le stock
                }
              }
            } catch (e) {
              // Erreur lors du traitement du stock
            }
          }

          return ApiResponse.success(
            stocks,
            pagination: jsonData['pagination'] != null ? _safeParsePagination(jsonData['pagination']) : null,
          );
        } catch (e) {
          return ApiResponse.error(message: 'Erreur lors du parsing des données: $e');
        }
      } else if (response.statusCode == 401) {
        print('🔐 Erreur d\'authentification - token invalide');
        return ApiResponse.error(message: 'Token d\'authentification invalide');
      } else {
        final errorData = json.decode(response.body);
        print('❌ Erreur API: ${errorData['message']}');
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la récupération du stock');
      }
    } catch (e) {
      print('💥 Erreur de connexion: $e');
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  // Données de test pour le développement
  ApiResponse<List<Stock>> _getTestStockData() {
    final testStocks = TestDataService.getTestStocks();
    return ApiResponse.success(testStocks);
  }

  // Méthode helper pour extraire des entiers de manière sécurisée
  static int _safeExtractInt(Map<String, dynamic> json, List<String> keys) {
    for (String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        final value = json[key];
        try {
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) {
            final parsed = int.tryParse(value);
            if (parsed != null) return parsed;
          }
          if (value is num) return value.toInt();
        } catch (e) {
          print('⚠️ Erreur conversion $key: $value -> $e');
          continue;
        }
      }
    }
    return 0;
  }

  // Méthode helper pour parser la pagination de manière sécurisée
  static Pagination? _safeParsePagination(dynamic paginationData) {
    if (paginationData == null) return null;

    try {
      if (paginationData is Map<String, dynamic>) {
        return Pagination.fromJson(paginationData);
      }
    } catch (e) {}

    return null;
  }

  Future<ApiResponse<Stock?>> getProductStock(int productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print('⚠️ Token d\'authentification manquant pour produit $productId');
        if (ApiConfig.isDevelopment && ApiConfig.useTestData) {
          final testStock = TestDataService.getTestStockByProductId(productId);
          return ApiResponse.success(testStock);
        }
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      // L'endpoint correct est /inventory/:id où :id est le produitId
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final stock = Stock.fromJson(jsonData['data']);
        return ApiResponse.success(stock);
      } else if (response.statusCode == 404) {
        // Pas de stock pour ce produit (probablement un service)
        print('⚠️ Stock non trouvé pour produit $productId');
        return ApiResponse.success(null);
      } else if (response.statusCode == 401) {
        print('🔐 Erreur d\'authentification pour produit $productId');
        if (ApiConfig.isDevelopment && ApiConfig.useTestData) {
          final testStock = TestDataService.getTestStockByProductId(productId);
          return ApiResponse.success(testStock);
        }
        return ApiResponse.error(message: 'Token d\'authentification invalide');
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la récupération du stock');
      }
    } catch (e) {
      print('💥 Erreur de connexion pour produit $productId: $e');
      if (ApiConfig.isDevelopment && ApiConfig.useTestData) {
        final testStock = TestDataService.getTestStockByProductId(productId);
        return ApiResponse.success(testStock);
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  // Méthodes pour le contrôleur GetX existant
  Future<PaginatedResponse<List<Stock>>> getStocks({
    int page = 1,
    int limit = 20,
    bool? alerteStock,
    int? produitId,
    String? searchQuery,
    String? category,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (alerteStock != null) queryParams['alerteStock'] = alerteStock.toString();
      if (produitId != null) queryParams['produitId'] = produitId.toString();
      if (searchQuery != null && searchQuery.isNotEmpty) queryParams['search'] = searchQuery;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}').replace(queryParameters: queryParams);

      // Log toutes les requêtes API
      print('📨 API REQUEST: GET $uri');
      print('   - page=${queryParams['page']}, limit=${queryParams['limit']}');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 API RESPONSE STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final stocks = (jsonData['data'] as List).map((item) => Stock.fromJson(item)).toList();
        final pagination = PaginationInfo.fromJson(jsonData['pagination']);

        print('✅ SUCCÈS: ${stocks.length} produits reçus');
        print('   - Total disponible: ${pagination.total}');
        print('   - Page: ${pagination.page}/${pagination.totalPages}');
        print('   - hasNext: ${pagination.hasNext}');
        print('   - First product: ${stocks.isNotEmpty ? stocks.first.produit?.nom ?? 'N/A' : 'AUCUN'}');

        return PaginatedResponse(
          data: stocks,
          pagination: pagination,
        );
      } else if (response.statusCode == 401) {
        print('❌ ERREUR AUTH: Token invalide ou expiré');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        print('❌ ERREUR API: Status ${response.statusCode}');
        print('   - Response: ${response.body.substring(0, 200)}');
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération des stocks');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<PaginatedResponse<List<Stock>>> getStockAlerts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    return getStocks(
      page: page,
      limit: limit,
      alerteStock: true,
      searchQuery: search,
      category: category,
    );
  }

  Future<PaginatedResponse<List<StockMovement>>> getStockMovements({
    int page = 1,
    int limit = 20,
    String? search,
    int? produitId,
    String? typeMouvement,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['q'] = search;
      if (produitId != null) queryParams['produitId'] = produitId.toString();
      if (typeMouvement != null) queryParams['typeMouvement'] = typeMouvement;
      if (dateDebut != null) queryParams['dateDebut'] = dateDebut.toIso8601String();
      if (dateFin != null) queryParams['dateFin'] = dateFin.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/movements').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final movements = (jsonData['data'] as List).map((item) => StockMovement.fromJson(item)).toList();
        final pagination = PaginationInfo.fromJson(jsonData['pagination']);

        return PaginatedResponse(
          data: movements,
          pagination: pagination,
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération des mouvements');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<StockSummary> getStockSummary() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return StockSummary.fromJson(jsonData['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération du résumé');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<Stock> adjustStock({
    required int produitId,
    required int changementQuantite,
    String? notes,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (ApiConfig.isDevelopment && ApiConfig.useTestData) {
          return _createTestStockAdjustment(produitId, changementQuantite, notes);
        }
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/adjust'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'produitId': produitId,
              'changementQuantite': changementQuantite,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        return Stock.fromJson(jsonData['data']);
      } else {
        final errorData = json.decode(response.body);

        throw Exception(errorData['message'] ?? 'Erreur lors de l\'ajustement du stock');
      }
    } catch (e) {
      if (ApiConfig.isDevelopment && ApiConfig.useTestData) {
        return _createTestStockAdjustment(produitId, changementQuantite, notes);
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Crée un ajustement de stock de test
  Stock _createTestStockAdjustment(int produitId, int changementQuantite, String? notes) {
    // Trouver le stock existant ou en créer un nouveau
    final existingStock = TestDataService.getTestStockByProductId(produitId);

    if (existingStock != null) {
      // Mettre à jour le stock existant
      final newQuantite = (existingStock.quantiteDisponible + changementQuantite).clamp(0, 9999);
      return Stock(
        id: existingStock.id,
        produitId: produitId,
        quantiteDisponible: newQuantite,
        quantiteReservee: existingStock.quantiteReservee,
        derniereMaj: DateTime.now(),
        produit: existingStock.produit,
        stockFaible: newQuantite <= (existingStock.produit?.seuilStockMinimum ?? 10),
      );
    } else {
      // Créer un nouveau stock
      final newQuantite = changementQuantite.clamp(0, 9999);
      return Stock(
        id: produitId,
        produitId: produitId,
        quantiteDisponible: newQuantite,
        quantiteReservee: 0,
        derniereMaj: DateTime.now(),
        produit: Product(
          id: produitId,
          reference: 'REF$produitId',
          nom: 'Produit $produitId',
          seuilStockMinimum: 10,
          estActif: true,
        ),
        stockFaible: newQuantite <= 10,
      );
    }
  }

  /// Effectue un ajustement en lot
  Future<BulkAdjustmentResponse> bulkAdjustStock(BulkAdjustmentRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/bulk-adjust'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return BulkAdjustmentResponse.fromJson(jsonData['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'ajustement en lot');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère le stock d'un produit spécifique par ID
  Future<Stock?> getStockByProductId(int productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/product/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Stock.fromJson(jsonData['data']);
      } else if (response.statusCode == 404) {
        return null; // Pas de stock pour ce produit
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la récupération du stock');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Exporte les stocks en CSV
  Future<String> exportStockToCsv({
    bool? alerteStock,
    int? produitId,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final queryParams = <String, String>{};
      if (alerteStock != null) queryParams['alerteStock'] = alerteStock.toString();
      if (produitId != null) queryParams['produitId'] = produitId.toString();

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/export/csv').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'export CSV');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Exporte les mouvements en CSV
  Future<String> exportMovementsToCsv({
    int? produitId,
    String? typeMouvement,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final queryParams = <String, String>{};
      if (produitId != null) queryParams['produitId'] = produitId.toString();
      if (typeMouvement != null) queryParams['typeMouvement'] = typeMouvement;
      if (dateDebut != null) queryParams['dateDebut'] = dateDebut.toIso8601String();
      if (dateFin != null) queryParams['dateFin'] = dateFin.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/movements/export/csv').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'export CSV des mouvements');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Crée un mouvement de stock (remplace adjustStock)
  Future<StockMovement> createStockMovement({
    required int produitId,
    required String typeMouvement,
    required int changementQuantite,
    String? notes,
    int? referenceId,
    String? typeReference,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.inventoryEndpoint}/movements'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'produitId': produitId,
          'typeMouvement': typeMouvement,
          'changementQuantite': changementQuantite,
          'notes': notes,
          'referenceId': referenceId,
          'typeReference': typeReference,
        }),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return StockMovement.fromJson(jsonData['data']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création du mouvement');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}

// Classes helper pour la pagination
class PaginatedResponse<T> {
  final T data;
  final PaginationInfo pagination;

  PaginatedResponse({
    required this.data,
    required this.pagination,
  });
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['pages'] ?? json['totalPages'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}
