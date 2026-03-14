/**
 * Service pour la gestion des mouvements de stock (entrée/sortie)
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_constants.dart';
import '../models/stock_model.dart';

class StockMovementService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = '${ApiConfig.baseUrl}/inventory';

  /// Récupère le token d'authentification
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: AppConstants.authTokenKey);
  }

  /// Crée un mouvement d'entrée de stock
  Future<StockMovement> createEntreeStock({
    required int produitId,
    required int quantite,
    required String motif,
    String? notes,
    int? referenceId,
    String? typeReference,
  }) async {
    return _createMouvement(
      produitId: produitId,
      typeMouvement: 'entree',
      changementQuantite: quantite,
      notes: notes ?? 'Entrée de stock - $motif',
      referenceId: referenceId,
      typeReference: typeReference,
    );
  }

  /// Crée un mouvement de sortie de stock
  Future<StockMovement> createSortieStock({
    required int produitId,
    required int quantite,
    required String motif,
    String? notes,
    int? referenceId,
    String? typeReference,
  }) async {
    return _createMouvement(
      produitId: produitId,
      typeMouvement: 'sortie',
      changementQuantite: -quantite, // Négatif pour une sortie
      notes: notes ?? 'Sortie de stock - $motif',
      referenceId: referenceId,
      typeReference: typeReference,
    );
  }

  /// Crée un mouvement de correction de stock
  Future<StockMovement> createCorrectionStock({
    required int produitId,
    required int changementQuantite,
    required String motif,
    String? notes,
  }) async {
    return _createMouvement(
      produitId: produitId,
      typeMouvement: 'correction',
      changementQuantite: changementQuantite,
      notes: notes ?? 'Correction de stock - $motif',
      typeReference: 'correction',
    );
  }

  /// Crée un mouvement de transfert de stock
  Future<StockMovement> createTransfertStock({
    required int produitId,
    required int quantite,
    required String destination,
    String? notes,
    int? referenceId,
  }) async {
    return _createMouvement(
      produitId: produitId,
      typeMouvement: 'transfert',
      changementQuantite: -quantite, // Négatif car c'est une sortie
      notes: notes ?? 'Transfert vers $destination',
      referenceId: referenceId,
      typeReference: 'transfert',
    );
  }

  /// Méthode privée pour créer un mouvement
  Future<StockMovement> _createMouvement({
    required int produitId,
    required String typeMouvement,
    required int changementQuantite,
    String? notes,
    int? referenceId,
    String? typeReference,
  }) async {
    try {
      final token = await _getToken();

      final body = {
        'produitId': produitId,
        'typeMouvement': typeMouvement,
        'changementQuantite': changementQuantite,
        'notes': notes,
        'referenceId': referenceId,
        'typeReference': typeReference,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/movements'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return StockMovement.fromJson(data['data']);
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la création du mouvement');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error']['message'] ?? 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création du mouvement: $e');
    }
  }

  /// Récupère les types de mouvements disponibles (avec clés de traduction)
  List<TypeMouvement> getTypesMouvements() {
    return [
      TypeMouvement(
        code: 'entree',
        libelle: 'stock_movement_type_entree',
        description: 'stock_movement_desc_entree',
        motifs: [
          'stock_reason_reception_supplier',
          'stock_reason_customer_return',
          'stock_reason_internal_production',
          'stock_reason_positive_inventory',
          'stock_reason_other_entry',
        ],
      ),
      TypeMouvement(
        code: 'sortie',
        libelle: 'stock_movement_type_sortie',
        description: 'stock_movement_desc_sortie',
        motifs: [
          'stock_reason_sale',
          'stock_reason_damage_loss',
          'stock_reason_expiration',
          'stock_reason_supplier_return',
          'stock_reason_sample',
          'stock_reason_internal_use',
          'stock_reason_other_exit',
        ],
      ),
      TypeMouvement(
        code: 'correction',
        libelle: 'stock_movement_type_correction',
        description: 'stock_movement_desc_correction',
        motifs: [
          'stock_reason_entry_error',
          'stock_reason_inventory_gap',
          'stock_reason_regularization',
        ],
      ),
      TypeMouvement(
        code: 'transfert',
        libelle: 'stock_movement_type_transfert',
        description: 'stock_movement_desc_transfert',
        motifs: [
          'stock_reason_store_transfer',
          'stock_reason_warehouse_transfer',
          'stock_reason_reorganization',
        ],
      ),
    ];
  }

  /// Récupère les motifs pour un type de mouvement
  List<String> getMotifsParType(String typeMouvement) {
    final type = getTypesMouvements().firstWhere(
      (t) => t.code == typeMouvement,
      orElse: () => TypeMouvement(code: '', libelle: '', description: '', motifs: []),
    );
    return type.motifs;
  }
}

/// Modèle pour un type de mouvement
class TypeMouvement {
  final String code;
  final String libelle;
  final String description;
  final List<String> motifs;

  TypeMouvement({
    required this.code,
    required this.libelle,
    required this.description,
    required this.motifs,
  });
}
