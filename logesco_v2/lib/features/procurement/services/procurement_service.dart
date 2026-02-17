/**
 * Service pour la gestion des approvisionnements
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_constants.dart';
import '../models/procurement_models.dart';

class ProcurementService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = '${ApiConfig.baseUrl}/procurement';

  ProcurementService();

  /// Récupère le token d'authentification
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: AppConstants.authTokenKey);
  }

  /// Récupère la liste des commandes d'approvisionnement
  Future<Map<String, dynamic>> getCommandes({
    int? fournisseurId,
    String? statut,
    DateTime? dateDebut,
    DateTime? dateFin,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (fournisseurId != null) queryParams['fournisseurId'] = fournisseurId.toString();
      if (statut != null) queryParams['statut'] = statut;
      if (dateDebut != null) queryParams['dateDebut'] = dateDebut.toIso8601String();
      if (dateFin != null) queryParams['dateFin'] = dateFin.toIso8601String();

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final token = await _getToken();

      print('📨 API REQUEST (Procurement): GET $uri');
      print('   - page=$page, limit=$limit');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📨 API RESPONSE STATUS (Procurement): ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final commandes = (data['data']['commandes'] as List).map((json) => CommandeApprovisionnement.fromJson(json)).toList();
          final pagination = data['data']['pagination'] as Map<String, dynamic>;

          print('✅ SUCCÈS: ${commandes.length} commandes reçues');
          print('   - Total disponible: ${pagination['total']}');
          print('   - Page: ${pagination['page']}/${pagination['pages']}');
          print('   - hasNext: ${(pagination['page'] as int) < (pagination['pages'] as int)}');

          return {
            'commandes': commandes,
            'pagination': pagination,
          };
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la récupération des commandes');
        }
      } else {
        print('❌ ERREUR API: Status ${response.statusCode}');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ERREUR: $e');
      throw Exception('Erreur lors de la récupération des commandes: $e');
    }
  }

  /// Récupère une commande par son ID
  Future<CommandeApprovisionnement> getCommande(int id) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CommandeApprovisionnement.fromJson(data['data']);
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la récupération de la commande');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la commande: $e');
    }
  }

  /// Crée une nouvelle commande d'approvisionnement
  Future<CommandeApprovisionnement> createCommande({
    required int fournisseurId,
    DateTime? dateLivraisonPrevue,
    String modePaiement = 'credit',
    String? notes,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final token = await _getToken();

      final body = {
        'fournisseurId': fournisseurId,
        'dateLivraisonPrevue': dateLivraisonPrevue?.toIso8601String(),
        'modePaiement': modePaiement,
        'notes': notes,
        'details': details,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CommandeApprovisionnement.fromJson(data['data']);
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la création de la commande');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error']['message'] ?? 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }

  /// Met à jour une commande d'approvisionnement
  Future<CommandeApprovisionnement> updateCommande(
    int id, {
    DateTime? dateLivraisonPrevue,
    String? modePaiement,
    String? notes,
    String? statut,
  }) async {
    try {
      final token = await _getToken();

      final body = <String, dynamic>{};
      if (dateLivraisonPrevue != null) body['dateLivraisonPrevue'] = dateLivraisonPrevue.toIso8601String();
      if (modePaiement != null) body['modePaiement'] = modePaiement;
      if (notes != null) body['notes'] = notes;
      if (statut != null) body['statut'] = statut;

      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CommandeApprovisionnement.fromJson(data['data']);
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la mise à jour de la commande');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error']['message'] ?? 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la commande: $e');
    }
  }

  /// Réceptionne une commande (partiellement ou totalement)
  Future<CommandeApprovisionnement> recevoirCommande(
    int id,
    List<Map<String, dynamic>> details,
  ) async {
    try {
      final token = await _getToken();

      final body = {
        'details': details,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/$id/receive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CommandeApprovisionnement.fromJson(data['data']);
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la réception de la commande');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error']['message'] ?? 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la réception de la commande: $e');
    }
  }

  /// Annule une commande d'approvisionnement
  Future<CommandeApprovisionnement> annulerCommande(int id) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CommandeApprovisionnement.fromJson(data['data']);
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de l\'annulation de la commande');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error']['message'] ?? 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la commande: $e');
    }
  }

  /// Récupère les alertes d'approvisionnement
  Future<Map<String, dynamic>> getAlertes() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/alerts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la récupération des alertes');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des alertes: $e');
    }
  }
}
