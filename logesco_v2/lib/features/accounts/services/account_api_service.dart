import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/exceptions.dart';
import '../models/account.dart';
import 'account_service.dart';

/// Implémentation API du service de gestion des comptes
class AccountApiService implements AccountService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  @override
  Future<List<CompteClient>> getComptesClients({
    String? search,
    double? soldeMin,
    double? soldeMax,
    bool? enDepassement,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }
      if (soldeMin != null) {
        queryParams['soldeMin'] = soldeMin;
      }
      if (soldeMax != null) {
        queryParams['soldeMax'] = soldeMax;
      }
      if (enDepassement != null) {
        queryParams['enDepassement'] = enDepassement;
      }

      final response = await _apiClient.get(
        '/accounts/customers',
        queryParameters: queryParams,
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> comptesJson = data['data'] ?? [];

        return comptesJson.map((json) => CompteClient.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_recuperation_comptes_clients'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_recuperation_comptes_clients'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<CompteFournisseur>> getComptesFournisseurs({
    String? search,
    double? soldeMin,
    double? soldeMax,
    bool? enDepassement,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }
      if (soldeMin != null) {
        queryParams['soldeMin'] = soldeMin;
      }
      if (soldeMax != null) {
        queryParams['soldeMax'] = soldeMax;
      }
      if (enDepassement != null) {
        queryParams['enDepassement'] = enDepassement;
      }

      final response = await _apiClient.get(
        '/accounts/suppliers',
        queryParameters: queryParams,
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> comptesJson = data['data'] ?? [];

        return comptesJson.map((json) => CompteFournisseur.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_recuperation_comptes_fournisseurs'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_recuperation_comptes_fournisseurs'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CompteClient?> getSoldeClient(int clientId) async {
    try {
      final response = await _apiClient.get('/accounts/customers/$clientId/balance');

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        return CompteClient.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_recuperation_solde_client'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CompteFournisseur?> getSoldeFournisseur(int fournisseurId) async {
    try {
      final response = await _apiClient.get('/accounts/suppliers/$fournisseurId/balance');

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        return CompteFournisseur.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_recuperation_solde_fournisseur'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CompteClient> createTransactionClient(
    int clientId,
    TransactionForm transactionForm,
  ) async {
    try {
      final response = await _apiClient.post(
        '/accounts/customers/$clientId/transactions',
        transactionForm.toJson(),
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        return CompteClient.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_creation_transaction_client'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_creation_transaction_client'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Récupère les ventes impayées d'un client
  Future<List<UnpaidSale>> getUnpaidSales(int clientId) async {
    try {
      final response = await _apiClient.get('/accounts/customers/$clientId/unpaid-sales');

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final ventesData = data['data'] as List;
        return ventesData.map((v) => UnpaidSale.fromJson(v as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_recuperation_ventes_impayees'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_recuperation_ventes_impayees'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  /// Crée une transaction avec lien vers une vente
  Future<CompteClient> createTransactionWithSale({
    required int clientId,
    required double montant,
    required String typeTransaction,
    required String typeTransactionDetail,
    int? venteId,
    String? description,
  }) async {
    try {
      final body = {
        'montant': montant,
        'typeTransaction': typeTransaction,
        'typeTransactionDetail': typeTransactionDetail,
        if (venteId != null) 'venteId': venteId,
        if (description != null) 'description': description,
      };

      final response = await _apiClient.post(
        '/accounts/customers/$clientId/transactions',
        body,
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        return CompteClient.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_creation_transaction'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_creation_transaction'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CompteFournisseur> createTransactionFournisseur(
    int fournisseurId,
    TransactionForm transactionForm,
  ) async {
    try {
      final response = await _apiClient.post(
        '/accounts/suppliers/$fournisseurId/transactions',
        transactionForm.toJson(),
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        return CompteFournisseur.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_creation_transaction_fournisseur'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_creation_transaction_fournisseur'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TransactionCompte>> getTransactionsClient(
    int clientId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/accounts/customers/$clientId/transactions',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> transactionsJson = data['data'] ?? [];

        return transactionsJson.map((json) => TransactionCompte.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_recuperation_transactions_client'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_recuperation_transactions_client'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<TransactionCompte>> getTransactionsFournisseur(
    int fournisseurId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/accounts/suppliers/$fournisseurId/transactions',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> transactionsJson = data['data'] ?? [];

        return transactionsJson.map((json) => TransactionCompte.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_recuperation_transactions_fournisseur'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_recuperation_transactions_fournisseur'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CompteClient> updateLimiteCreditClient(
    int clientId,
    LimiteCreditForm limiteCreditForm,
  ) async {
    try {
      final response = await _apiClient.put(
        '/accounts/customers/$clientId/credit-limit',
        limiteCreditForm.toJson(),
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        return CompteClient.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_mise_jour_limite_credit'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_mise_jour_limite_credit'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CompteFournisseur> updateLimiteCreditFournisseur(
    int fournisseurId,
    LimiteCreditForm limiteCreditForm,
  ) async {
    try {
      final response = await _apiClient.put(
        '/accounts/suppliers/$fournisseurId/credit-limit',
        limiteCreditForm.toJson(),
      );

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        return CompteFournisseur.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw ApiException(
          message: response.message ?? 'accounts_erreur_lors_mise_jour_limite_credit_2'.tr,
          code: response.errorCode ?? 'API_ERROR',
          statusCode: 500,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'accounts_erreur_lors_mise_jour_limite_credit_2'.tr,
        code: 'UNKNOWN_ERROR',
        statusCode: 500,
      );
    }
  }
}
