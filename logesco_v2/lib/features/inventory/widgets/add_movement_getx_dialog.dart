import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../../products/controllers/product_getx_controller.dart';
import '../../products/models/product.dart';

/// Dialog GetX pour ajouter un mouvement de stock
class AddMovementGetxDialog extends GetView<InventoryGetxController> {
  const AddMovementGetxDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return _AddMovementDialogContent();
  }
}

class _AddMovementDialogContent extends StatefulWidget {
  @override
  State<_AddMovementDialogContent> createState() => _AddMovementDialogContentState();
}

class _AddMovementDialogContentState extends State<_AddMovementDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  Product? selectedProduct;
  String selectedMovementType = 'entree'; // 'entree' ou 'sortie'

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryGetxController>();
    final productController = Get.find<ProductGetxController>();

    return AlertDialog(
      title: const Text('Ajouter un mouvement de stock'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          minWidth: 300,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sélection du produit
              Obx(() {
                if (productController.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (productController.error.value.isNotEmpty) {
                  return Column(
                    children: [
                      Text(
                        'Erreur: ${productController.error.value}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: () => productController.loadProducts(refresh: true),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  );
                }

                return DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Produit *',
                    border: OutlineInputBorder(),
                  ),
                  items: productController.products.map((product) {
                    return DropdownMenuItem<Product>(
                      key: ValueKey(product.id),
                      value: product,
                      child: Text(
                        '${product.nom} (Réf: ${product.reference})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setState(() {
                      selectedProduct = product;
                    });
                  },
                  validator: (value) => value == null ? 'Veuillez sélectionner un produit' : null,
                );
              }),

              const SizedBox(height: 16),

              // Type de mouvement
              DropdownButtonFormField<String>(
                value: selectedMovementType,
                decoration: const InputDecoration(
                  labelText: 'Type de mouvement *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'entree',
                    child: Text('Entrée de stock (+)'),
                  ),
                  DropdownMenuItem(
                    value: 'sortie',
                    child: Text('Sortie de stock (-)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedMovementType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Quantité
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 10, 25, 100...',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une quantité';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'La quantité doit être un nombre positif';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Motif
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif *',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Réception fournisseur, Vente, Ajustement...',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un motif';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Annuler'),
        ),
        Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : _handleSubmit,
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ajouter'),
            )),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = Get.find<InventoryGetxController>();
    final quantity = int.parse(_quantityController.text);

    final success = await controller.createStockMovement(
      productId: selectedProduct!.id,
      typeMouvement: selectedMovementType,
      quantite: quantity,
      motif: _reasonController.text,
      notes: _reasonController.text,
    );

    if (success) {
      Get.back();
      Get.snackbar(
        'Succès',
        'Mouvement de stock ajouté avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
    }
  }
}
