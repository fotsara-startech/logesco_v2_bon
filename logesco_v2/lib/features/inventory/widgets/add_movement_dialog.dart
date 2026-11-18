/**
 * Dialog pour ajouter un mouvement de stock
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
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
      title: Text('stock_add_movement'.tr),
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
                    decoration: InputDecoration(
                      labelText: 'stock_add_movement_product'.tr,
                      border: OutlineInputBorder(),
                    ),
                    items: productController.products.map((product) {
                      return DropdownMenuItem<Product>(
                        key: ValueKey(product.id),
                        value: product,
                        child: Text(
                          'inventory_ref_3'.trParams({'nom': '${product.nom}', 'reference': '${product.reference}'}),
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
                decoration: InputDecoration(
                  labelText: 'stock_add_movement_type'.tr,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'entree',
                    child: Text('stock_movement_type_entree'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'sortie',
                    child: Text('stock_movement_type_sortie'.tr),
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
                decoration: InputDecoration(
                  labelText: 'expiration_dialog_quantity_label'.tr,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'stock_movement_quantity_required'.tr;
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'stock_add_movement_quantity_positive'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Motif
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Motif *',
                  border: OutlineInputBorder(),
                  hintText: 'stock_add_movement_reason_example'.tr,
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'inventory_veuillez_saisir_motif'.tr;
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
          child: Text('suppliers_form_cancel'.tr),
        ),
        Obx(() => ElevatedButton(
              onPressed: inventoryController.isLoading.value ? null : _handleSubmit,
              child: inventoryController.isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('add'.tr),
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
      SnackbarHelper.success('stock_add_movement_success'.tr);
    }
  }
}
