import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/api_response.dart';
import '../models/models.dart';
import '../../company_settings/models/company_profile.dart';
import '../../customers/models/customer.dart';
import '../../sales/models/sale.dart';

/// Service pour la gestion des impressions et réimpressions de reçus
class PrintingService {
  final AuthService _authService;
  static const String _cacheKey = 'receipts_cache';
  static const String _cacheTimestampKey = 'receipts_cache_timestamp';
  static const Duration _cacheExpiration = Duration(minutes: 30);

  // Mode test pour simuler les réponses quand le backend n'est pas disponible
  static const bool _useTestMode = false;

  // Cache pour les reçus générés en mode test
  static final Map<String, Receipt> _testReceiptsCache = {};

  // Profil d'entreprise partagé
  static CompanyProfile? _sharedCompanyProfile;

  PrintingService(this._authService);

  /// Définit le profil d'entreprise à utiliser
  static void setCompanyProfile(CompanyProfile? profile) {
    _sharedCompanyProfile = profile;
    if (profile != null) {
      print('🔥 DÉFINITION DU PROFIL PARTAGÉ POUR IMPRESSION');
      print('📋 === PROFIL D\'ENTREPRISE POUR IMPRESSION ===');
      print('📋 Nom: ${profile.name}');
      print('📋 Adresse: ${profile.address}');
      print('📋 Localisation: ${profile.location ?? 'Non définie'}');
      print('📋 Téléphone: ${profile.phone ?? 'Non défini'}');
      print('📋 Email: ${profile.email ?? 'Non défini'}');
      print('📋 NUI/RCCM: ${profile.nuiRccm ?? 'Non défini'}');
      print('📋 ============================================');
    } else {
      print('❌ TENTATIVE DE DÉFINIR UN PROFIL NULL');
    }
  }

  /// Recherche des reçus selon les critères spécifiés
  Future<ApiResponse<ReceiptSearchResponse>> searchReceipts({
    required ReceiptSearchRequest request,
    bool useCache = true,
  }) async {
    try {
      // Vérifier le cache pour les requêtes simples
      if (useCache && !request.criteria.hasFilters) {
        final cachedResponse = await _getCachedReceipts();
        if (cachedResponse != null) {
          return ApiResponse.success(cachedResponse, message: 'Données récupérées du cache');
        }
      }

      // Mode test : simuler la réponse
      if (_useTestMode) {
        return _simulateSearchResponse(request);
      }

      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final queryParams = request.toQueryParams();
      final uri = Uri.parse('${ApiConfig.baseUrl}/printing/receipts').replace(
        queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())),
      );

      print('📊 Searching receipts with URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('📊 Receipt Search API Response Status: ${response.statusCode}');
      print('📊 Receipt Search API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Vérifier si data est une liste ou un objet
        ReceiptSearchResponse searchResponse;
        if (jsonData['data'] is List) {
          // Si c'est une liste, créer une réponse simple
          final List<dynamic> receiptsJson = jsonData['data'];
          final receipts = receiptsJson.map((json) {
            // Convertir et nettoyer les données pour éviter les erreurs de type
            final fixedJson = Map<String, dynamic>.from(json);

            // Corriger les IDs (convertir int en string si nécessaire, gérer les null)
            if (fixedJson['id'] != null) {
              fixedJson['id'] = fixedJson['id'].toString();
            } else {
              fixedJson['id'] = '0';
            }

            if (fixedJson['saleId'] != null) {
              fixedJson['saleId'] = fixedJson['saleId'].toString();
            } else {
              fixedJson['saleId'] = '0';
            }

            if (fixedJson['venteId'] != null) {
              fixedJson['venteId'] = fixedJson['venteId'].toString();
            }

            // Assurer que les champs String requis ne sont pas null
            fixedJson['saleNumber'] = fixedJson['saleNumber']?.toString() ?? 'N/A';
            fixedJson['paymentMethod'] = fixedJson['paymentMethod']?.toString() ?? 'Comptant';

            // Corriger les données de vente imbriquées
            if (fixedJson['vente'] != null) {
              final vente = Map<String, dynamic>.from(fixedJson['vente']);
              if (vente['id'] != null) {
                vente['id'] = vente['id'].toString();
              }
              fixedJson['vente'] = vente;
            }

            // Assurer que companyInfo existe avec tous les champs requis
            if (fixedJson['companyInfo'] == null) {
              fixedJson['companyInfo'] = {
                'id': 0,
                'name': 'LOGESCO',
                'address': 'Adresse non définie',
                'location': '',
                'phone': '',
                'email': '',
                'nuiRccm': '',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              };
            } else {
              // Vérifier et corriger les champs manquants dans companyInfo
              final companyInfo = Map<String, dynamic>.from(fixedJson['companyInfo']);
              if (companyInfo['id'] == null) companyInfo['id'] = 0;
              companyInfo['name'] = companyInfo['name']?.toString() ?? 'LOGESCO';
              companyInfo['address'] = companyInfo['address']?.toString() ?? 'Adresse non définie';
              companyInfo['location'] = companyInfo['location']?.toString() ?? '';
              companyInfo['phone'] = companyInfo['phone']?.toString() ?? '';
              companyInfo['email'] = companyInfo['email']?.toString() ?? '';
              companyInfo['nuiRccm'] = companyInfo['nuiRccm']?.toString() ?? '';
              if (companyInfo['createdAt'] == null) {
                companyInfo['createdAt'] = DateTime.now().toIso8601String();
              }
              if (companyInfo['updatedAt'] == null) {
                companyInfo['updatedAt'] = DateTime.now().toIso8601String();
              }
              fixedJson['companyInfo'] = companyInfo;
            }

            // Assurer que items existe et corriger les données des items
            if (fixedJson['items'] == null) {
              fixedJson['items'] = [];
            } else {
              final items = List<Map<String, dynamic>>.from(fixedJson['items']);
              for (var item in items) {
                item['productId'] = item['productId']?.toString() ?? '0';
                item['productName'] = item['productName']?.toString() ?? 'Produit';
                item['productReference'] = item['productReference']?.toString() ?? '';
                if (item['quantity'] == null) item['quantity'] = 1;
                if (item['unitPrice'] == null) item['unitPrice'] = 0.0;
                if (item['totalPrice'] == null) item['totalPrice'] = 0.0;
                if (item['displayPrice'] == null) item['displayPrice'] = 0.0;
                if (item['discountAmount'] == null) item['discountAmount'] = 0.0;
                if (item['discountJustification'] != null) {
                  item['discountJustification'] = item['discountJustification'].toString();
                }
              }
              fixedJson['items'] = items;
            }

            // Assurer que les champs numériques existent
            if (fixedJson['subtotal'] == null) fixedJson['subtotal'] = 0.0;
            if (fixedJson['discountAmount'] == null) fixedJson['discountAmount'] = 0.0;
            if (fixedJson['totalAmount'] == null) fixedJson['totalAmount'] = 0.0;

            // Récupérer paidAmount et remainingAmount de la vente associée
            if (fixedJson['paidAmount'] == null || fixedJson['paidAmount'] == 0) {
              if (fixedJson['vente'] != null && fixedJson['vente']['montantPaye'] != null) {
                fixedJson['paidAmount'] = (fixedJson['vente']['montantPaye'] as num).toDouble();
                print('🔍 [SEARCH_RECEIPTS] Receipt ${fixedJson['id']} - Mapped paidAmount: ${fixedJson['paidAmount']}');
              } else {
                fixedJson['paidAmount'] = 0.0;
              }
            }
            if (fixedJson['remainingAmount'] == null || fixedJson['remainingAmount'] == 0) {
              if (fixedJson['vente'] != null && fixedJson['vente']['montantRestant'] != null) {
                fixedJson['remainingAmount'] = (fixedJson['vente']['montantRestant'] as num).toDouble();
                print('🔍 [SEARCH_RECEIPTS] Receipt ${fixedJson['id']} - Mapped remainingAmount: ${fixedJson['remainingAmount']}');
              } else {
                fixedJson['remainingAmount'] = 0.0;
              }
            }

            print(
                '📊 [PAYMENT DATA] paidAmount: ${fixedJson['paidAmount']}, remainingAmount: ${fixedJson['remainingAmount']}, from vente: ${fixedJson['vente']?['montantPaye']}, ${fixedJson['vente']?['montantRestant']}');

            // Assurer que les champs de date existent
            if (fixedJson['saleDate'] == null) {
              fixedJson['saleDate'] = DateTime.now().toIso8601String();
            }

            // Assurer que les champs de format existent
            if (fixedJson['format'] == null) fixedJson['format'] = 'thermal';
            if (fixedJson['isReprint'] == null) fixedJson['isReprint'] = false;
            if (fixedJson['reprintCount'] == null) fixedJson['reprintCount'] = 0;

            return Receipt.fromJson(fixedJson);
          }).toList();

          searchResponse = ReceiptSearchResponse(
            receipts: receipts,
            totalCount: receipts.length,
            currentPage: request.paginationOptions.page,
            totalPages: 1,
            hasNextPage: false,
            hasPreviousPage: false,
          );
        } else {
          // Si c'est un objet, parser normalement
          searchResponse = ReceiptSearchResponse.fromJson(jsonData['data']);
        }

        // Mettre en cache si c'est une requête simple
        if (!request.criteria.hasFilters) {
          await _cacheReceipts(searchResponse);
        }

        return ApiResponse.success(searchResponse, message: jsonData['message']);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la recherche des reçus');
      }
    } catch (e) {
      print('❌ Error searching receipts: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Récupère un reçu spécifique par son ID
  Future<ApiResponse<Receipt>> getReceiptById(String receiptId) async {
    try {
      // Mode test : simuler la réponse
      if (_useTestMode) {
        return _simulateGetReceiptResponse(receiptId);
      }

      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/printing/receipts/$receiptId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('📊 Get Receipt API Response Status: ${response.statusCode}');
      print('📊 Get Receipt API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final receiptJson = Map<String, dynamic>.from(jsonData['data']);

        print('📋 [GET_RECEIPT_BY_ID] Full JSON: $receiptJson');
        print('📋 [GET_RECEIPT_BY_ID] Has vente? ${receiptJson['vente'] != null}');
        if (receiptJson['vente'] != null) {
          print('📋 [GET_RECEIPT_BY_ID] Vente keys: ${receiptJson['vente'].keys}');
          print('📋 [GET_RECEIPT_BY_ID] Vente.montantPaye: ${receiptJson['vente']['montantPaye']}');
          print('📋 [GET_RECEIPT_BY_ID] Vente.montantRestant: ${receiptJson['vente']['montantRestant']}');
        }
        print('📋 [GET_RECEIPT_BY_ID] Direct paidAmount: ${receiptJson['paidAmount']}');
        print('📋 [GET_RECEIPT_BY_ID] Direct remainingAmount: ${receiptJson['remainingAmount']}');

        // Mapper paidAmount et remainingAmount depuis la vente
        if (receiptJson['paidAmount'] == null || receiptJson['paidAmount'] == 0) {
          if (receiptJson['vente'] != null && receiptJson['vente']['montantPaye'] != null) {
            receiptJson['paidAmount'] = (receiptJson['vente']['montantPaye'] as num).toDouble();
            print('✅ [GET_RECEIPT_BY_ID] Mapped paidAmount: ${receiptJson['paidAmount']}');
          } else {
            receiptJson['paidAmount'] = 0.0;
            print('❌ [GET_RECEIPT_BY_ID] No vente data for paidAmount');
          }
        }
        if (receiptJson['remainingAmount'] == null || receiptJson['remainingAmount'] == 0) {
          if (receiptJson['vente'] != null && receiptJson['vente']['montantRestant'] != null) {
            receiptJson['remainingAmount'] = (receiptJson['vente']['montantRestant'] as num).toDouble();
            print('✅ [GET_RECEIPT_BY_ID] Mapped remainingAmount: ${receiptJson['remainingAmount']}');
          } else {
            receiptJson['remainingAmount'] = 0.0;
            print('❌ [GET_RECEIPT_BY_ID] No vente data for remainingAmount');
          }
        }

        final receipt = Receipt.fromJson(receiptJson);
        print('✅ [FINAL] paidAmount: ${receipt.paidAmount}, remainingAmount: ${receipt.remainingAmount}');

        return ApiResponse.success(receipt, message: jsonData['message']);
      } else if (response.statusCode == 404) {
        return ApiResponse.error(message: 'Reçu non trouvé');
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la récupération du reçu');
      }
    } catch (e) {
      print('❌ Error getting receipt: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Récupère un reçu par ID de vente
  Future<ApiResponse<Receipt>> getReceiptBySaleId(String saleId) async {
    try {
      // Mode test : simuler la réponse
      if (_useTestMode) {
        return _simulateGetReceiptBySaleResponse(saleId);
      }

      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/printing/receipts/by-sale/$saleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('📊 Get Receipt by Sale API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final receiptJson = Map<String, dynamic>.from(jsonData['data']);

        print('📋 [GET_RECEIPT_BY_SALEID] Full JSON: $receiptJson');
        print('📋 [GET_RECEIPT_BY_SALEID] Has vente? ${receiptJson['vente'] != null}');
        if (receiptJson['vente'] != null) {
          print('📋 [GET_RECEIPT_BY_SALEID] Vente keys: ${receiptJson['vente'].keys}');
          print('📋 [GET_RECEIPT_BY_SALEID] Vente.montantPaye: ${receiptJson['vente']['montantPaye']}');
          print('📋 [GET_RECEIPT_BY_SALEID] Vente.montantRestant: ${receiptJson['vente']['montantRestant']}');
        }

        // Mapper paidAmount et remainingAmount depuis la vente
        if (receiptJson['paidAmount'] == null || receiptJson['paidAmount'] == 0) {
          if (receiptJson['vente'] != null && receiptJson['vente']['montantPaye'] != null) {
            receiptJson['paidAmount'] = (receiptJson['vente']['montantPaye'] as num).toDouble();
            print('✅ [GET_RECEIPT_BY_SALEID] Mapped paidAmount: ${receiptJson['paidAmount']}');
          } else {
            receiptJson['paidAmount'] = 0.0;
          }
        }
        if (receiptJson['remainingAmount'] == null || receiptJson['remainingAmount'] == 0) {
          if (receiptJson['vente'] != null && receiptJson['vente']['montantRestant'] != null) {
            receiptJson['remainingAmount'] = (receiptJson['vente']['montantRestant'] as num).toDouble();
            print('✅ [GET_RECEIPT_BY_SALEID] Mapped remainingAmount: ${receiptJson['remainingAmount']}');
          } else {
            receiptJson['remainingAmount'] = 0.0;
          }
        }

        final receipt = Receipt.fromJson(receiptJson);

        return ApiResponse.success(receipt, message: jsonData['message']);
      } else if (response.statusCode == 404) {
        return ApiResponse.error(message: 'Aucun reçu trouvé pour cette vente');
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la récupération du reçu');
      }
    } catch (e) {
      print('❌ Error getting receipt by sale: $e');
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Réimprime un reçu existant
  Future<ApiResponse<ReceiptGenerationResponse>> reprintReceipt({
    required ReprintReceiptRequest request,
  }) async {
    try {
      // Mode test : simuler la réimpression
      if (_useTestMode) {
        return _simulateReprintResponse(request);
      }

      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      print('Reprinting receipt with data: ${json.encode(request.toJson())}');

      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/printing/receipts/${request.receiptId}/reprint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      )
          .timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('📊 Reprint Receipt API Response Status: ${response.statusCode}');
      print('📊 Reprint Receipt API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final reprintResponse = ReceiptGenerationResponse.fromJson(jsonData['data']);

        // Invalider le cache car les données ont changé
        await _clearCache();

        return ApiResponse.success(reprintResponse, message: jsonData['message']);
      } else if (response.statusCode == 404) {
        return ApiResponse.error(message: 'Reçu non trouvé pour réimpression');
      } else if (response.statusCode == 403) {
        return ApiResponse.error(message: 'Vous n\'avez pas l\'autorisation de réimprimer ce reçu');
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la réimpression');
      }
    } catch (e) {
      print('❌ Error reprinting receipt: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Génère un nouveau reçu à partir d'une vente
  Future<ApiResponse<ReceiptGenerationResponse>> generateReceipt({
    required GenerateReceiptRequest request,
  }) async {
    try {
      // Mode test : simuler la génération
      if (_useTestMode) {
        return _simulateGenerateResponse(request);
      }

      // Générer le reçu côté client à partir des données de vente
      return await _generateReceiptFromSaleData(request);
    } catch (e) {
      print('❌ Error generating receipt: $e');
      return ApiResponse.error(message: 'Erreur lors de la génération du reçu: $e');
    }
  }

  /// Obtient l'historique des réimpressions pour un reçu
  Future<ApiResponse<List<Receipt>>> getReprintHistory(String receiptId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/printing/receipts/$receiptId/reprints'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> reprintsJson = jsonData['data'];
        final reprints = reprintsJson.map((json) => Receipt.fromJson(json)).toList();

        return ApiResponse.success(reprints, message: jsonData['message']);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la récupération de l\'historique');
      }
    } catch (e) {
      print('❌ Error getting reprint history: $e');
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Simule une réponse de recherche en mode test
  Future<ApiResponse<ReceiptSearchResponse>> _simulateSearchResponse(ReceiptSearchRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Créer des reçus de test
    final testReceipts = _generateTestReceipts();

    // Appliquer les filtres de base
    var filteredReceipts = testReceipts;

    if (request.criteria.saleNumber?.isNotEmpty == true) {
      filteredReceipts = filteredReceipts.where((r) => r.saleNumber.contains(request.criteria.saleNumber!)).toList();
    }

    if (request.criteria.customerName?.isNotEmpty == true) {
      filteredReceipts = filteredReceipts.where((r) => r.customer?.nom.toLowerCase().contains(request.criteria.customerName!.toLowerCase()) == true).toList();
    }

    // Pagination
    final totalCount = filteredReceipts.length;
    final startIndex = (request.paginationOptions.page - 1) * request.paginationOptions.limit;
    final endIndex = (startIndex + request.paginationOptions.limit).clamp(0, totalCount);

    final paginatedReceipts = filteredReceipts.sublist(
      startIndex.clamp(0, totalCount),
      endIndex,
    );

    final response = ReceiptSearchResponse(
      receipts: paginatedReceipts,
      totalCount: totalCount,
      currentPage: request.paginationOptions.page,
      totalPages: (totalCount / request.paginationOptions.limit).ceil(),
      hasNextPage: endIndex < totalCount,
      hasPreviousPage: request.paginationOptions.page > 1,
    );

    return ApiResponse.success(response, message: 'Recherche simulée réussie');
  }

  /// Simule la récupération d'un reçu par ID
  Future<ApiResponse<Receipt>> _simulateGetReceiptResponse(String receiptId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // D'abord chercher dans le cache
    if (_testReceiptsCache.containsKey(receiptId)) {
      return ApiResponse.success(_testReceiptsCache[receiptId]!, message: 'Reçu récupéré avec succès');
    }

    // Sinon chercher dans les reçus de test par défaut
    final testReceipts = _generateTestReceipts();
    try {
      final receipt = testReceipts.firstWhere(
        (r) => r.id == receiptId,
      );
      return ApiResponse.success(receipt, message: 'Reçu récupéré avec succès');
    } catch (e) {
      return ApiResponse.error(message: 'Reçu non trouvé');
    }
  }

  /// Simule la récupération d'un reçu par ID de vente
  Future<ApiResponse<Receipt>> _simulateGetReceiptBySaleResponse(String saleId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // D'abord chercher dans le cache des reçus générés
    final cachedReceipt = _testReceiptsCache.values.firstWhere(
      (r) => r.saleId == saleId,
      orElse: () => Receipt(
        id: '',
        saleId: '',
        saleNumber: '',
        companyInfo: _getDefaultCompanyProfile(),
        items: [],
        subtotal: 0,
        discountAmount: 0,
        totalAmount: 0,
        paidAmount: 0,
        remainingAmount: 0,
        paymentMethod: '',
        saleDate: DateTime.now(),
        format: PrintFormat.thermal,
        isReprint: false,
        reprintCount: 0,
      ),
    );

    if (cachedReceipt.id.isNotEmpty) {
      return ApiResponse.success(cachedReceipt, message: 'Reçu récupéré avec succès');
    }

    // Si pas trouvé dans le cache, créer un nouveau reçu à partir des vraies données
    try {
      // Récupérer le profil d'entreprise réel
      final companyProfile = await _getRealCompanyProfile();
      if (companyProfile == null) {
        return ApiResponse.error(message: 'Profil d\'entreprise requis');
      }

      // Récupérer les vraies données de vente
      final saleData = await _getRealSaleData(saleId);
      if (saleData == null) {
        return ApiResponse.error(message: 'Aucun reçu trouvé pour cette vente');
      }

      // Créer le reçu à partir des vraies données
      final receipt = _createReceiptFromRealData(
        saleData: saleData,
        companyProfile: companyProfile,
        format: PrintFormat.thermal,
      );

      // Ajouter au cache pour les prochaines fois
      _testReceiptsCache[receipt.id] = receipt;

      print('✅ Reçu créé à partir des vraies données: ${receipt.saleNumber}');
      return ApiResponse.success(receipt, message: 'Reçu récupéré avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création du reçu: $e');
      return ApiResponse.error(message: 'Erreur lors de la récupération du reçu');
    }
  }

  /// Simule la réimpression d'un reçu
  Future<ApiResponse<ReceiptGenerationResponse>> _simulateReprintResponse(ReprintReceiptRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    Receipt? originalReceipt;

    // D'abord chercher dans le cache des reçus générés par saleId
    originalReceipt = _testReceiptsCache.values.firstWhere(
      (r) => r.saleId == request.saleId,
      orElse: () => Receipt(
        id: '',
        saleId: '',
        saleNumber: '',
        companyInfo: _getDefaultCompanyProfile(),
        items: [],
        subtotal: 0,
        discountAmount: 0,
        totalAmount: 0,
        paidAmount: 0,
        remainingAmount: 0,
        paymentMethod: '',
        saleDate: DateTime.now(),
        format: PrintFormat.thermal,
        isReprint: false,
        reprintCount: 0,
      ),
    );

    // Si pas trouvé dans le cache, créer un nouveau reçu à partir des vraies données
    if (originalReceipt.id.isEmpty) {
      // Récupérer le profil d'entreprise réel
      final companyProfile = await _getRealCompanyProfile();
      if (companyProfile == null) {
        return ApiResponse.error(message: 'Profil d\'entreprise requis pour la réimpression');
      }

      // Récupérer les vraies données de vente
      final saleData = await _getRealSaleData(request.saleId);
      if (saleData == null) {
        return ApiResponse.error(message: 'Impossible de récupérer les données de la vente ${request.saleId}');
      }

      // Créer le reçu à partir des vraies données
      originalReceipt = _createReceiptFromRealData(
        saleData: saleData,
        companyProfile: companyProfile,
        format: request.newFormat ?? PrintFormat.thermal,
      );

      print('✅ Reçu créé pour réimpression avec vraies données: ${originalReceipt.saleNumber}');
    }

    final reprintedReceipt = originalReceipt.copyForReprint(
      reprintBy: request.reprintBy,
      newFormat: request.newFormat,
    );

    // Ajouter le reçu réimprimé au cache
    _testReceiptsCache[reprintedReceipt.id] = reprintedReceipt;

    final response = ReceiptGenerationResponse.success(
      receipt: reprintedReceipt,
      pdfUrl: reprintedReceipt.format.requiresPdf ? 'receipts/${reprintedReceipt.id}.pdf' : null,
      thermalData: reprintedReceipt.format == PrintFormat.thermal ? 'thermal_data_${reprintedReceipt.id}' : null,
    );

    return ApiResponse.success(response, message: 'Reçu réimprimé avec succès');
  }

  /// Génère un nouveau reçu avec les vraies données de vente et d'entreprise
  Future<ApiResponse<ReceiptGenerationResponse>> _simulateGenerateResponse(GenerateReceiptRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Récupérer le profil d'entreprise réel
      CompanyProfile? companyProfile = await _getRealCompanyProfile();
      if (companyProfile == null) {
        print('❌ AUCUN PROFIL RÉCUPÉRÉ - Profil d\'entreprise requis');
        return ApiResponse.error(message: 'Profil d\'entreprise requis pour générer le reçu');
      }

      print('🎯 PROFIL RÉCUPÉRÉ POUR GÉNÉRATION: ${companyProfile.name}');

      // Récupérer les vraies données de vente depuis l'API
      final saleData = await _getRealSaleData(request.saleId);
      if (saleData == null) {
        print('❌ IMPOSSIBLE DE RÉCUPÉRER LES DONNÉES DE VENTE: ${request.saleId}');
        return ApiResponse.error(message: 'Impossible de récupérer les données de la vente');
      }

      print('✅ DONNÉES DE VENTE RÉCUPÉRÉES: ${saleData['numeroVente']}');

      // Créer le reçu à partir des vraies données
      final receipt = _createReceiptFromRealData(
        saleData: saleData,
        companyProfile: companyProfile,
        format: request.format,
      );

      // Ajouter le reçu au cache
      _testReceiptsCache[receipt.id] = receipt;
      print('📝 Reçu créé avec vraies données: ${receipt.id} pour vente ${receipt.saleId}');

      final response = ReceiptGenerationResponse.success(
        receipt: receipt,
        pdfUrl: receipt.format.requiresPdf ? 'receipts/${receipt.id}.pdf' : null,
        thermalData: receipt.format == PrintFormat.thermal ? 'thermal_data_${receipt.id}' : null,
      );

      print('✅ Reçu généré avec succès à partir des données réelles: ${receipt.id}');
      return ApiResponse.success(response, message: 'Reçu généré avec les vraies données');
    } catch (e) {
      print('❌ Erreur lors de la génération du reçu: $e');
      return ApiResponse.error(message: 'Erreur lors de la génération du reçu: $e');
    }
  }

  /// Récupère les vraies données de vente depuis l'API
  Future<Map<String, dynamic>?> _getRealSaleData(String saleId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/sales/$saleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Données de vente récupérées pour ID: $saleId');
        return jsonData['data'];
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération données vente: $e');
      return null;
    }
  }

  /// Crée un reçu à partir des vraies données
  Receipt _createReceiptFromRealData({
    required Map<String, dynamic> saleData,
    required CompanyProfile companyProfile,
    required PrintFormat format,
  }) {
    final now = DateTime.now();

    // Extraire les données de vente
    final saleNumber = saleData['numeroVente'] ?? 'VTE-${now.millisecondsSinceEpoch}';
    // Corriger le problème de fuseau horaire : convertir UTC vers heure locale
    final saleDate = DateTime.tryParse(saleData['dateVente'] ?? '')?.toLocal() ?? now;
    final subtotal = (saleData['sousTotal'] ?? 0).toDouble();
    final discount = (saleData['montantRemise'] ?? 0).toDouble();
    final total = (saleData['montantTotal'] ?? 0).toDouble();
    final paid = (saleData['montantPaye'] ?? 0).toDouble();
    final remaining = (saleData['montantRestant'] ?? 0).toDouble();
    final paymentMethod = saleData['modePaiement'] ?? 'comptant';

    // Extraire les articles
    final List<ReceiptItem> items = [];
    if (saleData['details'] != null) {
      for (final detail in saleData['details']) {
        final product = detail['produit'];
        items.add(ReceiptItem(
          productId: detail['produitId'].toString(),
          productName: product?['nom'] ?? 'Produit',
          productReference: product?['reference'] ?? '',
          quantity: detail['quantite'] ?? 1,
          unitPrice: (detail['prixUnitaire'] ?? 0).toDouble(),
          totalPrice: (detail['prixTotal'] ?? 0).toDouble(),
          displayPrice: (detail['prixAffiche'] ?? detail['prixUnitaire'] ?? 0).toDouble(),
          discountAmount: (detail['remiseAppliquee'] ?? 0).toDouble(),
          discountJustification: detail['justificationRemise'],
        ));
      }
    }

    // Extraire le client si présent
    Customer? customer;
    if (saleData['client'] != null) {
      final clientData = saleData['client'];
      customer = Customer(
        id: clientData['id'] ?? 0,
        nom: clientData['nom'] ?? 'Client',
        telephone: clientData['telephone'],
        adresse: clientData['adresse'],
        dateCreation: DateTime.tryParse(clientData['dateCreation'] ?? '') ?? now,
        dateModification: DateTime.tryParse(clientData['dateModification'] ?? '') ?? now,
      );
    }

    print('🎯 CRÉATION REÇU AVEC VRAIES DONNÉES:');
    print('🎯 Entreprise: ${companyProfile.name}');
    print('🎯 Vente: $saleNumber');
    print('🎯 Articles: ${items.length}');

    return Receipt(
      id: 'receipt_${saleData['id']}_${now.millisecondsSinceEpoch}',
      saleId: saleData['id'].toString(),
      saleNumber: saleNumber,
      companyInfo: companyProfile,
      items: items,
      subtotal: subtotal,
      discountAmount: discount,
      totalAmount: total,
      paidAmount: paid,
      remainingAmount: remaining,
      paymentMethod: paymentMethod,
      saleDate: saleDate,
      customer: customer,
      format: format,
      isReprint: false,
      reprintCount: 0,
    );
  }

  /// Génère un reçu à partir des données de vente réelles
  Future<ApiResponse<ReceiptGenerationResponse>> _generateReceiptFromSaleData(GenerateReceiptRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      // Récupérer les données de la vente depuis l'API
      final saleResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/sales/${request.saleId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('📊 Get Sale API Response Status: ${saleResponse.statusCode}');

      if (saleResponse.statusCode != 200) {
        return ApiResponse.error(message: 'Vente non trouvée');
      }

      final saleData = json.decode(saleResponse.body);
      print('🔍 DONNÉES VENTE RÉCUPÉRÉES DEPUIS API:');
      print('  Sale ID: ${request.saleId}');
      print('  Response: ${saleData['data']}');

      final sale = Sale.fromJson(saleData['data']);

      // Utiliser le profil d'entreprise partagé s'il est disponible
      CompanyProfile? companyProfile = _sharedCompanyProfile;

      if (companyProfile != null) {
        print('✅ UTILISATION DU PROFIL PARTAGÉ: ${companyProfile.name}');
      } else if (request.includeCompanyInfo) {
        // Fallback: essayer de récupérer depuis l'API seulement si pas de profil partagé
        try {
          print('🏢 RÉCUPÉRATION PROFIL ENTREPRISE DEPUIS API...');
          final companyResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/company/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(ApiConfig.connectTimeout);

          if (companyResponse.statusCode == 200) {
            final companyData = json.decode(companyResponse.body);
            companyProfile = CompanyProfile.fromJson(companyData['data']);
            print('✅ PROFIL ENTREPRISE RÉCUPÉRÉ DEPUIS API: ${companyProfile!.name}');
          }
        } catch (e) {
          print('❌ Impossible de récupérer le profil d\'entreprise depuis API: $e');
        }
      }

      // Utiliser un profil par défaut si aucun n'est disponible
      companyProfile ??= CompanyProfile(
        id: 0,
        name: 'LOGESCO SARL',
        address: 'Adresse non configurée',
        location: 'Localisation non configurée',
        phone: 'Téléphone non configuré',
        email: 'email@logesco.com',
        nuiRccm: 'NUI non configuré',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Créer le reçu à partir des données de vente
      final receipt = Receipt.fromSale(
        sale: sale,
        companyInfo: companyProfile,
        format: request.format,
      );

      // Ajouter le reçu au cache local
      _testReceiptsCache[receipt.id] = receipt;

      final response = ReceiptGenerationResponse.success(
        receipt: receipt,
        pdfUrl: receipt.format.requiresPdf ? 'receipts/${receipt.id}.pdf' : null,
        thermalData: receipt.format == PrintFormat.thermal ? 'thermal_data_${receipt.id}' : null,
      );

      print('✅ Reçu généré avec succès à partir des données réelles: ${receipt.id}');
      return ApiResponse.success(response, message: 'Reçu généré avec succès');
    } catch (e) {
      print('❌ Erreur lors de la génération du reçu: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Obtient un profil d'entreprise par défaut pour les reçus vides
  CompanyProfile _getDefaultCompanyProfile() {
    final now = DateTime.now();
    return CompanyProfile(
      id: 0,
      name: 'Entreprise',
      address: '',
      location: '',
      phone: '',
      email: '',
      nuiRccm: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Récupère le profil d'entreprise réel depuis l'API ou le cache partagé
  Future<CompanyProfile?> _getRealCompanyProfile() async {
    try {
      // D'abord vérifier s'il y a un profil partagé (venant du contrôleur de vente)
      if (_sharedCompanyProfile != null) {
        print('✅ Profil d\'entreprise récupéré depuis le cache partagé: ${_sharedCompanyProfile!.name}');
        return _sharedCompanyProfile;
      }

      print('⚠️ Aucun profil d\'entreprise partagé disponible');
      print('💡 Assurez-vous que le profil d\'entreprise est configuré dans les paramètres');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération du profil d\'entreprise: $e');
      return null;
    }
  }

  /// Génère des reçus de test pour la simulation
  List<Receipt> _generateTestReceipts({CompanyProfile? companyProfile}) {
    // Créer des données de test réalistes
    final now = DateTime.now();

    // OBLIGATOIRE : Utiliser uniquement le profil d'entreprise réel
    if (companyProfile == null) {
      print('❌ ERREUR: Aucun profil d\'entreprise fourni - impossible de générer le reçu');
      print('💡 Configurez le profil d\'entreprise dans les paramètres avant d\'imprimer');
      return [];
    }

    final company = companyProfile;
    print('✅ === GÉNÉRATION REÇU AVEC DONNÉES RÉELLES ===');
    print('✅ Nom entreprise: ${companyProfile.name}');
    print('✅ Adresse: ${companyProfile.address}');
    print('✅ Téléphone: ${companyProfile.phone ?? 'Non défini'}');
    print('✅ ==========================================');

    // Articles de test
    final testItems = [
      ReceiptItem(
        productId: '1',
        productName: 'Produit Test 1',
        productReference: 'REF001',
        quantity: 2,
        unitPrice: 5000,
        totalPrice: 10000,
      ),
      ReceiptItem(
        productId: '2',
        productName: 'Produit Test 2',
        productReference: 'REF002',
        quantity: 1,
        unitPrice: 15000,
        totalPrice: 15000,
      ),
    ];

    // Client de test
    final testCustomer = Customer(
      id: 1,
      nom: 'Client Test',
      telephone: '+229 97 12 34 56',
      adresse: 'Adresse du client test',
      dateCreation: now,
      dateModification: now,
    );

    return [
      Receipt(
        id: 'receipt_test_${now.millisecondsSinceEpoch}',
        saleId: '1',
        saleNumber: 'VTE-${now.millisecondsSinceEpoch}',
        companyInfo: company,
        items: testItems,
        subtotal: 25000,
        discountAmount: 0,
        totalAmount: 25000,
        paidAmount: 25000,
        remainingAmount: 0,
        paymentMethod: 'comptant',
        saleDate: now,
        customer: testCustomer,
        format: PrintFormat.thermal,
        isReprint: false,
        reprintCount: 0,
      ),
    ];
  }

  /// Récupère les reçus depuis le cache
  Future<ReceiptSearchResponse?> _getCachedReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && cacheTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
        final now = DateTime.now();

        if (now.difference(cacheTime) < _cacheExpiration) {
          final jsonData = json.decode(cachedData);
          return ReceiptSearchResponse.fromJson(jsonData);
        } else {
          await _clearCache();
        }
      }
    } catch (e) {
      print('❌ Error reading cached receipts: $e');
      await _clearCache();
    }
    return null;
  }

  /// Met en cache les reçus
  Future<void> _cacheReceipts(ReceiptSearchResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(response.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_cacheKey, jsonData);
      await prefs.setInt(_cacheTimestampKey, timestamp);

      print('✅ Receipts cached successfully');
    } catch (e) {
      print('❌ Error caching receipts: $e');
    }
  }

  /// Supprime le cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('✅ Receipts cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Vérifie si des données sont en cache
  Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cacheKey);
  }

  /// Récupère l'âge du cache en minutes
  Future<int?> getCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cacheTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
        final now = DateTime.now();
        return now.difference(cacheTime).inMinutes;
      }
    } catch (e) {
      print('❌ Error getting cache age: $e');
    }
    return null;
  }
}
