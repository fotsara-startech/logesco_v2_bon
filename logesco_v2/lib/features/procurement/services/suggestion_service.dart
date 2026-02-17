/**
 * Service pour les suggestions d'approvisionnement basées sur les ventes et stocks
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../products/models/product.dart';

class ProcurementSuggestionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = '${ApiConfig.baseUrl}/procurement';

  /// Récupère le token d'authentification
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: AppConstants.authTokenKey);
  }

  /// Récupère les suggestions d'approvisionnement
  Future<List<SuggestionApprovisionnement>> getSuggestions({
    int? fournisseurId,
    int periodeAnalyse = 30, // jours
    double seuilRotation = 0.5, // seuil de rotation de stock
  }) async {
    try {
      final queryParams = <String, String>{
        'periodeAnalyse': periodeAnalyse.toString(),
        'seuilRotation': seuilRotation.toString(),
      };

      if (fournisseurId != null) {
        queryParams['fournisseurId'] = fournisseurId.toString();
      }

      final uri = Uri.parse('$_baseUrl/suggestions').replace(queryParameters: queryParams);
      final token = await _getToken();

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final suggestions = (data['data']['suggestions'] as List).map((json) => SuggestionApprovisionnement.fromJson(json)).toList();
          return suggestions;
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la récupération des suggestions');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des suggestions: $e');
    }
  }

  /// Génère automatiquement une commande basée sur les suggestions
  Future<Map<String, dynamic>> genererCommandeAutomatique({
    required int fournisseurId,
    required List<SuggestionApprovisionnement> suggestions,
    String modePaiement = 'credit',
    DateTime? dateLivraisonPrevue,
    String? notes,
  }) async {
    try {
      final token = await _getToken();

      // Préparer les données des suggestions avec quantités modifiées
      final suggestionsData = suggestions
          .map((suggestion) => {
                'id': suggestion.id,
                'produitId': suggestion.produit.id,
                'quantiteSuggeree': suggestion.quantiteSuggeree,
                'coutUnitaireEstime': suggestion.coutUnitaireEstime,
                'montantTotal': suggestion.montantTotal,
              })
          .toList();

      final body = {
        'fournisseurId': fournisseurId,
        'suggestions': suggestionsData,
        'modePaiement': modePaiement,
        'dateLivraisonPrevue': dateLivraisonPrevue?.toIso8601String(),
        'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/generate-from-suggestions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['error']['message'] ?? 'Erreur lors de la génération de la commande');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error']['message'] ?? 'Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la génération de la commande: $e');
    }
  }
}

/// Modèle pour une suggestion d'approvisionnement
class SuggestionApprovisionnement {
  final int id;
  final Product produit;
  final int stockActuel;
  final int seuilMinimum;
  final double moyenneVentesJournalieres;
  final double quantiteSuggeree; // Changed from int to double
  final double coutUnitaireEstime;
  final double montantTotal;
  final String priorite; // 'haute', 'moyenne', 'faible'
  final String raison;
  final int joursStockRestant;
  final double tauxRotation;

  SuggestionApprovisionnement({
    required this.id,
    required this.produit,
    required this.stockActuel,
    required this.seuilMinimum,
    required this.moyenneVentesJournalieres,
    required this.quantiteSuggeree,
    required this.coutUnitaireEstime,
    required this.montantTotal,
    required this.priorite,
    required this.raison,
    required this.joursStockRestant,
    required this.tauxRotation,
  });

  factory SuggestionApprovisionnement.fromJson(Map<String, dynamic> json) {
    return SuggestionApprovisionnement(
      id: json['id'] ?? 0,
      produit: Product.fromJson(json['produit']),
      stockActuel: json['stockActuel'] ?? 0,
      seuilMinimum: json['seuilMinimum'] ?? 0,
      moyenneVentesJournalieres: (json['moyenneVentesJournalieres'] ?? 0.0).toDouble(),
      quantiteSuggeree: (json['quantiteSuggeree'] ?? 0.0).toDouble(), // Changed to handle double
      coutUnitaireEstime: (json['coutUnitaireEstime'] ?? 0.0).toDouble(),
      montantTotal: (json['montantTotal'] ?? 0.0).toDouble(),
      priorite: json['priorite'] ?? 'moyenne',
      raison: json['raison'] ?? '',
      joursStockRestant: json['joursStockRestant'] ?? 0,
      tauxRotation: (json['tauxRotation'] ?? 0.0).toDouble(),
    );
  }

  /// Indique si la suggestion est urgente
  bool get estUrgente => priorite == 'haute' || joursStockRestant <= 3;

  /// Indique si le produit est en rupture
  bool get estEnRupture => stockActuel <= 0;

  /// Indique si le produit est sous le seuil minimum
  bool get estSousSeuilMinimum => stockActuel <= seuilMinimum;
}

/// Priorités de suggestion
enum PrioriteSuggestion {
  haute('haute', 'Haute'),
  moyenne('moyenne', 'Moyenne'),
  faible('faible', 'Faible');

  const PrioriteSuggestion(this.value, this.label);
  final String value;
  final String label;

  static PrioriteSuggestion fromString(String value) {
    return PrioriteSuggestion.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => PrioriteSuggestion.moyenne,
    );
  }
}
