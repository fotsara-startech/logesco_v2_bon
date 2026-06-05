import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../config/environment_config.dart';
import '../constants/app_constants.dart';
import '../models/api_response.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

/// Client API centralisé pour toutes les communications avec le backend
class ApiClient extends GetxService {
  late http.Client _client;
  String? _authToken;
  bool _isRefreshing = false;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _client = http.Client();
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }

  /// Définit le token d'authentification
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Supprime le token d'authentification
  void clearAuthToken() {
    _authToken = null;
  }

  /// Vérifie si un token d'authentification est présent
  bool get hasAuthToken => _authToken != null;

  /// Headers par défaut pour toutes les requêtes
  Map<String, String> get _defaultHeaders {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Tente de rafraîchir le token, retourne true si réussi
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final url = Uri.parse('${EnvironmentConfig.apiBaseUrl}/auth/refresh');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final newToken = data['accessToken'] as String?;
          final newRefresh = data['refreshToken'] as String?;
          if (newToken != null) {
            _authToken = newToken;
            await _secureStorage.write(key: AppConstants.authTokenKey, value: newToken);
            if (newRefresh != null) {
              await _secureStorage.write(key: AppConstants.refreshTokenKey, value: newRefresh);
            }
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('Token refresh failed', error: e);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Exécute une requête HTTP et retente après refresh si 401
  Future<ApiResponse<T>> _executeWithRefresh<T>(
    Future<http.Response> Function() request,
    Future<http.Response> Function() retryRequest,
    String method,
    String endpoint,
    Stopwatch stopwatch,
  ) async {
    var response = await request();
    stopwatch.stop();
    AppLogger.api(method, endpoint, response.statusCode, stopwatch.elapsed);

    if (response.statusCode == 401 && _authToken != null) {
      AppLogger.debug('Token expired, attempting refresh', data: {'endpoint': endpoint});
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        stopwatch.reset();
        stopwatch.start();
        response = await retryRequest();
        stopwatch.stop();
        AppLogger.api('$method (retry)', endpoint, response.statusCode, stopwatch.elapsed);
      } else {
        // Refresh échoué → forcer déconnexion
        _forceLogout();
      }
    }

    return _handleResponse<T>(response);
  }

  /// Force la déconnexion quand le refresh échoue
  void _forceLogout() {
    clearAuthToken();
    _secureStorage.delete(key: AppConstants.authTokenKey);
    _secureStorage.delete(key: AppConstants.refreshTokenKey);
    // Naviguer vers login si GetX est disponible
    try {
      Get.offAllNamed('/login');
    } catch (_) {}
  }

  /// Requête GET générique
  Future<ApiResponse<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    final stopwatch = Stopwatch()..start();

    try {
      Uri url = Uri.parse('${EnvironmentConfig.apiBaseUrl}$endpoint');

      if (queryParameters != null && queryParameters.isNotEmpty) {
        url = url.replace(queryParameters: queryParameters.map((key, value) => MapEntry(key, value.toString())));
      }

      AppLogger.debug('API GET Request', data: {'endpoint': endpoint, 'url': url.toString()});

      return await _executeWithRefresh<T>(
        () => _client.get(url, headers: _defaultHeaders),
        () => _client.get(url, headers: _defaultHeaders),
        'GET',
        endpoint,
        stopwatch,
      );
    } on SocketException catch (e) {
      AppLogger.error('Network error on GET $endpoint', error: e);
      throw ApiException(message: 'Pas de connexion internet', code: 'NO_INTERNET', statusCode: 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error on GET $endpoint', error: e);
      throw ApiException(message: 'Erreur inattendue: ${e.toString()}', code: 'UNKNOWN_ERROR', statusCode: 500);
    }
  }

  /// Requête POST générique
  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic> data) async {
    final stopwatch = Stopwatch()..start();

    try {
      final url = Uri.parse('${EnvironmentConfig.apiBaseUrl}$endpoint');
      final body = json.encode(data);

      AppLogger.debug('API POST Request', data: {'endpoint': endpoint});

      return await _executeWithRefresh<T>(
        () => _client.post(url, headers: _defaultHeaders, body: body),
        () => _client.post(url, headers: _defaultHeaders, body: body),
        'POST',
        endpoint,
        stopwatch,
      );
    } on SocketException catch (e) {
      AppLogger.error('Network error on POST $endpoint', error: e);
      throw ApiException(message: 'Pas de connexion internet', code: 'NO_INTERNET', statusCode: 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error on POST $endpoint', error: e);
      throw ApiException(message: 'Erreur inattendue: ${e.toString()}', code: 'UNKNOWN_ERROR', statusCode: 500);
    }
  }

  /// Requête PUT générique
  Future<ApiResponse<T>> put<T>(String endpoint, Map<String, dynamic> data) async {
    final stopwatch = Stopwatch()..start();

    try {
      final url = Uri.parse('${EnvironmentConfig.apiBaseUrl}$endpoint');
      final body = json.encode(data);

      AppLogger.debug('API PUT Request', data: {'endpoint': endpoint});

      return await _executeWithRefresh<T>(
        () => _client.put(url, headers: _defaultHeaders, body: body),
        () => _client.put(url, headers: _defaultHeaders, body: body),
        'PUT',
        endpoint,
        stopwatch,
      );
    } on SocketException catch (e) {
      AppLogger.error('Network error on PUT $endpoint', error: e);
      throw ApiException(message: 'Pas de connexion internet', code: 'NO_INTERNET', statusCode: 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error on PUT $endpoint', error: e);
      throw ApiException(message: 'Erreur inattendue: ${e.toString()}', code: 'UNKNOWN_ERROR', statusCode: 500);
    }
  }

  /// Requête DELETE générique
  Future<ApiResponse<T>> delete<T>(String endpoint) async {
    final stopwatch = Stopwatch()..start();

    try {
      final url = Uri.parse('${EnvironmentConfig.apiBaseUrl}$endpoint');

      AppLogger.debug('API DELETE Request', data: {'endpoint': endpoint});

      return await _executeWithRefresh<T>(
        () => _client.delete(url, headers: _defaultHeaders),
        () => _client.delete(url, headers: _defaultHeaders),
        'DELETE',
        endpoint,
        stopwatch,
      );
    } on SocketException catch (e) {
      AppLogger.error('Network error on DELETE $endpoint', error: e);
      throw ApiException(message: 'Pas de connexion internet', code: 'NO_INTERNET', statusCode: 0);
    } on ApiException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error on DELETE $endpoint', error: e);
      throw ApiException(message: 'Erreur inattendue: ${e.toString()}', code: 'UNKNOWN_ERROR', statusCode: 500);
    }
  }

  /// Traite la réponse HTTP et retourne un ApiResponse typé
  ApiResponse<T> _handleResponse<T>(http.Response response) {
    AppLogger.debug('API Response', data: {
      'statusCode': response.statusCode,
      'headers': response.headers,
      'bodyLength': response.body.length,
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = json.decode(response.body);
        return ApiResponse<T>.success(data);
      } catch (e) {
        AppLogger.error('Failed to parse response JSON', error: e, data: {
          'statusCode': response.statusCode,
          'body': response.body.substring(0, response.body.length > 500 ? 500 : response.body.length),
        });

        throw ApiException(
          message: 'Erreur de format de réponse',
          code: 'PARSE_ERROR',
          statusCode: response.statusCode,
        );
      }
    } else {
      final exception = ApiException.fromResponse(response);

      AppLogger.error('API Error Response', data: {
        'statusCode': response.statusCode,
        'errorCode': exception.code,
        'errorMessage': exception.message,
      });

      throw exception;
    }
  }
}
