import 'package:get/get.dart';
import '../models/product.dart';
import '../services/api_product_service.dart';

/// Contrôleur pour la page de détail d'un produit
class ProductDetailController extends GetxController {
  final ApiProductService _productService = Get.find<ApiProductService>();

  final Rx<Product?> product = Rx<Product?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProduct();
  }

  /// Charge le produit avec résolution des catégories
  Future<void> _loadProduct() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Essayer de récupérer le produit depuis les arguments
      Product? argumentProduct = Get.arguments as Product?;

      if (argumentProduct != null) {
        print('🔍 Produit reçu via arguments: ${argumentProduct.reference}');
        
        // Recharger le produit via l'API pour avoir la catégorie résolue
        final fullProduct = await _productService.getProductById(argumentProduct.id);
        
        if (fullProduct != null) {
          print('✅ Produit rechargé avec catégorie: "${fullProduct.categorie}"');
          product.value = fullProduct;
        } else {
          // Fallback avec le produit des arguments
          print('⚠️ Impossible de recharger, utilisation du produit des arguments');
          product.value = argumentProduct;
        }
      } else {
        // Essayer de récupérer l'ID depuis les paramètres de route
        final String? productId = Get.parameters['id'];
        if (productId != null) {
          print('🔍 Chargement produit par ID: $productId');
          
          final loadedProduct = await _productService.getProductById(int.parse(productId));
          
          if (loadedProduct != null) {
            print('✅ Produit chargé avec catégorie: "${loadedProduct.categorie}"');
            product.value = loadedProduct;
          } else {
            errorMessage.value = 'Produit non trouvé';
          }
        } else {
          errorMessage.value = 'Aucun produit spécifié';
        }
      }
    } catch (e) {
      print('❌ Erreur chargement produit: $e');
      errorMessage.value = 'Erreur lors du chargement: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Recharge le produit
  Future<void> refreshProduct() async {
    if (product.value != null) {
      await _loadProduct();
    }
  }
}