import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../models/boutique_model.dart';
import '../models/user_boutique_assignment_model.dart';
import '../models/stock_transfert_model.dart';

class BoutiqueService {
  final ApiClient _api = Get.find<ApiClient>();

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Extrait l'objet depuis { success: true, data: {...} } ou retourne directement
  Map<String, dynamic> _data(dynamic response) {
    if (response is Map<String, dynamic>) {
      // Format API : { success: true, data: {...} }
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {};
  }

  /// Extrait la liste depuis { success: true, data: [...] } ou retourne directement
  List<dynamic> _list(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      // Format API : { success: true, data: [...] }
      if (response.containsKey('data') && response['data'] is List) {
        return response['data'] as List<dynamic>;
      }
    }
    return [];
  }

  // ─── Boutiques ───────────────────────────────────────────────────────────────

  Future<List<Boutique>> getBoutiques() async {
    final response = await _api.get<dynamic>('/boutiques');
    return _list(response.data).map((e) => Boutique.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Boutique> getBoutique(int id) async {
    final response = await _api.get<dynamic>('/boutiques/$id');
    return Boutique.fromJson(_data(response.data));
  }

  Future<Boutique> createBoutique({
    required String nom,
    String? adresse,
    String? telephone,
    String? email,
    String? description,
  }) async {
    final response = await _api.post<dynamic>('/boutiques', {
      'nom': nom,
      if (adresse != null) 'adresse': adresse,
      if (telephone != null) 'telephone': telephone,
      if (email != null) 'email': email,
      if (description != null) 'description': description,
    });
    return Boutique.fromJson(_data(response.data));
  }

  Future<Boutique> updateBoutique(int id, Map<String, dynamic> data) async {
    final response = await _api.put<dynamic>('/boutiques/$id', data);
    return Boutique.fromJson(_data(response.data));
  }

  Future<void> deleteBoutique(int id) async {
    await _api.delete<dynamic>('/boutiques/$id');
  }

  // ─── Assignations ────────────────────────────────────────────────────────────

  Future<List<UserBoutiqueAssignment>> getBoutiqueUsers(int boutiqueId) async {
    final response = await _api.get<dynamic>('/boutiques/$boutiqueId/users');
    return _list(response.data).map((e) => UserBoutiqueAssignment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserBoutiqueAssignment> assignUser({
    required int boutiqueId,
    required int utilisateurId,
    int? roleId,
  }) async {
    final response = await _api.post<dynamic>('/boutiques/$boutiqueId/users', {
      'utilisateurId': utilisateurId,
      if (roleId != null) 'roleId': roleId,
    });
    return UserBoutiqueAssignment.fromJson(_data(response.data));
  }

  Future<void> removeUser(int boutiqueId, int utilisateurId) async {
    await _api.delete<dynamic>('/boutiques/$boutiqueId/users/$utilisateurId');
  }

  // ─── Stock boutique ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBoutiqueStock(int boutiqueId, {String? search, int page = 1, int limit = 50}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await _api.get<dynamic>('/boutiques/$boutiqueId/stock', queryParameters: params);
    // La réponse est { success, data: { stocks: [...], total: n } }
    return _data(response.data);
  }

  // ─── Transferts ──────────────────────────────────────────────────────────────

  Future<List<StockTransfert>> getTransferts({int? boutiqueId, int page = 1, int limit = 50}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (boutiqueId != null) params['boutiqueId'] = boutiqueId;
    final response = await _api.get<dynamic>('/boutiques/transferts/list', queryParameters: params);
    final data = _data(response.data);
    final list = data['transferts'] as List<dynamic>? ?? [];
    return list.map((e) => StockTransfert.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StockTransfert> createTransfert({
    required int sourceBoutiqueId,
    required int destBoutiqueId,
    required int produitId,
    required int quantite,
    String? notes,
  }) async {
    final response = await _api.post<dynamic>('/boutiques/transferts', {
      'sourceBoutiqueId': sourceBoutiqueId,
      'destBoutiqueId': destBoutiqueId,
      'produitId': produitId,
      'quantite': quantite,
      if (notes != null) 'notes': notes,
    });
    return StockTransfert.fromJson(_data(response.data));
  }

  // ─── Dashboard ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardConsolide({String? dateDebut, String? dateFin}) async {
    final params = <String, dynamic>{};
    if (dateDebut != null) params['dateDebut'] = dateDebut;
    if (dateFin != null) params['dateFin'] = dateFin;
    final response = await _api.get<dynamic>('/boutiques/dashboard/consolidated', queryParameters: params.isNotEmpty ? params : null);
    return _data(response.data);
  }

  Future<Map<String, dynamic>> getBoutiqueDashboard(int boutiqueId, {String? dateDebut, String? dateFin}) async {
    final params = <String, dynamic>{};
    if (dateDebut != null) params['dateDebut'] = dateDebut;
    if (dateFin != null) params['dateFin'] = dateFin;
    final response = await _api.get<dynamic>('/boutiques/$boutiqueId/dashboard', queryParameters: params.isNotEmpty ? params : null);
    return _data(response.data);
  }
}
