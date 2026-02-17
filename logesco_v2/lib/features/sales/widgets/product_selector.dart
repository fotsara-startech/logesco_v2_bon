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
    final controller = Get.find<ProductController>();

    return Column(
      children: [
        // Barre de recherche et bouton de rafraîchissement
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Rechercher un produit',
                  hintText: 'Nom, référence, code-barre...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () => _showBarcodeSearch(controller),
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Recherche par code-barre',
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  controller.updateSearchQuery(value);
                },
              ),
            ),
            Obx(() => IconButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          controller.loadProducts(refresh: true);
                        },
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Actualiser les produits',
                )),
            const SizedBox(width: 8),
            GetX<SalesController>(
              builder: (salesController) => IconButton(
                onPressed: salesController.isLoading
                    ? null
                    : () async {
                        await salesController.refreshStocks();
                        await controller.loadProducts(refresh: true);
                      },
                icon: salesController.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Actualiser les stocks',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Liste des produits
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.products.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.products.isEmpty) {
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
                      'Aucun produit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun produit disponible pour la vente',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: controller.products.length,
              itemBuilder: (context, index) {
                final product = controller.products[index];
                return _ProductItem(
                  product: product,
                  onSelected: onProductSelected,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  /// Affiche la recherche par code-barre pour les ventes
  void _showBarcodeSearch(ProductController controller) {
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Recherche par code-barre'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Code-barre',
            hintText: 'Scanner ou saisir le code-barre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code_scanner),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final barcode = textController.text.trim();
              if (barcode.isNotEmpty) {
                Get.back();
                await _searchByBarcode(barcode, controller);
              }
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  /// Effectue une recherche spécifique par code-barres dans les ventes
  Future<void> _searchByBarcode(String barcode, ProductController controller) async {
    try {
      // Utiliser la méthode spécialisée de recherche par code-barres
      final product = await controller.searchByBarcode(barcode);

      if (product != null) {
        // Produit trouvé, l'afficher dans la liste et proposer de l'ajouter
        controller.setSearchResults([product]);

        // Proposer d'ajouter directement au panier
        final shouldAdd = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Produit trouvé'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Produit: ${product.nom}'),
                    Text('Référence: ${product.reference}'),
                    Text('Prix: ${product.prixUnitaire.toStringAsFixed(0)} FCFA'),
                    if (product.codeBarre != null) Text('Code-barre: ${product.codeBarre}'),
                    const SizedBox(height: 16),
                    const Text('Voulez-vous l\'ajouter au panier ?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Non'),
                  ),
                  ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    child: const Text('Ajouter au panier'),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldAdd) {
          await onProductSelected(product, 1);
        }

        Get.snackbar(
          'Produit trouvé',
          'Produit "${product.nom}" trouvé avec le code-barre $barcode',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        // Aucun produit trouvé
        controller.setSearchResults([]);
        Get.snackbar(
          'Aucun résultat',
          'Aucun produit trouvé avec le code-barre $barcode',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la recherche par code-barre: $e',
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
                Text('Référence: ${product.reference}'),
                Text('Prix: ${product.prixUnitaire.toStringAsFixed(0)} FCFA'),
                Text('Catégorie: ${product.categorie ?? 'Non définie'}'),

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
        title: Text('Ajouter ${product.nom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Produit: ${product.nom}'),
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
                labelText: 'Quantité',
                border: const OutlineInputBorder(),
                helperText: product.estService ? 'Service - quantité libre' : 'Maximum: $availableQuantity',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                // Vérifier le stock pour les produits physiques
                if (!product.estService && quantity > availableQuantity) {
                  Get.snackbar(
                    'Stock insuffisant',
                    'Quantité demandée: $quantity, Disponible: $availableQuantity',
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
                  'Erreur',
                  'Veuillez saisir une quantité valide',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
