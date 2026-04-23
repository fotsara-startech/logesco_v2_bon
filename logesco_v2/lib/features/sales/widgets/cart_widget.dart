import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sales_controller.dart';

class CartWidget extends StatelessWidget {
  final Function(int productId, int quantity) onQuantityChanged;
  final Function(int productId, double price) onPriceChanged;
  final Function(int productId) onRemoveItem;

  const CartWidget({
    super.key,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();

    return Obx(() {
      if (controller.cartItems.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'sales_cart_empty'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'sales_cart_select_products'.tr,
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Liste des articles
          Expanded(
            child: ListView.builder(
              itemCount: controller.cartItems.length,
              itemBuilder: (context, index) {
                final item = controller.cartItems[index];
                return _CartItem(
                  key: ValueKey('${item.productId}_${item.quantity}'), // Clé unique basée sur l'ID et la quantité
                  item: item,
                  onQuantityChanged: onQuantityChanged,
                  onPriceChanged: onPriceChanged,
                  onRemove: onRemoveItem,
                );
              },
            ),
          ),

          const Divider(),

          // Résumé du panier
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('sales_cart_subtotal'.tr),
                    Text(
                      '${controller.cartSubtotal.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (controller.discount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('sales_cart_discount'.tr),
                      Text(
                        '-${controller.discount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'sales_cart_total'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${controller.cartTotal.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bouton vider le panier
          if (controller.cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmClearCart(context, controller),
                  icon: const Icon(Icons.clear_all),
                  label: Text('sales_cart_clear'.tr),
                ),
              ),
            ),
        ],
      );
    });
  }

  void _confirmClearCart(BuildContext context, SalesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('sales_cart_clear_confirm'.tr),
        content: Text('sales_cart_clear_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.clearCart();
            },
            child: Text('sales_cart_clear_button'.tr),
          ),
        ],
      ),
    );
  }
}

class _CartItem extends StatefulWidget {
  final dynamic item;
  final Function(int productId, int quantity) onQuantityChanged;
  final Function(int productId, double price) onPriceChanged;
  final Function(int productId) onRemove;

  const _CartItem({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  State<_CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<_CartItem> {
  late TextEditingController _quantityController;
  bool _isUserTyping = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ne synchroniser que si l'utilisateur n'est pas en train de taper
    if (!_isUserTyping && _quantityController.text != widget.item.quantity.toString()) {
      _quantityController.text = widget.item.quantity.toString();
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du produit et bouton supprimer
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onRemove(widget.item.productId),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),

            // Référence
            Text(
              'sales_cart_reference'.trParams({'ref': widget.item.productReference}),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 8),

            // Quantité et prix
            Row(
              children: [
                // Contrôles de quantité
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.item.quantity > 1
                          ? () {
                              _isUserTyping = false;
                              widget.onQuantityChanged(widget.item.productId, widget.item.quantity - 1);
                            }
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                    ),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          isDense: true,
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        onChanged: (value) {
                          _isUserTyping = true;
                          final quantity = int.tryParse(value);
                          if (quantity != null && quantity > 0) {
                            widget.onQuantityChanged(widget.item.productId, quantity);
                          }
                        },
                        onFieldSubmitted: (value) {
                          _isUserTyping = false;
                          final quantity = int.tryParse(value);
                          if (quantity != null && quantity > 0) {
                            widget.onQuantityChanged(widget.item.productId, quantity);
                          } else {
                            // Si la valeur n'est pas valide, remettre la quantité actuelle
                            _quantityController.text = widget.item.quantity.toString();
                          }
                        },
                        onTap: () {
                          _isUserTyping = true;
                        },
                        onEditingComplete: () {
                          _isUserTyping = false;
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _isUserTyping = false;
                        widget.onQuantityChanged(widget.item.productId, widget.item.quantity + 1);
                      },
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Prix unitaire
                Expanded(
                  child: TextFormField(
                    initialValue: widget.item.unitPrice.toStringAsFixed(2),
                    decoration: InputDecoration(
                      labelText: 'sales_cart_unit_price'.tr,
                      suffixText: 'FCFA',
                      isDense: true,
                      helperText: widget.item.maxDiscountAllowed > 0 ? 'Min: ${(widget.item.originalPrice - widget.item.maxDiscountAllowed).toStringAsFixed(0)} FCFA' : null,
                      helperStyle: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final price = double.tryParse(value);
                      if (price != null && price >= 0) {
                        // Vérifier que le prix ne descend pas en dessous du minimum autorisé
                        final minPrice = widget.item.originalPrice - widget.item.maxDiscountAllowed;
                        final validatedPrice = price < minPrice ? minPrice : price;
                        widget.onPriceChanged(widget.item.productId, validatedPrice);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Total de la ligne
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('sales_cart_line_total'.tr),
                Text(
                  '${widget.item.totalPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
