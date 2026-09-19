import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../models/ville.dart';
import '../models/zone.dart';
import '../models/commercial.dart';
import 'commercial_service.dart';

/// Service pour la gestion des villes/zones/commerciaux terrain via l'API
class ApiCommercialService extends GetxService implements CommercialService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // ── Villes ─────────────────────────────────────────────────────────────

  @override
  Future<List<Ville>> getVilles() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/villes');
    if (response.isSuccess && response.data != null) {
      final data = response.data!['data'] as List<dynamic>;
      return data.map((json) => Ville.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<Ville> createVille(String nom) async {
    final response = await _apiClient.post<Map<String, dynamic>>('/villes', {'nom': nom});
    if (response.isSuccess && response.data != null) {
      return Ville.fromJson(response.data!['data'] as Map<String, dynamic>);
    }
    throw Exception('Erreur lors de la création de la ville');
  }

  @override
  Future<Ville> updateVille(int id, String nom) async {
    final response = await _apiClient.put<Map<String, dynamic>>('/villes/$id', {'nom': nom});
    if (response.isSuccess && response.data != null) {
      return Ville.fromJson(response.data!['data'] as Map<String, dynamic>);
    }
    throw Exception('Erreur lors de la mise à jour de la ville');
  }

  @override
  Future<bool> deleteVille(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>('/villes/$id');
    return response.isSuccess;
  }

  // ── Zones ──────────────────────────────────────────────────────────────

  @override
  Future<List<Zone>> getZones({int? villeId}) async {
    final path = villeId != null ? '/zones?villeId=$villeId' : '/zones';
    final response = await _apiClient.get<Map<String, dynamic>>(path);
    if (response.isSuccess && response.data != null) {
      final data = response.data!['data'] as List<dynamic>;
      return data.map((json) => Zone.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<Zone> createZone(String nom, int villeId) async {
    final response = await _apiClient.post<Map<String, dynamic>>('/zones', {'nom': nom, 'villeId': villeId});
    if (response.isSuccess && response.data != null) {
      return Zone.fromJson(response.data!['data'] as Map<String, dynamic>);
    }
    throw Exception('Erreur lors de la création de la zone');
  }

  @override
  Future<Zone> updateZone(int id, {String? nom, int? villeId}) async {
    final body = <String, dynamic>{};
    if (nom != null) body['nom'] = nom;
    if (villeId != null) body['villeId'] = villeId;

    final response = await _apiClient.put<Map<String, dynamic>>('/zones/$id', body);
    if (response.isSuccess && response.data != null) {
      return Zone.fromJson(response.data!['data'] as Map<String, dynamic>);
    }
    throw Exception('Erreur lors de la mise à jour de la zone');
  }

  @override
  Future<bool> deleteZone(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>('/zones/$id');
    return response.isSuccess;
  }

  // ── Commerciaux ────────────────────────────────────────────────────────

  @override
  Future<List<Commercial>> getCommerciaux({int? zoneId, int? villeId, bool? isActive, String? search}) async {
    final queryParams = <String, String>{};
    if (zoneId != null) queryParams['zoneId'] = zoneId.toString();
    if (villeId != null) queryParams['villeId'] = villeId.toString();
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (search != null && search.isNotEmpty) queryParams['q'] = search;

    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final path = queryString.isNotEmpty ? '/commerciaux?$queryString' : '/commerciaux';

    final response = await _apiClient.get<Map<String, dynamic>>(path);
    if (response.isSuccess && response.data != null) {
      final data = response.data!['data'] as List<dynamic>;
      return data.map((json) => Commercial.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<Commercial> createCommercial(CommercialForm form) async {
    final response = await _apiClient.post<Map<String, dynamic>>('/commerciaux', form.toJson());
    if (response.isSuccess && response.data != null) {
      return Commercial.fromJson(response.data!['data'] as Map<String, dynamic>);
    }
    throw Exception('Erreur lors de la création du commercial');
  }

  @override
  Future<Commercial> updateCommercial(int id, CommercialForm form) async {
    final response = await _apiClient.put<Map<String, dynamic>>('/commerciaux/$id', form.toJson());
    if (response.isSuccess && response.data != null) {
      return Commercial.fromJson(response.data!['data'] as Map<String, dynamic>);
    }
    throw Exception('Erreur lors de la mise à jour du commercial');
  }

  @override
  Future<bool> deleteCommercial(int id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>('/commerciaux/$id');
    return response.isSuccess;
  }
}
