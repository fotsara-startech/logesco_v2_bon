import '../models/supplier.dart';

/// Service abstrait pour la gestion des fournisseurs
abstract class SupplierService {
  /// Récupère la liste des fournisseurs avec pagination et recherche
  Future<List<Supplier>> getSuppliers({
    String? search,
    int page = 1,
    int limit = 20,
  });

  /// Récupère un fournisseur par son ID
  Future<Supplier?> getSupplierById(int id);

  /// Crée un nouveau fournisseur
  Future<Supplier> createSupplier(SupplierForm supplierForm);

  /// Met à jour un fournisseur existant
  Future<Supplier> updateSupplier(int id, SupplierForm supplierForm);

  /// Supprime un fournisseur
  Future<bool> deleteSupplier(int id);

  /// Recherche des fournisseurs par nom ou téléphone
  Future<List<Supplier>> searchSuppliers(String query);

  /// Récupère l'historique des transactions d'un fournisseur
  Future<List<SupplierTransaction>> getSupplierTransactions(int supplierId);

  /// Paie un fournisseur (enregistre un paiement)
  Future<bool> paySupplier(
    int supplierId,
    double montant, {
    String? description,
  });

  /// Récupère les commandes impayées d'un fournisseur
  Future<List<UnpaidProcurement>> getUnpaidProcurements(int supplierId);

  /// Récupère les données du relevé de compte fournisseur
  Future<Map<String, dynamic>?> getSupplierStatement(int supplierId);

  /// Paie une commande spécifique d'un fournisseur
  Future<bool> paySupplierForProcurement(
    int supplierId,
    double montant,
    int procurementId, {
    String? description,
    bool createFinancialMovement = false,
  });

  /// Vérifie si un fournisseur peut être supprimé (pas de commandes en cours)
  Future<bool> canDeleteSupplier(int id);
}
