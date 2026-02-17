import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../models/inventory_model.dart';

/// Service pour la gestion de l'inventaire de stock via API
class StockInventoryService {
  static const String _endpoint = '/stock-inventory';

  /// Récupérer tous les inventaires
  static Future<List<StockInventory>> getAllInventories() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> inventories = data['data'] ?? [];
        return inventories.map((json) => StockInventory.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des inventaires: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer un inventaire par ID
  static Future<StockInventory> getInventoryById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StockInventory.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Inventaire non trouvé');
      } else {
        throw Exception('Erreur lors de la récupération de l\'inventaire: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Créer un nouvel inventaire
  static Future<StockInventory> createInventory(StockInventory inventory) async {
    try {
      final body = {
        'nom': inventory.nom,
        'description': inventory.description ?? '',
        'type': inventory.type.toString().split('.').last,
        'categorieId': inventory.categorieId,
        'utilisateurId': inventory.utilisateurId,
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
        return StockInventory.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la création de l\'inventaire');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Mettre à jour un inventaire
  static Future<StockInventory> updateInventory(int id, StockInventory inventory) async {
    try {
      final body = {
        'nom': inventory.nom,
        'description': inventory.description ?? '',
        'type': inventory.type.toString().split('.').last,
        'categorieId': inventory.categorieId,
        'status': inventory.status.toString().split('.').last,
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
        return StockInventory.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la mise à jour de l\'inventaire');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Supprimer un inventaire
  static Future<void> deleteInventory(int id) async {
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
        throw Exception('Inventaire non trouvé');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la suppression de l\'inventaire');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer les articles d'un inventaire
  static Future<List<InventoryItem>> getInventoryItems(int inventoryId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$inventoryId/items'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['data'] ?? [];
        return items.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Mettre à jour un article d'inventaire (comptage)
  static Future<InventoryItem> updateInventoryItem(int itemId, double quantiteComptee, String? commentaire) async {
    try {
      final body = {
        'quantiteComptee': quantiteComptee,
        'commentaire': commentaire ?? '',
        'utilisateurComptageId': 1, // TODO: Récupérer l'utilisateur connecté
      };

      final response = await http
          .put(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/items/$itemId'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return InventoryItem.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la mise à jour de l\'article');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Démarrer un inventaire (changer le statut en EN_COURS)
  static Future<StockInventory> startInventory(int id) async {
    try {
      final body = {'status': 'EN_COURS'};

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id/status'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StockInventory.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors du démarrage de l\'inventaire');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Terminer un inventaire (changer le statut en TERMINE)
  static Future<StockInventory> finishInventory(int id) async {
    try {
      final body = {'status': 'TERMINE'};

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id/status'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StockInventory.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la finalisation de l\'inventaire');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Clôturer un inventaire (changer le statut en CLOTURE et équilibrer le stock)
  static Future<StockInventory> closeInventory(int id) async {
    try {
      final body = {'status': 'CLOTURE'};

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$id/status'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StockInventory.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la clôture de l\'inventaire');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer les catégories disponibles
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}/categories'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Erreur lors de la récupération des catégories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Imprimer une feuille de comptage
  static Future<String> printCountingSheet(int inventoryId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/$inventoryId/print'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['printUrl'] ?? '';
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la génération de la feuille');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
