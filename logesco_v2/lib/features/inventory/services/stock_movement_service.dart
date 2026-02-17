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

  /// Récupère les types de mouvements disponibles
  List<TypeMouvement> getTypesMouvements() {
    return [
      TypeMouvement(
        code: 'entree',
        libelle: 'Entrée de stock',
        description: 'Ajout de produits au stock',
        motifs: [
          'Réception fournisseur',
          'Retour client',
          'Production interne',
          'Inventaire positif',
          'Autre entrée',
        ],
      ),
      TypeMouvement(
        code: 'sortie',
        libelle: 'Sortie de stock',
        description: 'Retrait de produits du stock',
        motifs: [
          'Vente',
          'Casse/Perte',
          'Péremption',
          'Retour fournisseur',
          'Échantillon',
          'Usage interne',
          'Autre sortie',
        ],
      ),
      TypeMouvement(
        code: 'correction',
        libelle: 'Correction de stock',
        description: 'Ajustement suite à un écart d\'inventaire',
        motifs: [
          'Erreur de saisie',
          'Écart d\'inventaire',
          'Régularisation',
        ],
      ),
      TypeMouvement(
        code: 'transfert',
        libelle: 'Transfert de stock',
        description: 'Déplacement vers un autre emplacement',
        motifs: [
          'Transfert magasin',
          'Transfert entrepôt',
          'Réorganisation',
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