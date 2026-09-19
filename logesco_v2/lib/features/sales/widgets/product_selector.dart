import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../../products/controllers/product_controller.dart';
import '../../products/models/product.dart';
import '../controllers/sales_controller.dart';
import '../../../core/widgets/product_image_preview.dart';

class ProductSelector extends StatefulWidget {
  final Future<void> Function(Product product, int quantity) onProductSelected;
  final FocusNode? searchFocusNode;
  // Bouton principal (Procéder au paiement / Enregistrer la commande) —
  // la touche Espace dans la recherche y envoie directement le focus.
  final FocusNode? primaryActionFocusNode;

  const ProductSelector({
    super.key,
    required this.onProductSelected,
    this.searchFocusNode,
    this.primaryActionFocusNode,
  });

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  // Une GlobalKey par ligne visible, pour pouvoir la faire défiler en vue
  // (Scrollable.ensureVisible) quand la sélection au clavier change.
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  /// Navigation clavier dans les résultats de recherche produit :
  /// - Flèches haut/bas : déplace le produit "surligné"
  /// - Entrée : ouvre le dialog de quantité pour le produit surligné
  /// - Espace : passe directement au bouton principal (paiement/commande)
  /// N'agit que lorsque le champ de recherche a le focus, pour ne pas
  /// interférer avec la saisie ailleurs (panier, quantité, etc.).
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (widget.searchFocusNode == null || !widget.searchFocusNode!.hasFocus) return false;

    final salesController = Get.find<SalesController>();

    if (event.logicalKey == LogicalKeyboardKey.space) {
      widget.primaryActionFocusNode?.requestFocus();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      salesController.moveProductHighlight(1);
      _scrollToHighlighted(salesController);
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      salesController.moveProductHighlight(-1);
      _scrollToHighlighted(salesController);
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final product = salesController.highlightedProduct;
      if (product == null) return true;

      final canAddToCart = product.estActif && (product.estService || salesController.getAvailableQuantity(product.id) > 0);
      if (!canAddToCart) {
        SnackbarHelper.warning('Stock épuisé pour ${product.nom}', duration: const Duration(seconds: 2));
        return true;
      }

      showAddToCartQuantityDialog(context, product, widget.onProductSelected);
      return true;
    }

    return false;
  }

  void _scrollToHighlighted(SalesController salesController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[salesController.highlightedProductIndex];
      final itemContext = key?.currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(itemContext, duration: const Duration(milliseconds: 150), alignment: 0.5);
      }
    });
  }

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
                  focusNode: widget.searchFocusNode,
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
                  // La sélection au clavier (flèches + Entrée) est gérée par
                  // _handleKeyEvent ci-dessus, pas par onSubmitted, pour
                  // éviter un double déclenchement.
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
                      final itemKey = _itemKeys.putIfAbsent(index, () => GlobalKey());
                      return _ProductItem(
                        key: itemKey,
                        index: index,
                        product: product,
                        onSelected: widget.onProductSelected,
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
          await widget.onProductSelected(product, 1);
        }

        SnackbarHelper.info(
          'sales_product_found_detail'.trParams({'product': product.nom, 'barcode': barcode}),
          title: 'sales_product_found'.tr,
        );
      } else {
        // Aucun produit trouvé
        SnackbarHelper.warning(
          'sales_no_product_barcode'.trParams({'barcode': barcode}),
          title: 'sales_no_product_found'.tr,
        );
      }
    } catch (e) {
      SnackbarHelper.error(
        'sales_barcode_search_error'.trParams({'error': e.toString()}),
        title: 'error'.tr,
      );
    }
  }
}

class _ProductItem extends StatelessWidget {
  final int index;
  final Product product;
  final Future<void> Function(Product product, int quantity) onSelected;

  const _ProductItem({
    super.key,
    required this.index,
    required this.product,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final salesController = Get.find<SalesController>();

    return Obx(() {
      final isHighlighted = salesController.highlightedProductIndex == index;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: isHighlighted ? Colors.blue[50] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: isHighlighted ? BorderSide(color: Colors.blue[400]!, width: 2) : BorderSide.none,
        ),
        child: ListTile(
          leading: ProductImageThumbnail(
            imageUrl: product.imageUrl,
            size: 48,
            productName: product.nom,
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
                    onPressed: canAddToCart ? () => showAddToCartQuantityDialog(context, product, onSelected) : null,
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
    });
  }
}

/// Dialog de saisie de quantité avant ajout au panier. Extrait en fonction
/// top-level pour être appelable à la fois par le clic sur l'icône panier
/// (_ProductItem) et par le raccourci clavier "Entrée" sur le produit
/// surligné dans la recherche (_ProductSelectorState) — Entrée y valide
/// aussi directement l'ajout, sans souris.
void showAddToCartQuantityDialog(
  BuildContext context,
  Product product,
  Future<void> Function(Product product, int quantity) onSelected,
) {
  // Pré-rempli à 1, texte déjà sélectionné : taper un chiffre l'écrase
  // directement, sans avoir à l'effacer d'abord.
  final quantityController = TextEditingController(text: '1')..selection = const TextSelection(baseOffset: 0, extentOffset: 1);
  final salesController = Get.find<SalesController>();
  final availableQuantity = salesController.getAvailableQuantity(product.id);

  void confirm(BuildContext dialogContext) async {
    final quantity = int.tryParse(quantityController.text);
    if (quantity != null && quantity > 0) {
      // Vérifier le stock pour les produits physiques
      if (!product.estService && quantity > availableQuantity) {
        SnackbarHelper.error(
          'sales_stock_insufficient_detail'.trParams({'requested': quantity.toString(), 'available': availableQuantity.toString()}),
          title: 'sales_stock_insufficient'.tr,
        );
        return;
      }

      Navigator.of(dialogContext).pop();
      await onSelected(product, quantity);
    } else {
      SnackbarHelper.error('sales_invalid_quantity'.tr, title: 'error'.tr);
    }
  }

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
            // Entrée valide directement la quantité, sans toucher la souris.
            onSubmitted: (_) => confirm(dialogContext),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () => confirm(dialogContext),
          child: Text('add'.tr),
        ),
      ],
    ),
  );
}
