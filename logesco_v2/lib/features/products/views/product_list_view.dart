import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/widgets/permission_widget.dart';
import '../controllers/product_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/product_search_bar.dart';
import '../widgets/product_filter_bar.dart';
import '../widgets/product_sort_bar.dart';
import '../../../core/routes/app_routes.dart';
import 'excel_import_export_page.dart';

/// Vue de la liste des produits
class ProductListView extends StatelessWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser Get.put avec permanent=false pour créer une nouvelle instance à chaque accès
    // Cette vue crée sa propre instance du contrôleur pour éviter le partage d'état avec d'autres modules
    final controller = Get.isRegistered<ProductController>() ? Get.find<ProductController>() : Get.put(ProductController(), permanent: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Produits'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.categories),
            icon: const Icon(Icons.category),
            tooltip: 'Gérer les catégories',
          ),
          PermissionWidget(
            module: 'products',
            privilege: 'CREATE',
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'import_export':
                    Get.to(() => const ExcelImportExportPage());
                    break;
                  case 'add_product':
                    controller.goToCreateProduct();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'import_export',
                  child: Row(
                    children: [
                      Icon(Icons.import_export),
                      SizedBox(width: 8),
                      Text('Import/Export Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_product',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Ajouter un produit'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.refreshProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Information mode développement
          // const DevModeInfo(),

          // Barre de recherche
          const ProductSearchBar(),

          // Barre de filtres
          const ProductFilterBar(),

          // Barre de tri
          const ProductSortBar(),

          // Liste des produits
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const LoadingWidget(message: 'Chargement des produits...');
              }

              if (controller.hasError.value && controller.products.isEmpty) {
                return ErrorDisplayWidget(
                  message: controller.errorMessage.value,
                  onRetry: controller.refreshProducts,
                );
              }

              if (controller.products.isEmpty) {
                return _buildEmptyState(controller);
              }

              return RefreshIndicator(
                onRefresh: controller.refreshProducts,
                child: _buildProductList(controller),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: PermissionWidget(
        module: 'products',
        privilege: 'CREATE',
        child: FloatingActionButton(
          onPressed: controller.goToCreateProduct,
          tooltip: 'Ajouter un produit',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// Construit l'état vide
  Widget _buildEmptyState(ProductController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value.isNotEmpty ? 'Aucun produit trouvé' : 'Aucun produit enregistré',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value.isNotEmpty ? 'Essayez de modifier vos critères de recherche' : 'Commencez par ajouter votre premier produit',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value.isNotEmpty)
            ElevatedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Effacer les filtres'),
            )
          else
            PermissionWidget(
              module: 'products',
              privilege: 'CREATE',
              child: ElevatedButton.icon(
                onPressed: controller.goToCreateProduct,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un produit'),
              ),
            ),
        ],
      ),
    );
  }

  /// Construit la liste des produits
  Widget _buildProductList(ProductController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.products.length,
      itemBuilder: (context, index) {
        final product = controller.products[index];
        return ProductCard(
          product: product,
          onTap: () => controller.goToProductDetail(product),
          onEdit: () => controller.goToEditProduct(product),
          onDelete: () => controller.deleteProduct(product),
          onToggleStatus: () => controller.toggleProductStatus(product),
        );
      },
    );
  }
}
