import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/cash_session_model.dart';

/// Service pour la gestion des sessions de caisse via API
class CashSessionService {
  static const String _endpoint = '/cash-sessions';

  /// Retourne les headers avec le token d'authentification
  static Future<Map<String, String>> _authHeaders() async {
    final authService = Get.find<AuthService>();
    final token = await authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'LOGESCO-Mobile/1.0.0',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Récupérer la session active de l'utilisateur
  static Future<CashSession?> getActiveSession() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/active'),
            headers: headers,
          )
          .timeout(AppConfig.receiveTimeout);

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
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/available-cash-registers'),
            headers: headers,
          )
          .timeout(AppConfig.receiveTimeout);

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
      final headers = await _authHeaders();
      final body = {
        'cashRegisterId': cashRegisterId,
        'soldeInitial': soldeOuverture,
      };

      final response = await http
          .post(
            Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/connect'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(AppConfig.receiveTimeout);

      // 201 = nouvelle session, 200 = session existante reprise
      if (response.statusCode == 201 || response.statusCode == 200) {
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

  /// Forcer la fermeture de la session active (pour nettoyer les sessions orphelines)
  static Future<void> forceCloseSession() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/force-close'),
            headers: headers,
            body: json.encode({}),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Erreur lors de la fermeture forcée');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Se déconnecter de la caisse (clôturer la session)
  static Future<CashSession> disconnectFromCashRegister(double soldeFermeture) async {
    try {
      final headers = await _authHeaders();
      final body = {'soldeFermeture': soldeFermeture};

      final response = await http
          .post(
            Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/disconnect'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CashSession.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message'] ?? 'Erreur lors de la déconnexion de la caisse');
      }
    } catch (e) {
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
      final headers = await _authHeaders();
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (userId != null) queryParams['userId'] = userId.toString();

      final uri = Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/history').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri, headers: headers).timeout(AppConfig.receiveTimeout);

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
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/stats'),
            headers: headers,
          )
          .timeout(AppConfig.receiveTimeout);

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

  /// Lister toutes les sessions actives (admin)
  static Future<List<Map<String, dynamic>>> getAllActiveSessions() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConfig.currentBaseUrl}/cash-sessions/all-active'),
            headers: headers,
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Nettoyer les sessions orphelines (admin)
  static Future<bool> cleanupOrphanSessions() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/cleanup-orphans'),
            headers: headers,
            body: json.encode({}),
          )
          .timeout(AppConfig.receiveTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fermer une session spécifique par ID (admin)
  static Future<bool> adminCloseSession(int sessionId) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse('${AppConfig.currentBaseUrl}/cash-sessions/admin-close/$sessionId'),
            headers: headers,
            body: json.encode({}),
          )
          .timeout(AppConfig.receiveTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Vérifier la disponibilité d'une caisse
  static Future<bool> checkCashRegisterAvailability(int cashRegisterId) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConfig.currentBaseUrl}$_endpoint/check-availability/$cashRegisterId'),
            headers: headers,
          )
          .timeout(AppConfig.receiveTimeout);

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
