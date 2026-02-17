// import '../models/customer.dart';
// import 'customer_service.dart';

// /// Service de test avec données simulées pour les clients
// class MockCustomerService extends CustomerService {
//   // Données simulées
//   final List<Customer> _mockCustomers = [
//     Customer(
//       id: 1,
//       nom: 'Mballa',
//       prenom: 'Jean-Pierre',
//       telephone: '+237 677 123 456',
//       email: 'jp.mballa@gmail.com',
//       adresse: 'Quartier Mvog-Ada, Yaoundé',
//       dateCreation: DateTime.now().subtract(const Duration(days: 200)),
//       dateModification: DateTime.now().subtract(const Duration(days: 3)),
//     ),
//     Customer(
//       id: 2,
//       nom: 'Nguyen',
//       prenom: 'Marie-Claire',
//       telephone: '+237 699 987 654',
//       email: 'marie.nguyen@yahoo.fr',
//       adresse: 'Rue de la Liberté, Douala',
//       dateCreation: DateTime.now().subtract(const Duration(days: 150)),
//       dateModification: DateTime.now().subtract(const Duration(days: 1)),
//     ),
//     Customer(
//       id: 3,
//       nom: 'Fotso',
//       prenom: 'Paul',
//       telephone: '+237 655 444 333',
//       email: 'paul.fotso@hotmail.com',
//       adresse: 'Quartier Bonanjo, Douala',
//       dateCreation: DateTime.now().subtract(const Duration(days: 100)),
//       dateModification: DateTime.now().subtract(const Duration(hours: 8)),
//     ),
//     Customer(
//       id: 4,
//       nom: 'Alhadji',
//       prenom: 'Fatima',
//       telephone: '+237 678 555 777',
//       email: 'fatima.alhadji@gmail.com',
//       adresse: 'Quartier Nlongkak, Yaoundé',
//       dateCreation: DateTime.now().subtract(const Duration(days: 80)),
//       dateModification: DateTime.now().subtract(const Duration(hours: 24)),
//     ),
//     Customer(
//       id: 5,
//       nom: 'Talla',
//       prenom: 'Robert',
//       telephone: '+237 690 111 222',
//       email: 'robert.talla@outlook.com',
//       adresse: 'Rue Joss, Douala',
//       dateCreation: DateTime.now().subtract(const Duration(days: 45)),
//       dateModification: DateTime.now().subtract(const Duration(hours: 2)),
//     ),
//     Customer(
//       id: 6,
//       nom: 'Entreprise ABC SARL',
//       prenom: null,
//       telephone: '+237 233 456 789',
//       email: 'contact@abc-sarl.cm',
//       adresse: 'Zone Industrielle, Douala',
//       dateCreation: DateTime.now().subtract(const Duration(days: 30)),
//       dateModification: DateTime.now().subtract(const Duration(hours: 6)),
//     ),
//   ];

//   final List<CustomerTransaction> _mockTransactions = [
//     CustomerTransaction(
//       id: 1,
//       customerId: 1,
//       type: 'vente',
//       montant: 450000,
//       description: 'Achat ordinateur portable HP',
//       reference: 'VTE001',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 12)),
//     ),
//     CustomerTransaction(
//       id: 2,
//       customerId: 1,
//       type: 'paiement',
//       montant: -200000,
//       description: 'Paiement partiel VTE001',
//       reference: 'PAY001',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 8)),
//     ),
//     CustomerTransaction(
//       id: 3,
//       customerId: 2,
//       type: 'vente',
//       montant: 180000,
//       description: 'Achat téléphone Samsung',
//       reference: 'VTE002',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 6)),
//     ),
//     CustomerTransaction(
//       id: 4,
//       customerId: 3,
//       type: 'vente',
//       montant: 75000,
//       description: 'Formation Excel',
//       reference: 'VTE003',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 3)),
//     ),
//     CustomerTransaction(
//       id: 5,
//       customerId: 6,
//       type: 'vente',
//       montant: 1250000,
//       description: 'Commande matériel informatique',
//       reference: 'VTE004',
//       dateTransaction: DateTime.now().subtract(const Duration(days: 2)),
//     ),
//   ];

//   /// Récupère la liste des clients avec pagination et recherche
//   @override
//   Future<List<Customer>> getCustomers({
//     String? search,
//     int page = 1,
//     int limit = 20,
//   }) async {
//     // Simulation d'un délai réseau
//     await Future.delayed(const Duration(milliseconds: 500));

//     var filteredCustomers = List<Customer>.from(_mockCustomers);

//     // Filtrage par recherche
//     if (search != null && search.isNotEmpty) {
//       filteredCustomers = filteredCustomers.where((customer) {
//         return customer.nom.toLowerCase().contains(search.toLowerCase()) ||
//             (customer.prenom?.toLowerCase().contains(search.toLowerCase()) ?? false) ||
//             (customer.telephone?.contains(search) ?? false) ||
//             (customer.email?.toLowerCase().contains(search.toLowerCase()) ?? false) ||
//             customer.nomComplet.toLowerCase().contains(search.toLowerCase());
//       }).toList();
//     }

//     // Pagination simulée
//     final startIndex = (page - 1) * limit;
//     final endIndex = startIndex + limit;

//     if (startIndex >= filteredCustomers.length) {
//       return [];
//     }

//     return filteredCustomers.sublist(
//       startIndex,
//       endIndex > filteredCustomers.length ? filteredCustomers.length : endIndex,
//     );
//   }

//   /// Récupère un client par son ID
//   @override
//   Future<Customer?> getCustomerById(int id) async {
//     await Future.delayed(const Duration(milliseconds: 300));

//     try {
//       return _mockCustomers.firstWhere((customer) => customer.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Crée un nouveau client
//   @override
//   Future<Customer> createCustomer(CustomerForm customerForm) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     final newCustomer = Customer(
//       id: _mockCustomers.length + 1,
//       nom: customerForm.nom,
//       prenom: customerForm.prenom,
//       telephone: customerForm.telephone,
//       email: customerForm.email,
//       adresse: customerForm.adresse,
//       dateCreation: DateTime.now(),
//       dateModification: DateTime.now(),
//     );

//     _mockCustomers.add(newCustomer);
//     return newCustomer;
//   }

//   /// Met à jour un client existant
//   @override
//   Future<Customer> updateCustomer(int id, CustomerForm customerForm) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     final index = _mockCustomers.indexWhere((customer) => customer.id == id);
//     if (index == -1) {
//       throw Exception('Client non trouvé');
//     }

//     final existingCustomer = _mockCustomers[index];
//     final updatedCustomer = Customer(
//       id: id,
//       nom: customerForm.nom,
//       prenom: customerForm.prenom,
//       telephone: customerForm.telephone,
//       email: customerForm.email,
//       adresse: customerForm.adresse,
//       dateCreation: existingCustomer.dateCreation,
//       dateModification: DateTime.now(),
//     );

//     _mockCustomers[index] = updatedCustomer;
//     return updatedCustomer;
//   }

//   /// Supprime un client
//   @override
//   Future<bool> deleteCustomer(int id) async {
//     await Future.delayed(const Duration(milliseconds: 500));

//     // Vérifier s'il y a des transactions liées
//     final hasTransactions = _mockTransactions.any((t) => t.customerId == id);
//     if (hasTransactions) {
//       throw Exception('Impossible de supprimer ce client car il a des transactions associées');
//     }

//     final index = _mockCustomers.indexWhere((customer) => customer.id == id);
//     if (index != -1) {
//       _mockCustomers.removeAt(index);
//       return true;
//     }
//     return false;
//   }

//   /// Recherche des clients par nom, prénom ou téléphone
//   @override
//   Future<List<Customer>> searchCustomers(String query) async {
//     return getCustomers(search: query);
//   }

//   /// Récupère l'historique des transactions d'un client
//   @override
//   Future<List<CustomerTransaction>> getCustomerTransactions(int customerId) async {
//     await Future.delayed(const Duration(milliseconds: 400));

//     return _mockTransactions.where((transaction) => transaction.customerId == customerId).toList()..sort((a, b) => b.dateTransaction.compareTo(a.dateTransaction));
//   }

//   /// Vérifie si un client peut être supprimé (pas de ventes en cours)
//   @override
//   Future<bool> canDeleteCustomer(int id) async {
//     await Future.delayed(const Duration(milliseconds: 200));

//     // Vérifier s'il y a des transactions liées
//     return !_mockTransactions.any((t) => t.customerId == id);
//   }
// }
