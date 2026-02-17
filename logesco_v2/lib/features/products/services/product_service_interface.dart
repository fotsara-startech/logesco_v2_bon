import '../models/product.dart';

/// Interface pour les services de gestion des produits
abstract class ProductServiceInterface {
  /// Récupère la liste des produits avec pagination et filtres
  Future<List<Product>> getProducts({
    String? search,
    String? categorie,
    int page = 1,
    int limit = 20,
  });

  /// Récupère un produit par son ID
  Future<Product?> getProductById(int id);

  /// Crée un nouveau produit
  Future<Product> createProduct(ProductForm productForm);

  /// Met à jour un produit existant
  Future<Product> updateProduct(int id, ProductForm productForm);

  /// Supprime un produit
  Future<bool> deleteProduct(int id);

  /// Récupère la liste des catégories disponibles
  Future<List<String>> getCategories();

  /// Importe des produits en lot
  Future<List<Product>> importProducts(List<ProductForm> products);

  /// Récupère tous les produits pour l'export
  Future<List<Product>> getAllProducts();
}
