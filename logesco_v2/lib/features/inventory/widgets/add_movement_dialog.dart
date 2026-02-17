/**
 * Dialog pour ajouter un mouvement de stock
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../products/models/product.dart';
import '../../products/controllers/product_controller.dart';
import '../controllers/inventory_getx_controller.dart';

class AddMovementDialog extends StatefulWidget {
  const AddMovementDialog({Key? key}) : super(key: key);

  @override
  State<AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<AddMovementDialog> {
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
    final inventoryController = Get.find<InventoryGetxController>();
    final productController = Get.find<ProductController>();

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
              Obx(() => DropdownButtonFormField<Product>(
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
                  )),

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
                    child: Text('Entrée de stock'),
                  ),
                  DropdownMenuItem(
                    value: 'sortie',
                    child: Text('Sortie de stock'),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        Obx(() => ElevatedButton(
              onPressed: inventoryController.isLoading.value ? null : _handleSubmit,
              child: inventoryController.isLoading.value
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

    final inventoryController = Get.find<InventoryGetxController>();
    final quantity = int.parse(_quantityController.text);

    final success = await inventoryController.createStockMovement(
      productId: selectedProduct!.id,
      typeMouvement: selectedMovementType,
      quantite: quantity,
      motif: _reasonController.text,
      notes: _reasonController.text,
    );

    if (success) {
      Navigator.of(context).pop();
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
