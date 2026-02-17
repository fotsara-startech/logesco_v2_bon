// import '../models/product.dart';
// import 'product_service.dart';

// /// Service de test avec données simulées pour les produits
// class MockProductService implements ProductService {
//   // Données simulées
//   final List<Product> _mockProducts = [
//     Product(
//       id: 1,
//       reference: 'ORD001',
//       nom: 'Ordinateur portable HP',
//       description: 'Ordinateur portable HP Pavilion 15.6" - Intel Core i5, 8GB RAM, 256GB SSD',
//       prixUnitaire: 450000,
//       prixAchat: 380000,
//       codeBarre: '1234567890123',
//       categorie: 'Informatique',
//       seuilStockMinimum: 5,
//       estActif: true,
//       estService: false,
//       dateCreation: DateTime.now().subtract(const Duration(days: 30)),
//       dateModification: DateTime.now().subtract(const Duration(days: 2)),
//     ),
//     Product(
//       id: 2,
//       reference: 'CONS001',
//       nom: 'Consultation IT',
//       description: 'Consultation en informatique - Audit et conseil technique',
//       prixUnitaire: 25000,
//       prixAchat: null,
//       codeBarre: null,
//       categorie: 'Services',
//       seuilStockMinimum: 0,
//       estActif: true,
//       estService: true,
//       dateCreation: DateTime.now().subtract(const Duration(days: 15)),
//       dateModification: DateTime.now().subtract(const Duration(days: 1)),
//     ),
//     Product(
//       id: 3,
//       reference: 'TEL001',
//       nom: 'Téléphone Samsung Galaxy',
//       description: 'Samsung Galaxy A54 - 128GB, Noir',
//       prixUnitaire: 180000,
//       prixAchat: 150000,
//       codeBarre: '9876543210987',
//       categorie: 'Téléphonie',
//       seuilStockMinimum: 10,
//       estActif: true,
//       estService: false,
//       dateCreation: DateTime.now().subtract(const Duration(days: 20)),
//       dateModification: DateTime.now().subtract(const Duration(hours: 5)),
//     ),
//     Product(
//       id: 4,
//       reference: 'FORM001',
//       nom: 'Formation Excel',
//       description: 'Formation complète Microsoft Excel - Niveau débutant à avancé',
//       prixUnitaire: 75000,
//       prixAchat: null,
//       codeBarre: null,
//       categorie: 'Formation',
//       seuilStockMinimum: 0,
//       estActif: true,
//       estService: true,
//       dateCreation: DateTime.now().subtract(const Duration(days: 10)),
//       dateModification: DateTime.now().subtract(const Duration(hours: 12)),
//     ),
//     Product(
//       id: 5,
//       reference: 'IMP001',
//       nom: 'Imprimante Canon',
//       description: 'Imprimante Canon PIXMA - Multifonction, WiFi',
//       prixUnitaire: 85000,
//       prixAchat: 70000,
//       codeBarre: '5555666677778',
//       categorie: 'Informatique',
//       seuilStockMinimum: 3,
//       estActif: false,
//       estService: false,
//       dateCreation: DateTime.now().subtract(const Duration(days: 45)),
//       dateModification: DateTime.now().subtract(const Duration(days: 7)),
//     ),
//   ];

//   final List<String> _mockCategories = [
//     'Informatique',
//     'Téléphonie',
//     'Services',
//     'Formation',
//     'Bureautique',
//   ];

//   /// Récupère la liste des produits avec pagination et recherche
//   @override
//   Future<List<Product>> getProducts({
//     String? search,
//     String? categorie,
//     int page = 1,
//     int limit = 20,
//   }) async {
//     // Simulation d'un délai réseau
//     await Future.delayed(const Duration(milliseconds: 500));

//     var filteredProducts = List<Product>.from(_mockProducts);

//     // Filtrage par recherche
//     if (search != null && search.isNotEmpty) {
//       filteredProducts = filteredProducts.where((product) {
//         return product.nom.toLowerCase().contains(search.toLowerCase()) || product.reference.toLowerCase().contains(search.toLowerCase()) || (product.codeBarre?.contains(search) ?? false);
//       }).toList();
//     }

//     // Filtrage par catégorie
//     if (categorie != null && categorie.isNotEmpty) {
//       filteredProducts = filteredProducts.where((product) {
//         return product.categorie == categorie;
//       }).toList();
//     }

//     // Pagination simulée
//     final startIndex = (page - 1) * limit;
//     final endIndex = startIndex + limit;

//     if (startIndex >= filteredProducts.length) {
//       return [];
//     }

//     return filteredProducts.sublist(
//       startIndex,
//       endIndex > filteredProducts.length ? filteredProducts.length : endIndex,
//     );
//   }

//   /// Récupère un produit par son ID
//   @override
//   Future<Product?> getProductById(int id) async {
//     await Future.delayed(const Duration(milliseconds: 300));

//     try {
//       return _mockProducts.firstWhere((product) => product.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Crée un nouveau produit
//   @override
//   Future<Product> createProduct(ProductForm productForm) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     final newProduct = Product(
//       id: _mockProducts.length + 1,
//       reference: productForm.reference,
//       nom: productForm.nom,
//       description: productForm.description,
//       prixUnitaire: productForm.prixUnitaire,
//       prixAchat: productForm.prixAchat,
//       codeBarre: productForm.codeBarre,
//       categorie: productForm.categorie,
//       seuilStockMinimum: productForm.seuilStockMinimum,
//       estActif: productForm.estActif,
//       estService: productForm.estService,
//       dateCreation: DateTime.now(),
//       dateModification: DateTime.now(),
//     );

//     _mockProducts.add(newProduct);
//     return newProduct;
//   }

//   /// Met à jour un produit existant
//   @override
//   Future<Product> updateProduct(int id, ProductForm productForm) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     final index = _mockProducts.indexWhere((product) => product.id == id);
//     if (index == -1) {
//       throw Exception('Produit non trouvé');
//     }

//     final existingProduct = _mockProducts[index];
//     final updatedProduct = Product(
//       id: id,
//       reference: productForm.reference,
//       nom: productForm.nom,
//       description: productForm.description,
//       prixUnitaire: productForm.prixUnitaire,
//       prixAchat: productForm.prixAchat,
//       codeBarre: productForm.codeBarre,
//       categorie: productForm.categorie,
//       seuilStockMinimum: productForm.seuilStockMinimum,
//       estActif: productForm.estActif,
//       estService: productForm.estService,
//       dateCreation: existingProduct.dateCreation,
//       dateModification: DateTime.now(),
//     );

//     _mockProducts[index] = updatedProduct;
//     return updatedProduct;
//   }

//   /// Supprime un produit
//   @override
//   Future<bool> deleteProduct(int id) async {
//     await Future.delayed(const Duration(milliseconds: 500));

//     final index = _mockProducts.indexWhere((product) => product.id == id);
//     if (index != -1) {
//       _mockProducts.removeAt(index);
//       return true;
//     }
//     return false;
//   }

//   /// Recherche des produits par référence, nom ou code-barre
//   @override
//   Future<List<Product>> searchProducts(String query) async {
//     return getProducts(search: query);
//   }

//   /// Recherche un produit par code-barre
//   @override
//   Future<Product?> getProductByBarcode(String barcode) async {
//     await Future.delayed(const Duration(milliseconds: 300));

//     try {
//       return _mockProducts.firstWhere((product) => product.codeBarre == barcode);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Récupère les catégories disponibles
//   @override
//   Future<List<String>> getCategories() async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     return List<String>.from(_mockCategories);
//   }

//   /// Vérifie si une référence produit est unique
//   @override
//   Future<bool> isReferenceUnique(String reference, {int? excludeId}) async {
//     await Future.delayed(const Duration(milliseconds: 300));

//     final existingProduct = _mockProducts.where((product) {
//       if (excludeId != null && product.id == excludeId) {
//         return false; // Exclure le produit en cours d'édition
//       }
//       return product.reference.toLowerCase() == reference.toLowerCase();
//     });

//     return existingProduct.isEmpty;
//   }

//   /// Génère automatiquement une nouvelle référence produit
//   @override
//   Future<String> generateProductReference() async {
//     await Future.delayed(const Duration(milliseconds: 200));

//     final currentYear = DateTime.now().year;
//     final yearSuffix = currentYear.toString().substring(2); // Derniers 2 chiffres

//     // Trouver le prochain numéro disponible
//     int nextNumber = 1;
//     String newReference;

//     do {
//       final formattedNumber = nextNumber.toString().padLeft(4, '0');
//       newReference = 'PRD$yearSuffix$formattedNumber';
//       nextNumber++;
//     } while (_mockProducts.any((p) => p.reference == newReference));

//     return newReference;
//   }
// }
