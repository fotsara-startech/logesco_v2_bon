// import '../models/supplier.dart';
// import 'supplier_service.dart';

// /// Service de test avec données simulées pour les fournisseurs
// class MockSupplierService extends SupplierService {
//   // Données simulées
//   final List<Supplier> _mockSuppliers = [
//     Supplier(
//       id: 1,
//       nom: 'TechDistrib SARL',
//       personneContact: 'Jean Dupont',
//       telephone: '+237 677 123 456',
//       email: 'contact@techdistrib.cm',
//       adresse: 'Rue de la Réunification, Douala',
//       dateCreation: DateTime.now().subtract(const Duration(days: 180)),
//       dateModification: DateTime.now().subtract(const Duration(days: 5)),
//     ),
//     Supplier(
//       id: 2,
//       nom: 'Informatique Plus',
//       personneContact: 'Marie Ngono',
//       telephone: '+237 699 987 654',
//       email: 'info@infoplus.cm',
//       adresse: 'Avenue Kennedy, Yaoundé',
//       dateCreation: DateTime.now().subtract(const Duration(days: 120)),
//       dateModification: DateTime.now().subtract(const Duration(days: 2)),
//     ),
//     Supplier(
//       id: 3,
//       nom: 'Global Tech Solutions',
//       personneContact: 'Paul Mbarga',
//       telephone: '+237 655 444 333',
//       email: 'paul@globaltech.cm',
//       adresse: 'Quartier Bonanjo, Douala',
//       dateCreation: DateTime.now().subtract(const Duration(days: 90)),
//       dateModification: DateTime.now().subtract(const Duration(hours: 12)),
//     ),
//     Supplier(
//       id: 4,
//       nom: 'Cameroon Electronics',
//       personneContact: 'Fatima Alhadji',
//       telephone: '+237 678 555 777',
//       email: 'fatima@camelec.cm',
//       adresse: 'Marché Central, Yaoundé',
//       dateCreation: DateTime.now().subtract(const Duration(days: 60)),
//       dateModification: DateTime.now().subtract(const Duration(days: 1)),
//     ),
//     Supplier(
//       id: 5,
//       nom: 'Digital World Cameroun',
//       personneContact: 'Robert Talla',
//       telephone: '+237 690 111 222',
//       email: 'robert@digitalworld.cm',
//       adresse: 'Rue Joss, Douala',
//       dateCreation: DateTime.now().subtract(const Duration(days: 30)),
//       dateModification: DateTime.now().subtract(const Duration(hours: 6)),
//     ),
//   ];

//   final List<SupplierTransaction> _mockTransactions = [
//     SupplierTransaction(
//       id: 1,
//       supplierId: 1,
//       type: 'achat',
//       montant: 2500000,
//       description: 'Commande ordinateurs portables',
//       reference: 'CMD001',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 15)),
//     ),
//     SupplierTransaction(
//       id: 2,
//       supplierId: 1,
//       type: 'paiement',
//       montant: -1500000,
//       description: 'Paiement partiel commande CMD001',
//       reference: 'PAY001',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 10)),
//     ),
//     SupplierTransaction(
//       id: 3,
//       supplierId: 2,
//       type: 'achat',
//       montant: 850000,
//       description: 'Achat imprimantes Canon',
//       reference: 'CMD002',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 8)),
//     ),
//     SupplierTransaction(
//       id: 4,
//       supplierId: 3,
//       type: 'achat',
//       montant: 1200000,
//       description: 'Commande téléphones Samsung',
//       reference: 'CMD003',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 5)),
//     ),
//   ];

//   /// Récupère la liste des fournisseurs avec pagination et recherche
//   @override
//   Future<List<Supplier>> getSuppliers({
//     String? search,
//     int page = 1,
//     int limit = 20,
//   }) async {
//     // Simulation d'un délai réseau
//     await Future.delayed(const Duration(milliseconds: 500));

//     var filteredSuppliers = List<Supplier>.from(_mockSuppliers);

//     // Filtrage par recherche
//     if (search != null && search.isNotEmpty) {
//       filteredSuppliers = filteredSuppliers.where((supplier) {
//         return supplier.nom.toLowerCase().contains(search.toLowerCase()) ||
//             (supplier.telephone?.contains(search) ?? false) ||
//             (supplier.email?.toLowerCase().contains(search.toLowerCase()) ?? false) ||
//             (supplier.personneContact?.toLowerCase().contains(search.toLowerCase()) ?? false);
//       }).toList();
//     }

//     // Pagination simulée
//     final startIndex = (page - 1) * limit;
//     final endIndex = startIndex + limit;

//     if (startIndex >= filteredSuppliers.length) {
//       return [];
//     }

//     return filteredSuppliers.sublist(
//       startIndex,
//       endIndex > filteredSuppliers.length ? filteredSuppliers.length : endIndex,
//     );
//   }

//   /// Récupère un fournisseur par son ID
//   @override
//   Future<Supplier?> getSupplierById(int id) async {
//     await Future.delayed(const Duration(milliseconds: 300));

//     try {
//       return _mockSuppliers.firstWhere((supplier) => supplier.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Crée un nouveau fournisseur
//   @override
//   Future<Supplier> createSupplier(SupplierForm supplierForm) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     final newSupplier = Supplier(
//       id: _mockSuppliers.length + 1,
//       nom: supplierForm.nom,
//       personneContact: supplierForm.personneContact,
//       telephone: supplierForm.telephone,
//       email: supplierForm.email,
//       adresse: supplierForm.adresse,
//       dateCreation: DateTime.now(),
//       dateModification: DateTime.now(),
//     );

//     _mockSuppliers.add(newSupplier);
//     return newSupplier;
//   }

//   /// Met à jour un fournisseur existant
//   @override
//   Future<Supplier> updateSupplier(int id, SupplierForm supplierForm) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     final index = _mockSuppliers.indexWhere((supplier) => supplier.id == id);
//     if (index == -1) {
//       throw Exception('Fournisseur non trouvé');
//     }

//     final existingSupplier = _mockSuppliers[index];
//     final updatedSupplier = Supplier(
//       id: id,
//       nom: supplierForm.nom,
//       personneContact: supplierForm.personneContact,
//       telephone: supplierForm.telephone,
//       email: supplierForm.email,
//       adresse: supplierForm.adresse,
//       dateCreation: existingSupplier.dateCreation,
//       dateModification: DateTime.now(),
//     );

//     _mockSuppliers[index] = updatedSupplier;
//     return updatedSupplier;
//   }

//   /// Supprime un fournisseur
//   @override
//   Future<bool> deleteSupplier(int id) async {
//     await Future.delayed(const Duration(milliseconds: 500));

//     // Vérifier s'il y a des transactions liées
//     final hasTransactions = _mockTransactions.any((t) => t.supplierId == id);
//     if (hasTransactions) {
//       throw Exception('Impossible de supprimer ce fournisseur car il a des transactions associées');
//     }

//     final index = _mockSuppliers.indexWhere((supplier) => supplier.id == id);
//     if (index != -1) {
//       _mockSuppliers.removeAt(index);
//       return true;
//     }
//     return false;
//   }

//   /// Recherche des fournisseurs par nom ou téléphone
//   @override
//   Future<List<Supplier>> searchSuppliers(String query) async {
//     return getSuppliers(search: query);
//   }

//   /// Récupère l'historique des transactions d'un fournisseur
//   @override
//   Future<List<SupplierTransaction>> getSupplierTransactions(int supplierId) async {
//     await Future.delayed(const Duration(milliseconds: 400));

//     return _mockTransactions.where((transaction) => transaction.supplierId == supplierId).toList()..sort((a, b) => b.dateTransaction.compareTo(a.dateTransaction));
//   }

//   /// Vérifie si un fournisseur peut être supprimé (pas de commandes en cours)
//   @override
//   Future<bool> canDeleteSupplier(int id) async {
//     await Future.delayed(const Duration(milliseconds: 200));

//     // Vérifier s'il y a des transactions liées
//     return !_mockTransactions.any((t) => t.supplierId == id);
//   }
// }
