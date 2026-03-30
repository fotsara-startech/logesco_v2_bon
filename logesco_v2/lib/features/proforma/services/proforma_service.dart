import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/api_response.dart';
import '../models/proforma_invoice.dart';
import '../../sales/models/sale.dart';

class ProformaService {
  final AuthService _authService;

  ProformaService(this._authService);

  String get _baseUrl => '${AppConfig.currentBaseUrl}${AppConfig.proformaEndpoint}';

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Récupère la liste des proformas
  Future<ApiResponse<List<ProformaInvoice>>> getProformas({
    int page = 1,
    int limit = 20,
    String? statut,
    int? clientId,
    int? vendeurId,
  }) async {
    try {
      final headers = await _headers();
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (statut != null) params['statut'] = statut;
      if (clientId != null) params['clientId'] = clientId.toString();
      if (vendeurId != null) params['vendeurId'] = vendeurId.toString();

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      final response = await http.get(uri, headers: headers).timeout(AppConfig.connectTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List<dynamic>? ?? [];
        final proformas = data.map((e) => ProformaInvoice.fromJson(e as Map<String, dynamic>)).toList();

        Pagination? pagination;
        if (json['pagination'] != null) {
          final p = json['pagination'] as Map<String, dynamic>;
          pagination = Pagination(
            page: _safeInt(p['page']) ?? page,
            limit: _safeInt(p['limit']) ?? limit,
            total: _safeInt(p['total']) ?? proformas.length,
            totalPages: _safeInt(p['pages'] ?? p['totalPages']) ?? 1,
            hasNext: p['hasNext'] as bool? ?? false,
            hasPrev: p['hasPrev'] as bool? ?? false,
          );
        }
        return ApiResponse.success(proformas, pagination: pagination);
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse.error(message: err['message'] ?? 'Erreur lors du chargement des proformas');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Récupère une proforma par son ID
  Future<ApiResponse<ProformaInvoice>> getProforma(int id) async {
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse('$_baseUrl/$id'), headers: headers).timeout(AppConfig.connectTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse.success(ProformaInvoice.fromJson(json['data'] as Map<String, dynamic>));
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse.error(message: err['message'] ?? 'Proforma introuvable');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Crée une nouvelle proforma
  Future<ApiResponse<ProformaInvoice>> createProforma(CreateProformaRequest request) async {
    try {
      final headers = await _headers();
      final body = jsonEncode(request.toJson());
      print('📋 [PROFORMA] Création: $body');

      final response = await http.post(Uri.parse(_baseUrl), headers: headers, body: body).timeout(AppConfig.connectTimeout);

      print('📋 [PROFORMA] Réponse ${response.statusCode}: ${response.body}');

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return ApiResponse.success(
          ProformaInvoice.fromJson(json['data'] as Map<String, dynamic>),
          message: json['message'],
        );
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse.error(message: err['message'] ?? 'Erreur lors de la création de la proforma');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Met à jour une proforma existante
  Future<ApiResponse<ProformaInvoice>> updateProforma(int id, CreateProformaRequest request) async {
    try {
      final headers = await _headers();
      final body = jsonEncode(request.toJson());

      final response = await http.put(Uri.parse('$_baseUrl/$id'), headers: headers, body: body).timeout(AppConfig.connectTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResponse.success(
          ProformaInvoice.fromJson(json['data'] as Map<String, dynamic>),
          message: json['message'],
        );
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse.error(message: err['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Valide une proforma → crée la vente réelle
  Future<ApiResponse<Sale>> validateProforma(int id, ValidateProformaRequest request) async {
    try {
      final headers = await _headers();
      final body = jsonEncode(request.toJson());
      print('✅ [PROFORMA] Validation proforma $id: $body');

      final response = await http.post(Uri.parse('$_baseUrl/$id/validate'), headers: headers, body: body).timeout(AppConfig.connectTimeout);

      print('✅ [PROFORMA] Réponse validation ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return ApiResponse.success(
          Sale.fromJson(json['data'] as Map<String, dynamic>),
          message: json['message'],
        );
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse.error(message: err['message'] ?? 'Erreur lors de la validation');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Annule une proforma
  Future<ApiResponse<void>> cancelProforma(int id) async {
    try {
      final headers = await _headers();
      final response = await http.delete(Uri.parse('$_baseUrl/$id'), headers: headers).timeout(AppConfig.connectTimeout);

      if (response.statusCode == 200) {
        return ApiResponse.success(null, message: 'Proforma annulée');
      } else {
        final err = jsonDecode(response.body);
        return ApiResponse.error(message: err['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  int? _safeInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
