import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../config/environment_config.dart';
import '../models/api_response.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

/// Client API centralisé pour toutes les communications avec le backend
class ApiClient extends GetxService {
  late http.Client _client;
  String? _authToken;

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

  /// Requête GET générique
  Future<ApiResponse<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    final stopwatch = Stopwatch()..start();

    try {
      Uri url = Uri.parse('${EnvironmentConfig.apiBaseUrl}$endpoint');

      if (queryParameters != null && queryParameters.isNotEmpty) {
        url = url.replace(queryParameters: queryParameters.map((key, value) => MapEntry(key, value.toString())));
      }

      AppLogger.debug('API GET Request', data: {
        'endpoint': endpoint,
        'url': url.toString(),
        'queryParameters': queryParameters,
      });

      final response = await _client.get(url, headers: _defaultHeaders);

      stopwatch.stop();
      AppLogger.api('GET', endpoint, response.statusCode, stopwatch.elapsed);

      return _handleResponse<T>(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      AppLogger.error('Network error on GET $endpoint', error: e);

      throw ApiException(
        message: 'Pas de connexion internet',
        code: 'NO_INTERNET',
        statusCode: 0,
      );
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Unexpected error on GET $endpoint', error: e);

      throw ApiException(
        message: 'Erreur inattendue: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Requête POST générique
  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic> data) async {
    final stopwatch = Stopwatch()..start();

    try {
      final url = Uri.parse('${EnvironmentConfig.apiBaseUrl}$endpoint');

      AppLogger.debug('API POST Request', data: {
        'endpoint': endpoint,
        'url': url.toString(),
        'payload': data,
      });

      final response = await _client.post(
        url,
        headers: _defaultHeaders,
        body: json.encode(data),
      );

      stopwatch.stop();
      AppLogger.api('POST', endpoint, response.statusCode, stopwatch.elapsed);

      return _handleResponse<T>(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      AppLogger.error('Network error on POST $endpoint', error: e);

      throw ApiException(
        message: 'Pas de connexion internet',
        code: 'NO_INTERNET',
        statusCode: 0,
      );
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Unexpected error on POST $endpoint', error: e);

      throw ApiException(
        message: 'Erreur inattendue: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Requête PUT générique
  Future<ApiResponse<T>> put<T>(String endpoint, Map<String, dynamic> data) async {
    final stopwatch = Stopwatch()..start();

    try {
      final url = Uri.parse('${EnvironmentConfig.apiBaseUrl}$endpoint');

      AppLogger.debug('API PUT Request', data: {
        'endpoint': endpoint,
        'url': url.toString(),
        'payload': data,
      });

      final response = await _client.put(
        url,
        headers: _defaultHeaders,
        body: json.encode(data),
      );

      stopwatch.stop();
      AppLogger.api('PUT', endpoint, response.statusCode, stopwatch.elapsed);

      return _handleResponse<T>(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      AppLogger.error('Network error on PUT $endpoint', error: e);

      throw ApiException(
        message: 'Pas de connexion internet',
        code: 'NO_INTERNET',
        statusCode: 0,
      );
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Unexpected error on PUT $endpoint', error: e);

      throw ApiException(
        message: 'Erreur inattendue: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Requête DELETE générique
  Future<ApiResponse<T>> delete<T>(String endpoint) async {
    final stopwatch = Stopwatch()..start();

    try {
      final url = Uri.parse('${EnvironmentConfig.apiBaseUrl}$endpoint');

      AppLogger.debug('API DELETE Request', data: {
        'endpoint': endpoint,
        'url': url.toString(),
      });

      final response = await _client.delete(url, headers: _defaultHeaders);

      stopwatch.stop();
      AppLogger.api('DELETE', endpoint, response.statusCode, stopwatch.elapsed);

      return _handleResponse<T>(response);
    } on SocketException catch (e) {
      stopwatch.stop();
      AppLogger.error('Network error on DELETE $endpoint', error: e);

      throw ApiException(
        message: 'Pas de connexion internet',
        code: 'NO_INTERNET',
        statusCode: 0,
      );
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Unexpected error on DELETE $endpoint', error: e);

      throw ApiException(
        message: 'Erreur inattendue: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
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
