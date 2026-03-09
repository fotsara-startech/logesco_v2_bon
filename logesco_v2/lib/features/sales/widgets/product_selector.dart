import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../products/controllers/product_controller.dart';
import '../../products/models/product.dart';
import '../controllers/sales_controller.dart';

class ProductSelector extends StatelessWidget {
  final Future<void> Function(Product product, int quantity) onProductSelected;

  const ProductSelector({
    super.key,
    required this.onProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    final salesController = Get.find<SalesController>();

    return Column(
      children: [
        // Barre de recherche et bouton de rafraîchissement
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'sales_search_product'.tr,
                    hintText: 'sales_search_product_hint'.tr,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () => _showBarcodeSearch(salesController),
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Recherche par code-barre',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    salesController.updateProductSearchQuery(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => IconButton(
                    onPressed: salesController.isLoading
                        ? null
                        : () async {
                            await salesController.refreshProductsAndStocks();
                          },
                    icon: salesController.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: 'Actualiser produits et stocks',
                  )),
            ],
          ),
        ),

        // Barre de tri
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text('sales_sort_by'.tr, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text('sales_sort_name'.tr),
                          selected: salesController.productSortBy == 'nom',
                          onSelected: (selected) {
                            if (selected) salesController.setProductSortBy('nom');
                          },
                        ),
                        ChoiceChip(
                          label: Text('sales_sort_reference'.tr),
                          selected: salesController.productSortBy == 'reference',
                          onSelected: (selected) {
                            if (selected) salesController.setProductSortBy('reference');
                          },
                        ),
                        ChoiceChip(
                          label: Text('sales_sort_price'.tr),
                          selected: salesController.productSortBy == 'prix',
                          onSelected: (selected) {
                            if (selected) salesController.setProductSortBy('prix');
                          },
                        ),
                        ChoiceChip(
                          label: Text('sales_sort_category'.tr),
                          selected: salesController.productSortBy == 'categorie',
                          onSelected: (selected) {
                            if (selected) salesController.setProductSortBy('categorie');
                          },
                        ),
                      ],
                    )),
              ),
              Obx(() => IconButton(
                    icon: Icon(
                      salesController.productSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                    onPressed: salesController.toggleProductSort,
                    tooltip: salesController.productSortAscending ? 'Croissant' : 'Décroissant',
                  )),
            ],
          ),
        ),
        const Divider(),

        // Liste des produits
        Expanded(
          child: Obx(() {
            if (salesController.isLoading && salesController.productsForSale.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (salesController.productsForSale.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'sales_no_products'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'sales_no_products_available'.tr,
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await salesController.refreshProductsAndStocks();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text('sales_reload'.tr),
                    ),
                  ],
                ),
              );
            }

            // Afficher un avertissement si aucun stock n'est chargé
            return Column(
              children: [
                if (salesController.getProductStock(1) == null && salesController.productsForSale.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'sales_stocks_not_loaded'.tr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                              Text(
                                'sales_stocks_not_loaded_help'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () async {
                            await salesController.refreshProductsAndStocks();
                          },
                          tooltip: 'sales_refresh_products'.tr,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: salesController.productsForSale.length,
                    itemBuilder: (context, index) {
                      final product = salesController.productsForSale[index];
                      return _ProductItem(
                        product: product,
                        onSelected: onProductSelected,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Affiche la recherche par code-barre pour les ventes
  void _showBarcodeSearch(SalesController salesController) {
    final textController = TextEditingController();
    final productController = Get.find<ProductController>();

    Get.dialog(
      AlertDialog(
        title: Text('sales_barcode_search_title'.tr),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: 'sales_barcode_label'.tr,
            hintText: 'sales_barcode_hint'.tr,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.qr_code_scanner),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final barcode = textController.text.trim();
              if (barcode.isNotEmpty) {
                Get.back();
                await _searchByBarcode(barcode, productController, salesController);
              }
            },
            child: Text('search'.tr),
          ),
        ],
      ),
    );
  }

  /// Effectue une recherche spécifique par code-barres dans les ventes
  Future<void> _searchByBarcode(String barcode, ProductController productController, SalesController salesController) async {
    try {
      // Utiliser la méthode spécialisée de recherche par code-barres
      final product = await productController.searchByBarcode(barcode);

      if (product != null) {
        // Produit trouvé, mettre à jour la recherche dans le sales controller
        salesController.updateProductSearchQuery(product.nom);

        // Proposer d'ajouter directement au panier
        final shouldAdd = await Get.dialog<bool>(
              AlertDialog(
                title: Text('sales_product_found'.tr),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${'sales_product_label'.tr}: ${product.nom}'),
                    Text('${'sales_product_reference'.tr}: ${product.reference}'),
                    Text('${'sales_product_price'.tr}: ${product.prixUnitaire.toStringAsFixed(0)} FCFA'),
                    if (product.codeBarre != null) Text('${'sales_barcode_label'.tr}: ${product.codeBarre}'),
                    const SizedBox(height: 8),
                    Text('${'sales_stock_available'.tr}: ${salesController.getRawStockQuantity(product.id)}',
                        style: TextStyle(
                          color: salesController.getRawStockQuantity(product.id) > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 16),
                    Text('sales_add_to_cart_question'.tr),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text('no'.tr),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    child: Text('sales_add_to_cart'.tr),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldAdd) {
          await onProductSelected(product, 1);
        }

        Get.snackbar(
          'sales_product_found'.tr,
          'sales_product_found_detail'.trParams({'product': product.nom, 'barcode': barcode}),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        // Aucun produit trouvé
        Get.snackbar(
          'sales_no_product_found'.tr,
          'sales_no_product_barcode'.trParams({'barcode': barcode}),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'sales_barcode_search_error'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}

class _ProductItem extends StatelessWidget {
  final Product product;
  final Future<void> Function(Product product, int quantity) onSelected;

  const _ProductItem({
    required this.product,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.estActif ? (product.estService ? Colors.blue : Colors.green) : Colors.grey,
          child: Icon(
            product.estService ? Icons.build : Icons.inventory,
            color: Colors.white,
          ),
        ),
        title: Text(
          product.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: GetX<SalesController>(
          builder: (salesController) {
            final availableQuantity = salesController.getAvailableQuantity(product.id);
            final stock = salesController.getProductStock(product.id);
            final cartQuantity = salesController.cartItems.where((item) => item.productId == product.id).fold(0, (sum, item) => sum + item.quantity);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'sales_product_reference'.tr}: ${product.reference}'),
                Text('${'sales_product_price'.tr}: ${product.prixUnitaire.toStringAsFixed(0)} FCFA'),
                Text('${'sales_product_category'.tr}: ${product.categorie ?? 'sales_product_category_undefined'.tr}'),

                // Affichage du stock
                if (product.estService)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: const Text(
                      'SERVICE',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: availableQuantity > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: availableQuantity > 0 ? Colors.green : Colors.red, width: 1),
                        ),
                        child: Text(
                          'Stock: ${salesController.getRawStockQuantity(product.id)}',
                          style: TextStyle(
                            color: salesController.getRawStockQuantity(product.id) > 0 ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (cartQuantity > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Text(
                            'Panier: $cartQuantity',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (availableQuantity != salesController.getRawStockQuantity(product.id)) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: availableQuantity > 0 ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: availableQuantity > 0 ? Colors.blue : Colors.red, width: 1),
                          ),
                          child: Text(
                            'Disponible: $availableQuantity',
                            style: TextStyle(
                              color: availableQuantity > 0 ? Colors.blue : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (stock != null && stock.quantiteReservee > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple, width: 1),
                          ),
                          child: Text(
                            'Réservé: ${stock.quantiteReservee}',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            );
          },
        ),
        trailing: GetX<SalesController>(
          builder: (salesController) {
            final availableQuantity = salesController.getAvailableQuantity(product.id);
            final canAddToCart = product.estActif && (product.estService || availableQuantity > 0);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: canAddToCart ? () => _showQuantityDialog(context, product) : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  tooltip: canAddToCart ? 'Ajouter au panier' : 'Stock épuisé',
                ),
                IconButton(
                  onPressed: canAddToCart ? () async => await onSelected(product, 1) : null,
                  icon: const Icon(Icons.add),
                  tooltip: canAddToCart ? 'Ajouter 1' : 'Stock épuisé',
                ),
              ],
            );
          },
        ),
        enabled: product.estActif,
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Product product) {
    final quantityController = TextEditingController(text: '1');
    final salesController = Get.find<SalesController>();
    final availableQuantity = salesController.getAvailableQuantity(product.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('sales_add_product_title'.trParams({'product': product.nom})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${'sales_product_label'.tr}: ${product.nom}'),
            if (!product.estService) ...[
              const SizedBox(height: 8),
              Text(
                'Stock disponible: $availableQuantity',
                style: TextStyle(
                  color: availableQuantity > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'sales_quantity_label'.tr,
                border: const OutlineInputBorder(),
                helperText: product.estService ? 'sales_service_quantity_free'.tr : 'sales_quantity_max'.trParams({'max': availableQuantity.toString()}),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                // Vérifier le stock pour les produits physiques
                if (!product.estService && quantity > availableQuantity) {
                  Get.snackbar(
                    'sales_stock_insufficient'.tr,
                    'sales_stock_insufficient_detail'.trParams({'requested': quantity.toString(), 'available': availableQuantity.toString()}),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                  return;
                }

                Navigator.of(context).pop();
                await onSelected(product, quantity);
              } else {
                Get.snackbar(
                  'error'.tr,
                  'sales_invalid_quantity'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }
}
