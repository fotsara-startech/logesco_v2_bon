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

class _CartItem extends StatelessWidget {
  final dynamic item;
  final Function(int productId, int quantity) onQuantityChanged;
  final Function(int productId, double price) onPriceChanged;
  final Function(int productId) onRemove;

  const _CartItem({
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(item.productId),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),

            // Référence
            Text(
              'sales_cart_reference'.trParams({'ref': item.productReference}),
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
                      onPressed: item.quantity > 1 ? () => onQuantityChanged(item.productId, item.quantity - 1) : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                    ),
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.quantity.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () => onQuantityChanged(item.productId, item.quantity + 1),
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Prix unitaire
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice.toStringAsFixed(2),
                    decoration: InputDecoration(
                      labelText: 'sales_cart_unit_price'.tr,
                      suffixText: 'FCFA',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final price = double.tryParse(value);
                      if (price != null && price >= 0) {
                        onPriceChanged(item.productId, price);
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
                  '${item.totalPrice.toStringAsFixed(0)} FCFA',
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
