import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/expiration_date.dart';

/// Service pour gérer les dates de péremption via l'API
class ExpirationDateService {
  final String baseUrl = '${ApiConfig.baseUrl}/expiration-dates';
  final AuthService _authService = AuthService();

  /// Récupère les headers avec le token d'authentification
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Crée une nouvelle date de péremption
  Future<ExpirationDate> createExpirationDate({
    required int produitId,
    required DateTime datePeremption,
    required int quantite,
    String? numeroLot,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode({
          'produitId': produitId,
          'datePeremption': datePeremption.toIso8601String(),
          'quantite': quantite,
          'numeroLot': numeroLot,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ExpirationDate.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère toutes les dates de péremption avec filtres
  Future<Map<String, dynamic>> getExpirationDates({
    int? produitId,
    bool? estPerime,
    int? joursRestants,
    bool? estEpuise,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (produitId != null) queryParams['produitId'] = produitId.toString();
      if (estPerime != null) queryParams['estPerime'] = estPerime.toString();
      if (joursRestants != null) queryParams['joursRestants'] = joursRestants.toString();
      if (estEpuise != null) queryParams['estEpuise'] = estEpuise.toString();

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dates = (data['data'] as List).map((json) => ExpirationDate.fromJson(json)).toList();

        return {
          'data': dates,
          'pagination': data['pagination'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la récupération');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les alertes de péremption
  Future<Map<String, dynamic>> getExpirationAlerts({
    String? niveauAlerte,
    int joursMax = 30,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'joursMax': joursMax.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (niveauAlerte != null) queryParams['niveauAlerte'] = niveauAlerte;

      final uri = Uri.parse('$baseUrl/alertes').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dates = (data['data'] as List).map((json) => ExpirationDate.fromJson(json)).toList();

        return {
          'data': dates,
          'pagination': data['pagination'],
          'stats': data['stats'] != null ? ExpirationAlertStats.fromJson(data['stats']) : null,
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la récupération des alertes');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère une date de péremption spécifique
  Future<ExpirationDate> getExpirationDate(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExpirationDate.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Date de péremption non trouvée');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Met à jour une date de péremption
  Future<ExpirationDate> updateExpirationDate(
    int id, {
    DateTime? datePeremption,
    int? quantite,
    String? numeroLot,
    String? notes,
    bool? estEpuise,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};

      if (datePeremption != null) body['datePeremption'] = datePeremption.toIso8601String();
      if (quantite != null) body['quantite'] = quantite;
      if (numeroLot != null) body['numeroLot'] = numeroLot;
      if (notes != null) body['notes'] = notes;
      if (estEpuise != null) body['estEpuise'] = estEpuise;

      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExpirationDate.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Supprime une date de péremption
  Future<void> deleteExpirationDate(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Marque une date de péremption comme épuisée
  Future<ExpirationDate> markAsExhausted(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$id/marquer-epuise'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExpirationDate.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors du marquage');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère les statistiques de péremption pour un produit
  Future<Map<String, dynamic>> getProductStats(int produitId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/product/$produitId/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la récupération des statistiques');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupère l'historique des lots épuisés
  Future<Map<String, dynamic>> getHistory({
    int? produitId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (produitId != null) queryParams['produitId'] = produitId.toString();

      final uri = Uri.parse('$baseUrl/history').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dates = (data['data'] as List).map((json) => ExpirationDate.fromJson(json)).toList();

        return {
          'data': dates,
          'pagination': data['pagination'],
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la récupération de l\'historique');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
