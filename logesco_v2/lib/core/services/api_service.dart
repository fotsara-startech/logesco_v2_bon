import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';

class ApiService {
  final String baseUrl;
  final Map<String, String> _defaultHeaders;
  String? _authToken;

  ApiService({
    required this.baseUrl,
    Map<String, String>? defaultHeaders,
  }) : _defaultHeaders = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?defaultHeaders,
        };

  /// Définit le token d'authentification
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Supprime le token d'authentification
  void clearAuthToken() {
    _authToken = null;
  }

  /// Obtient les en-têtes avec authentification
  Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Construit l'URL complète avec les paramètres de requête
  String _buildUrl(String endpoint, {Map<String, String>? queryParams}) {
    var url = '$baseUrl$endpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      final query = queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
      url += '?$query';
    }

    return url;
  }

  /// Traite la réponse HTTP
  ApiResponse<dynamic> _processResponse(http.Response response) {
    try {
      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<dynamic>(
          success: jsonData['success'] ?? true,
          data: jsonData['data'],
          message: jsonData['message'],
          timestamp: jsonData['timestamp'] ?? DateTime.now().toIso8601String(),
          pagination: jsonData['pagination'] != null ? Pagination.fromJson(jsonData['pagination']) : null,
        );
      } else {
        return ApiResponse<dynamic>(
          success: false,
          message: jsonData['message'] ?? 'Erreur ${response.statusCode}',
          errors: jsonData['errors'] != null ? (jsonData['errors'] as List).map((e) => ApiError.fromJson(e)).toList() : null,
          timestamp: jsonData['timestamp'] ?? DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return ApiResponse<dynamic>(
        success: false,
        message: 'Erreur de parsing: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Gère les erreurs de réseau
  ApiResponse<dynamic> _handleNetworkError(dynamic error) {
    String message;

    if (error is SocketException) {
      message = 'Erreur de connexion réseau';
    } else if (error is HttpException) {
      message = 'Erreur HTTP: ${error.message}';
    } else if (error is FormatException) {
      message = 'Erreur de format de données';
    } else {
      message = 'Erreur inconnue: $error';
    }

    return ApiResponse<dynamic>(
      success: false,
      message: message,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Requête GET
  Future<ApiResponse<dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams: queryParams);
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Requête POST
  Future<ApiResponse<dynamic>> post(
    String endpoint,
    dynamic body, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams: queryParams);
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(body),
      );

      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Requête PUT
  Future<ApiResponse<dynamic>> put(
    String endpoint,
    dynamic body, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams: queryParams);
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(body),
      );

      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Requête DELETE
  Future<ApiResponse<dynamic>> delete(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams: queryParams);
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      );

      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Requête PATCH
  Future<ApiResponse<dynamic>> patch(
    String endpoint,
    dynamic body, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams: queryParams);
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(body),
      );

      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Upload de fichier
  Future<ApiResponse<dynamic>> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? fields,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

      // Ajouter les en-têtes (sauf Content-Type qui sera défini automatiquement)
      final headers = Map<String, String>.from(_headers);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Ajouter le fichier
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      // Ajouter les champs supplémentaires
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }
}
