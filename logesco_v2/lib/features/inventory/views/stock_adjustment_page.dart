import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';
import '../models/stock_model.dart';

class StockAdjustmentPage extends StatefulWidget {
  final Stock? initialStock;

  const StockAdjustmentPage({
    Key? key,
    this.initialStock,
  }) : super(key: key);

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  Stock? _selectedStock;
  bool _isLoading = false;
  bool _isIncrement = true;

  @override
  void initState() {
    super.initState();
    _selectedStock = widget.initialStock;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('stock_adjustment_title'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection du produit
              if (_selectedStock == null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'stock_adjustment_select_product'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _selectProduct,
                          icon: const Icon(Icons.search),
                          label: Text('stock_adjustment_search_product'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Informations du produit sélectionné
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedStock!.produit?.nom ?? 'Produit',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (_selectedStock!.produit?.reference != null)
                                    Text(
                                      'Réf: ${_selectedStock!.produit!.reference}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStock = null;
                                });
                              },
                              child: Text('stock_adjustment_change'.tr),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStockInfo(
                                'stock_adjustment_current_stock'.tr,
                                _selectedStock!.quantiteDisponible.toString(),
                                Icons.inventory,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStockInfo(
                                'stock_movement_threshold'.tr,
                                _selectedStock!.produit?.seuilStockMinimum.toString() ?? '0',
                                Icons.warning,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Type d'ajustement
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'stock_adjustment_type'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('stock_adjustment_increment'.tr),
                                subtitle: Text('stock_add_stock'.tr),
                                value: true,
                                groupValue: _isIncrement,
                                onChanged: (value) {
                                  setState(() {
                                    _isIncrement = value!;
                                  });
                                },
                                secondary: const Icon(Icons.add_circle, color: Colors.green),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('stock_adjustment_decrement'.tr),
                                subtitle: Text('stock_remove_stock'.tr),
                                value: false,
                                groupValue: _isIncrement,
                                onChanged: (value) {
                                  setState(() {
                                    _isIncrement = value!;
                                  });
                                },
                                secondary: const Icon(Icons.remove_circle, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quantité
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'stock_adjustment_quantity'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: '${'stock_adjustment_quantity'.tr} ${_isIncrement ? '(+)' : '(-)'}',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              _isIncrement ? Icons.add : Icons.remove,
                              color: _isIncrement ? Colors.green : Colors.red,
                            ),
                            suffixText: 'unités',
                            hintText: 'stock_adjustment_quantity_hint'.tr,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir une quantité';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Veuillez saisir une quantité valide';
                            }
                            if (!_isIncrement && quantity > _selectedStock!.quantiteDisponible) {
                              return 'Quantité supérieure au stock disponible';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Aperçu du nouveau stock
                        if (_quantityController.text.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.preview,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nouveau stock: ${_calculateNewStock()}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'stock_adjustment_notes'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'stock_adjustment_notes'.tr,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.note),
                            hintText: 'stock_adjustment_notes_hint'.tr,
                          ),
                          maxLines: 3,
                          maxLength: 500,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton de validation
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitAdjustment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          'stock_adjustment_save'.tr,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateNewStock() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final currentStock = _selectedStock?.quantiteDisponible ?? 0;

    if (_isIncrement) {
      return currentStock + quantity;
    } else {
      return currentStock - quantity;
    }
  }

  void _selectProduct() {
    // TODO: Implémenter la sélection de produit
    // Pour l'instant, on affiche un message
    Get.snackbar(
      'info'.tr,
      'Sélection de produit - À implémenter',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _submitAdjustment() async {
    if (!_formKey.currentState!.validate() || _selectedStock == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final quantity = int.parse(_quantityController.text);
      final changement = _isIncrement ? quantity : -quantity;

      final controller = Get.find<InventoryController>();
      final success = await controller.adjustStock(
        produitId: _selectedStock!.produitId,
        changementQuantite: changement,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (success) {
        Get.snackbar(
          'success'.tr,
          'stock_adjustment_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        Get.back();
      } else {
        Get.snackbar(
          'error'.tr,
          controller.error ?? 'Erreur lors de l\'ajustement',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'Erreur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
