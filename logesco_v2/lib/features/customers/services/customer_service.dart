import '../models/customer.dart';
import '../models/customer_transaction.dart';

/// Service abstrait pour la gestion des clients
abstract class CustomerService {
  /// Récupère la liste des clients avec pagination et recherche
  Future<List<Customer>> getCustomers({
    String? search,
    int page = 1,
    int limit = 20,
  });

  /// Récupère un client par son ID
  Future<Customer?> getCustomerById(int id);

  /// Crée un nouveau client
  Future<Customer> createCustomer(CustomerForm customerForm);

  /// Met à jour un client existant
  Future<Customer> updateCustomer(int id, CustomerForm customerForm);

  /// Supprime un client
  Future<bool> deleteCustomer(int id);

  /// Recherche des clients par nom, prénom ou téléphone
  Future<List<Customer>> searchCustomers(String query);

  /// Récupère l'historique des transactions d'un client
  Future<List<CustomerTransaction>> getCustomerTransactions(int customerId);

  /// Vérifie si un client peut être supprimé (pas de ventes en cours)
  Future<bool> canDeleteCustomer(int id);
}
