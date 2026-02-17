import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../models/cash_register_model.dart';

/// Service pour la gestion des caisses via API
class CashRegisterService {
  static const String _endpoint = '/cash-registers';

  /// Récupérer toutes les caisses
  static Future<List<CashRegister>> getAllCashRegisters() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cashRegisters = data['data'] ?? [];
        return cashRegisters.map((json) => CashRegister.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des caisses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer une caisse par ID
  static Future<CashRegister> getCashRegisterById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CashRegister.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Caisse non trouvée');
      } else {
        throw Exception('Erreur lors de la récupération de la caisse: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Créer une nouvelle caisse
  static Future<CashRegister> createCashRegister(CashRegister cashRegister) async {
    try {
      final body = {
        'nom': cashRegister.nom,
        'description': cashRegister.description ?? '',
        'soldeInitial': cashRegister.soldeInitial,
        'isActive': cashRegister.isActive,
      };

      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return CashRegister.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la création de la caisse');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Mettre à jour une caisse
  static Future<CashRegister> updateCashRegister(int id, CashRegister cashRegister) async {
    try {
      final body = {
        'nom': cashRegister.nom,
        'description': cashRegister.description ?? '',
        'isActive': cashRegister.isActive,
      };

      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CashRegister.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la mise à jour de la caisse');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Supprimer une caisse
  static Future<void> deleteCashRegister(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Caisse non trouvée');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la suppression de la caisse');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Ouvrir une caisse
  static Future<CashRegister> openCashRegister(int id, double soldeInitial) async {
    try {
      final body = {
        'action': 'open',
        'soldeInitial': soldeInitial,
      };

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id/status'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CashRegister.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de l\'ouverture de la caisse');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Fermer une caisse
  static Future<CashRegister> closeCashRegister(int id) async {
    try {
      final body = {
        'action': 'close',
      };

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id/status'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CashRegister.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la fermeture de la caisse');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer les mouvements d'une caisse
  static Future<List<Map<String, dynamic>>> getCashMovements(int cashRegisterId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$cashRegisterId/movements'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des mouvements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Ajouter un mouvement de caisse
  static Future<void> addCashMovement(int cashRegisterId, String type, double montant, String? description) async {
    try {
      final body = {
        'type': type,
        'montant': montant,
        'description': description ?? '',
      };

      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$cashRegisterId/movements'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode != 201) {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de l\'ajout du mouvement');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
