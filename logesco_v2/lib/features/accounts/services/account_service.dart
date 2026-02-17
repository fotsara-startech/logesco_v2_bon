import '../models/account.dart';

/// Interface abstraite pour les services de gestion des comptes
abstract class AccountService {
  /// Récupère la liste des comptes clients avec pagination et recherche
  Future<List<CompteClient>> getComptesClients({
    String? search,
    double? soldeMin,
    double? soldeMax,
    bool? enDepassement,
    int page = 1,
    int limit = 20,
  });

  /// Récupère la liste des comptes fournisseurs avec pagination et recherche
  Future<List<CompteFournisseur>> getComptesFournisseurs({
    String? search,
    double? soldeMin,
    double? soldeMax,
    bool? enDepassement,
    int page = 1,
    int limit = 20,
  });

  /// Récupère le solde d'un compte client spécifique
  Future<CompteClient?> getSoldeClient(int clientId);

  /// Récupère le solde d'un compte fournisseur spécifique
  Future<CompteFournisseur?> getSoldeFournisseur(int fournisseurId);

  /// Crée une transaction sur un compte client
  Future<CompteClient> createTransactionClient(
    int clientId,
    TransactionForm transactionForm,
  );

  /// Crée une transaction sur un compte fournisseur
  Future<CompteFournisseur> createTransactionFournisseur(
    int fournisseurId,
    TransactionForm transactionForm,
  );

  /// Récupère l'historique des transactions d'un compte client
  Future<List<TransactionCompte>> getTransactionsClient(
    int clientId, {
    int page = 1,
    int limit = 20,
  });

  /// Récupère l'historique des transactions d'un compte fournisseur
  Future<List<TransactionCompte>> getTransactionsFournisseur(
    int fournisseurId, {
    int page = 1,
    int limit = 20,
  });

  /// Met à jour la limite de crédit d'un client
  Future<CompteClient> updateLimiteCreditClient(
    int clientId,
    LimiteCreditForm limiteCreditForm,
  );

  /// Met à jour la limite de crédit d'un fournisseur
  Future<CompteFournisseur> updateLimiteCreditFournisseur(
    int fournisseurId,
    LimiteCreditForm limiteCreditForm,
  );
}
