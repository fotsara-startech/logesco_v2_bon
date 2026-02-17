import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../models/cash_session_model.dart';

/// Service pour la gestion des sessions de caisse via API
class CashSessionService {
  static const String _endpoint = '/cash-sessions';

  /// Récupérer la session active de l'utilisateur
  static Future<CashSession?> getActiveSession() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/active'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return CashSession.fromJson(data['data']);
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur lors de la récupération de la session active: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer les caisses disponibles
  static Future<List<Map<String, dynamic>>> getAvailableCashRegisters() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/available-cash-registers'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Erreur lors de la récupération des caisses disponibles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Se connecter à une caisse
  static Future<CashSession> connectToCashRegister(int cashRegisterId, double soldeOuverture) async {
    try {
      final body = {
        'cashRegisterId': cashRegisterId,
        'soldeInitial': soldeOuverture, // Le backend attend 'soldeInitial'
      };

      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/connect'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return CashSession.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la connexion à la caisse');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Se déconnecter de la caisse (clôturer la session)
  static Future<CashSession> disconnectFromCashRegister(double soldeFermeture) async {
    try {
      final body = {
        'soldeFermeture': soldeFermeture,
      };

      print('🌐 SERVICE - Envoi requête disconnect:');
      print('   URL: ${ApiConfig.currentBaseUrl}$_endpoint/disconnect');
      print('   Body: ${json.encode(body)}');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/disconnect'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      print('🌐 SERVICE - Réponse reçue:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🌐 SERVICE - Données parsées:');
        print('   data[\'data\']: ${data['data']}');

        final session = CashSession.fromJson(data['data']);

        print('🌐 SERVICE - Session créée:');
        print('   ecart: ${session.ecart}');
        print('   Type: ${session.ecart.runtimeType}');

        return session;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la déconnexion de la caisse');
      }
    } catch (e) {
      print('❌ SERVICE - Erreur: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer l'historique des sessions
  static Future<List<CashSession>> getSessionHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (userId != null) {
        queryParams['userId'] = userId.toString();
      }

      final uri = Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/history').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(
            uri,
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> sessions = data['data'] ?? [];
        return sessions.map((json) => CashSession.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération de l\'historique: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Récupérer les statistiques des sessions
  static Future<Map<String, dynamic>> getSessionStats() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/stats'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erreur lors de la récupération des statistiques: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Vérifier la disponibilité d'une caisse
  static Future<bool> checkCashRegisterAvailability(int cashRegisterId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}$_endpoint/check-availability/$cashRegisterId'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['available'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
