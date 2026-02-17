import 'package:get/get.dart';
import '../models/product.dart';
import '../services/api_product_service.dart';

class ProductGetxController extends GetxController {
  final ApiProductService _productService = Get.find<ApiProductService>();

  // Observables
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  /// Charge la liste des produits
  Future<void> loadProducts({bool refresh = false}) async {
    try {
      if (refresh) {
        products.clear();
      }

      isLoading.value = true;
      error.value = '';

      final result = await _productService.getProducts(
        limit: 100, // Limite maximale autorisée par l'API
      );

      products.assignAll(result);
      print('✅ ${result.length} produits chargés');
    } catch (e) {
      print('❌ Erreur chargement produits: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Recherche un produit par ID
  Product? getProductById(int id) {
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Recherche des produits par nom ou référence
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return products;

    return products.where((product) {
      return product.nom.toLowerCase().contains(query.toLowerCase()) || product.reference.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
