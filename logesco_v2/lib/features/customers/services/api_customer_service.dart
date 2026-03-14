import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/exceptions.dart';
import '../models/customer.dart';
import '../models/customer_transaction.dart';
import 'customer_service.dart';

/// Service pour la gestion des clients via l'API
class ApiCustomerService extends GetxService implements CustomerService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Récupère la liste des clients avec pagination et recherche
  @override
  Future<List<Customer>> getCustomers({
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
      '/customers?$queryString',
    );

    if (response.isSuccess && response.data != null) {
      final customersData = response.data!['data'] as List<dynamic>;
      return customersData.map((json) => Customer.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Récupère un client par son ID
  @override
  Future<Customer?> getCustomerById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/customers/$id');

    if (response.isSuccess && response.data != null) {
      final customerData = response.data!['data'] as Map<String, dynamic>;
      return Customer.fromJson(customerData);
    }

    return null;
  }

  /// Crée un nouveau client
  @override
  Future<Customer> createCustomer(CustomerForm customerForm) async {
    print('🔄 Création client - Données envoyées:');
    print(customerForm.toJson());

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/customers',
      customerForm.toJson(),
    );

    print('📡 Réponse serveur complète:');
    print('  - Success: ${response.isSuccess}');
    print('  - Data: ${response.data}');

    if (response.isSuccess && response.data != null) {
      try {
        // Vérifier si les données sont directement dans response.data ou dans response.data['data']
        Map<String, dynamic> customerData;
        if (response.data!.containsKey('data')) {
          customerData = response.data!['data'] as Map<String, dynamic>;
          print('📋 Données client extraites de data: $customerData');
        } else {
          customerData = response.data!;
          print('📋 Données client directes: $customerData');
        }

        return Customer.fromJson(customerData);
      } catch (e) {
        print('❌ Erreur lors de la désérialisation: $e');
        print('📋 Structure de données reçue: ${response.data}');
        rethrow;
      }
    }

    throw Exception('Erreur lors de la création du client');
  }

  /// Met à jour un client existant
  @override
  Future<Customer> updateCustomer(int id, CustomerForm customerForm) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/customers/$id',
      customerForm.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      final customerData = response.data!['data'] as Map<String, dynamic>;
      return Customer.fromJson(customerData);
    }

    throw Exception('Erreur lors de la mise à jour du client');
  }

  /// Supprime un client
  @override
  Future<bool> deleteCustomer(int id) async {
    print('🗑️ Appel API DELETE /customers/$id');

    try {
      final response = await _apiClient.delete<Map<String, dynamic>>('/customers/$id');

      print('📡 Réponse DELETE:');
      print('  - Success: ${response.isSuccess}');
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

  /// Recherche des clients par nom ou téléphone
  @override
  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty) return [];

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/customers/search?q=${Uri.encodeComponent(query)}',
    );

    if (response.isSuccess && response.data != null) {
      final customersData = response.data!['data'] as List<dynamic>;
      return customersData.map((json) => Customer.fromJson(json as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Récupère l'historique des transactions d'un client
  @override
  Future<List<CustomerTransaction>> getCustomerTransactions(int customerId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/accounts/customers/$customerId/transactions');

    print('🔍 [getCustomerTransactions] Response debug:');
    print('  - isSuccess: ${response.isSuccess}');
    print('  - data: ${response.data}');
    print('  - success: ${response.success}');

    if (response.isSuccess && response.data != null) {
      print('  - response.data type: ${response.data.runtimeType}');
      print('  - response.data keys: ${(response.data as Map).keys.toList()}');

      // CORRECTION: response.data contient toute la structure JSON de la réponse
      // Structure: { success: true, data: [...], pagination: {...} }
      // Les transactions sont dans response.data['data']

      final responseMap = response.data as Map<String, dynamic>;

      if (responseMap.containsKey('data')) {
        final transactionsData = responseMap['data'] as List<dynamic>;
        print('  - transactions count: ${transactionsData.length}');

        if (transactionsData.isNotEmpty) {
          print('  - first transaction raw: ${transactionsData[0]}');
        }

        final transactions = transactionsData.map((json) => CustomerTransaction.fromJson(json as Map<String, dynamic>)).toList();
        print('  - parsed transactions count: ${transactions.length}');
        return transactions;
      } else {
        print('  - ⚠️ No "data" key found in response');
        print('  - Available keys: ${responseMap.keys.toList()}');
      }
    } else {
      print('  - ❌ Response not successful or data is null');
      print('  - isSuccess: ${response.isSuccess}');
      print('  - success: ${response.success}');
    }

    return [];
  }

  /// Enregistre un paiement de dette pour un client
  Future<bool> payCustomerDebt(int customerId, double montant, {String? description}) async {
    try {
      print('💰 Enregistrement paiement dette pour client $customerId: $montant FCFA');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/customers/$customerId/payment',
        {
          'montant': montant,
          'description': description,
        },
      );

      print('📡 Réponse paiement dette:');
      print('  - Success: ${response.isSuccess}');
      print('  - Message: ${response.message}');

      return response.isSuccess;
    } catch (e) {
      print('❌ Erreur paiement dette: $e');
      throw Exception('Erreur lors de l\'enregistrement du paiement: $e');
    }
  }

  /// Enregistre un paiement de dette pour une vente spécifique
  Future<bool> payCustomerDebtForSale(int customerId, double montant, int venteId, {String? description}) async {
    try {
      print('💰 [Service] Enregistrement paiement dette pour client $customerId, vente $venteId: $montant FCFA');
      print('  - Description: $description');

      final requestBody = {
        'montant': montant,
        'description': description,
        'venteId': venteId,
        'typeTransactionDetail': 'paiement_dette',
      };

      print('📤 [Service] Body de la requête: $requestBody');
      print('📤 [Service] Endpoint: /customers/$customerId/payment');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/customers/$customerId/payment',
        requestBody,
      );

      print('📡 [Service] Réponse paiement dette pour vente:');
      print('  - Success: ${response.isSuccess}');
      print('  - Message: ${response.message}');
      print('  - Data: ${response.data}');

      return response.isSuccess;
    } catch (e, stackTrace) {
      print('❌ [Service] Erreur paiement dette pour vente: $e');
      print('  - Stack trace: $stackTrace');
      throw Exception('Erreur lors de l\'enregistrement du paiement: $e');
    }
  }

  /// Récupère les données du relevé de compte pour un client
  Future<Map<String, dynamic>?> getCustomerStatement(int customerId, {String format = 'a4'}) async {
    try {
      print('📄 Récupération relevé de compte pour client $customerId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/customers/$customerId/statement',
        queryParameters: {'format': format},
      );

      print('📡 Réponse relevé de compte:');
      print('  - Success: ${response.isSuccess}');
      print('  - Response data type: ${response.data.runtimeType}');
      print('  - Response data keys: ${(response.data as Map?)?.keys.toList()}');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // La réponse du backend est: { success: true, message: '...', data: {...} }
        // On extrait le 'data' qui contient les informations du relevé
        if (responseData.containsKey('data')) {
          final statementData = responseData['data'] as Map<String, dynamic>;

          print('✅ Données du relevé extraites:');
          print('  - Entreprise: ${statementData['entreprise'] != null ? 'Présente' : 'Absente'}');
          print('  - Client: ${statementData['client'] != null ? 'Présent' : 'Absent'}');
          print('  - Compte: ${statementData['compte'] != null ? 'Présent' : 'Absent'}');
          print('  - Transactions: ${(statementData['transactions'] as List?)?.length ?? 0}');

          final entrepriseMap = statementData['entreprise'] as Map<String, dynamic>?;
          print('  - Logo path: ${entrepriseMap?['logoPath']}');

          return statementData;
        } else {
          print('⚠️ Pas de clé "data" dans la réponse');
          print('  - Clés disponibles: ${responseData.keys.toList()}');
          return responseData;
        }
      }

      return null;
    } catch (e) {
      print('❌ Erreur récupération relevé: $e');
      throw Exception('Erreur lors de la récupération du relevé: $e');
    }
  }

  /// Vérifie si un client peut être supprimé (pas de ventes en cours)
  @override
  Future<bool> canDeleteCustomer(int id) async {
    try {
      print('🔍 Vérification suppression possible pour client $id');

      final response = await _apiClient.get<Map<String, dynamic>>('/customers/$id/can-delete');

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
      print('⚠️ Endpoint can-delete non disponible, autorisation par défaut');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');

      // Si l'endpoint n'existe pas (404) ou autre erreur, on autorise la suppression
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
