import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/exceptions.dart';
import '../models/supplier.dart';
import 'supplier_service.dart';

/// Service pour la gestion des fournisseurs via l'API
class ApiSupplierService extends GetxService implements SupplierService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Récupère la liste des fournisseurs avec pagination et recherche
  @override
  Future<List<Supplier>> getSuppliers({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }

    final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/suppliers?$queryString',
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne les fournisseurs directement dans 'data'
      final suppliersData = response.data!['data'] as List<dynamic>;
      return suppliersData.map((json) => Supplier.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Récupère un fournisseur par son ID
  @override
  Future<Supplier?> getSupplierById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/suppliers/$id');

    if (response.isSuccess && response.data != null) {
      // Le backend retourne le fournisseur directement dans 'data'
      final supplierData = response.data!['data'] as Map<String, dynamic>;
      return Supplier.fromJson(supplierData);
    }

    return null;
  }

  /// Crée un nouveau fournisseur
  @override
  Future<Supplier> createSupplier(SupplierForm supplierForm) async {
    print('🔄 Création fournisseur - Données envoyées:');
    print(supplierForm.toJson());

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/suppliers',
      supplierForm.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne le fournisseur créé directement dans 'data'
      final supplierData = response.data!['data'] as Map<String, dynamic>;
      return Supplier.fromJson(supplierData);
    }

    throw Exception('Erreur lors de la création du fournisseur');
  }

  /// Met à jour un fournisseur existant
  @override
  Future<Supplier> updateSupplier(int id, SupplierForm supplierForm) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/suppliers/$id',
      supplierForm.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne le fournisseur mis à jour directement dans 'data'
      final supplierData = response.data!['data'] as Map<String, dynamic>;
      return Supplier.fromJson(supplierData);
    }

    throw Exception('Erreur lors de la mise à jour du fournisseur');
  }

  /// Supprime un fournisseur
  @override
  Future<bool> deleteSupplier(int id) async {
    print('🗑️ Appel API DELETE /suppliers/$id');
    print('🔑 Token présent: ${_apiClient.hasAuthToken}');

    try {
      final response = await _apiClient.delete<Map<String, dynamic>>('/suppliers/$id');

      print('📡 Réponse DELETE:');
      print('  - Success: ${response.isSuccess}');
      print('  - Status Code: ${response.data}');
      print('  - Data: ${response.data}');

      if (response.isSuccess) {
        print('✅ Suppression réussie');
        return true;
      } else {
        print('❌ Suppression échouée - réponse non-success');
        return false;
      }
    } catch (e) {
      print('❌ Erreur DELETE: $e');
      if (e is ApiException) {
        print('  - Message: ${e.message}');
        print('  - Code: ${e.code}');
        print('  - Status: ${e.statusCode}');
      }
      rethrow;
    }
  }

  /// Recherche des fournisseurs par nom ou téléphone
  @override
  Future<List<Supplier>> searchSuppliers(String query) async {
    if (query.isEmpty) return [];

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/suppliers/search?q=${Uri.encodeComponent(query)}',
    );

    if (response.isSuccess && response.data != null) {
      // Le backend retourne les fournisseurs directement dans 'data'
      final suppliersData = response.data!['data'] as List<dynamic>;
      return suppliersData.map((json) => Supplier.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Récupère l'historique des transactions d'un fournisseur
  @override
  Future<List<SupplierTransaction>> getSupplierTransactions(int supplierId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/accounts/suppliers/$supplierId/transactions');

    if (response.isSuccess && response.data != null) {
      // Le backend retourne les transactions directement dans 'data'
      final transactionsData = response.data!['data'] as List<dynamic>;
      return transactionsData.map((json) => SupplierTransaction.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Paie un fournisseur (enregistre un paiement)
  @override
  Future<bool> paySupplier(
    int supplierId,
    double montant, {
    String? description,
  }) async {
    print('💰 Appel API POST /accounts/suppliers/$supplierId/transactions');
    print('  - Montant: $montant');
    print('  - Description: $description');

    try {
      final body = {
        'montant': montant,
        'typeTransaction': 'paiement',
        if (description != null) 'description': description,
      };

      print('📤 Body: $body');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/accounts/suppliers/$supplierId/transactions',
        body,
      );

      print('📡 Réponse paiement:');
      print('  - Success: ${response.isSuccess}');
      print('  - Data: ${response.data}');

      if (response.isSuccess) {
        print('✅ Paiement enregistré avec succès');
        return true;
      } else {
        print('❌ Paiement échoué - réponse non-success');
        return false;
      }
    } catch (e) {
      print('❌ Erreur paiement: $e');
      if (e is ApiException) {
        print('  - Message: ${e.message}');
        print('  - Code: ${e.code}');
        print('  - Status: ${e.statusCode}');
      }
      rethrow;
    }
  }

  /// Récupère les commandes impayées d'un fournisseur
  @override
  Future<List<UnpaidProcurement>> getUnpaidProcurements(int supplierId) async {
    print('🔍 Appel API GET /accounts/suppliers/$supplierId/unpaid-procurements');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/accounts/suppliers/$supplierId/unpaid-procurements',
      );

      print('📡 Réponse commandes impayées:');
      print('  - Success: ${response.isSuccess}');

      if (response.isSuccess && response.data != null) {
        final procurementsData = response.data!['data'] as List<dynamic>;
        print('  - Nombre de commandes: ${procurementsData.length}');
        return procurementsData.map((json) => UnpaidProcurement.fromJson(json as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Erreur récupération commandes impayées: $e');
      rethrow;
    }
  }

  /// Récupère les données du relevé de compte fournisseur
  @override
  Future<Map<String, dynamic>?> getSupplierStatement(int supplierId) async {
    print('� Appel API GET /accounts/suppliers/$supplierId/statement');

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/accounts/suppliers/$supplierId/statement',
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('❌ Erreur récupération relevé: $e');
      rethrow;
    }
  }

  /// Paie une commande spécifique d'un fournisseur
  @override
  Future<bool> paySupplierForProcurement(
    int supplierId,
    double montant,
    int procurementId, {
    String? description,
    bool createFinancialMovement = false,
  }) async {
    print('💰 Appel API POST /accounts/suppliers/$supplierId/transactions (commande spécifique)');
    print('  - Montant: $montant');
    print('  - Commande ID: $procurementId');
    print('  - Description: $description');
    print('  - Créer mouvement financier: $createFinancialMovement');

    try {
      final body = {
        'montant': montant,
        'typeTransaction': 'paiement',
        'referenceType': 'approvisionnement',
        'referenceId': procurementId,
        if (description != null) 'description': description,
        'createFinancialMovement': createFinancialMovement,
      };

      print('📤 Body: $body');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/accounts/suppliers/$supplierId/transactions',
        body,
      );

      print('📡 Réponse paiement commande:');
      print('  - Success: ${response.isSuccess}');
      print('  - Data: ${response.data}');

      if (response.isSuccess) {
        print('✅ Paiement commande enregistré avec succès');
        return true;
      } else {
        print('❌ Paiement commande échoué - réponse non-success');
        return false;
      }
    } catch (e) {
      print('❌ Erreur paiement commande: $e');
      if (e is ApiException) {
        print('  - Message: ${e.message}');
        print('  - Code: ${e.code}');
        print('  - Status: ${e.statusCode}');
      }
      rethrow;
    }
  }

  /// Vérifie si un fournisseur peut être supprimé (pas de commandes en cours)
  @override
  Future<bool> canDeleteSupplier(int id) async {
    try {
      print('🔍 Vérification suppression possible pour fournisseur $id');

      final response = await _apiClient.get<Map<String, dynamic>>('/suppliers/$id/can-delete');

      print('📡 Réponse can-delete:');
      print('  - Success: ${response.isSuccess}');
      print('  - Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>;
        final canDelete = responseData['can_delete'] as bool? ?? true;
        print('✅ Peut supprimer: $canDelete');
        return canDelete;
      }

      // Si l'endpoint n'existe pas ou échoue, on autorise la suppression
      // Le serveur gérera les contraintes lors de la suppression effective
      print('⚠️ Endpoint can-delete non disponible, autorisation par défaut');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');

      // Si l'endpoint n'existe pas (404) ou autre erreur, on autorise la suppression
      // Le serveur gérera les contraintes lors de la suppression effective
      if (e is ApiException && e.statusCode == 404) {
        print('📝 Endpoint can-delete non implémenté, autorisation par défaut');
        return true;
      }

      // Pour les autres erreurs, on autorise aussi mais on log
      print('⚠️ Erreur inattendue, autorisation par défaut');
      return true;
    }
  }
}
