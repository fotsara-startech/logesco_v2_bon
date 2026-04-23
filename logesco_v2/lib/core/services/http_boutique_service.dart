import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'boutique_context_service.dart';

/// Service HTTP qui injecte automatiquement le boutiqueId dans toutes les requêtes
class HttpBoutiqueService extends GetxService {
  final BoutiqueContextService _boutiqueContext = Get.find<BoutiqueContextService>();

  /// GET avec injection automatique du boutiqueId
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUriWithBoutiqueId(url, queryParameters);
    final finalHeaders = _addBoutiqueIdToHeaders(headers);

    print('🌐 GET: $uri');
    print('📦 Headers: $finalHeaders');

    return await http.get(uri, headers: finalHeaders);
  }

  /// POST avec injection automatique du boutiqueId
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
  }) async {
    final uri = _buildUriWithBoutiqueId(url, queryParameters);
    final finalHeaders = _addBoutiqueIdToHeaders(headers);
    final finalBody = _addBoutiqueIdToBody(body);

    print('🌐 POST: $uri');
    print('📦 Headers: $finalHeaders');
    print('📄 Body: $finalBody');

    return await http.post(uri, headers: finalHeaders, body: finalBody);
  }

  /// PUT avec injection automatique du boutiqueId
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
  }) async {
    final uri = _buildUriWithBoutiqueId(url, queryParameters);
    final finalHeaders = _addBoutiqueIdToHeaders(headers);
    final finalBody = _addBoutiqueIdToBody(body);

    print('🌐 PUT: $uri');
    print('📦 Headers: $finalHeaders');
    print('📄 Body: $finalBody');

    return await http.put(uri, headers: finalHeaders, body: finalBody);
  }

  /// DELETE avec injection automatique du boutiqueId
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUriWithBoutiqueId(url, queryParameters);
    final finalHeaders = _addBoutiqueIdToHeaders(headers);

    print('🌐 DELETE: $uri');
    print('📦 Headers: $finalHeaders');

    return await http.delete(uri, headers: finalHeaders);
  }

  /// Construit l'URI avec le boutiqueId dans les query parameters
  Uri _buildUriWithBoutiqueId(String url, Map<String, String>? queryParameters) {
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(queryParameters ?? {});

    final boutiqueId = _boutiqueContext.activeBoutiqueId;
    if (boutiqueId != null) {
      params['boutiqueId'] = boutiqueId.toString();
      print('🏪 Query param boutiqueId ajouté: $boutiqueId');
    }

    return uri.replace(queryParameters: params.isNotEmpty ? params : null);
  }

  /// Ajoute le boutiqueId aux headers
  Map<String, String> _addBoutiqueIdToHeaders(Map<String, String>? headers) {
    final finalHeaders = Map<String, String>.from(headers ?? {});

    final boutiqueId = _boutiqueContext.activeBoutiqueId;
    if (boutiqueId != null) {
      finalHeaders['X-Boutique-Id'] = boutiqueId.toString();
      print('🏪 Header X-Boutique-Id ajouté: $boutiqueId');
    }

    return finalHeaders;
  }

  /// Ajoute le boutiqueId au body (si c'est du JSON)
  String? _addBoutiqueIdToBody(Object? body) {
    if (body == null) return null;

    // Si c'est déjà une string, essayer de la parser comme JSON
    if (body is String) {
      try {
        final jsonData = json.decode(body) as Map<String, dynamic>;
        final updatedData = _boutiqueContext.injectBoutiqueId(jsonData);
        return json.encode(updatedData);
      } catch (e) {
        // Si ce n'est pas du JSON, retourner tel quel
        return body;
      }
    }

    // Si c'est un Map, l'injecter directement
    if (body is Map<String, dynamic>) {
      final updatedData = _boutiqueContext.injectBoutiqueId(body);
      return json.encode(updatedData);
    }

    // Pour les autres types, convertir en string
    return body.toString();
  }
}
