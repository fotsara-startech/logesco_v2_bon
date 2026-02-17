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
        title: const Text('Ajustement de Stock'),
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
                          'Sélectionner un produit',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _selectProduct,
                          icon: const Icon(Icons.search),
                          label: const Text('Rechercher un produit'),
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
                              child: const Text('Changer'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStockInfo(
                                'Stock actuel',
                                _selectedStock!.quantiteDisponible.toString(),
                                Icons.inventory,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStockInfo(
                                'Seuil minimum',
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
                          'Type d\'ajustement',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Augmenter'),
                                subtitle: const Text('Ajouter au stock'),
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
                                title: const Text('Diminuer'),
                                subtitle: const Text('Retirer du stock'),
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
                          'Quantité',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantité à ${_isIncrement ? 'ajouter' : 'retirer'}',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              _isIncrement ? Icons.add : Icons.remove,
                              color: _isIncrement ? Colors.green : Colors.red,
                            ),
                            suffixText: 'unités',
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
                          'Notes (optionnel)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Raison de l\'ajustement',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                            hintText: 'Ex: Inventaire, casse, erreur de saisie...',
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
                          'Ajuster le stock',
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
      'Information',
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
          'Succès',
          'Stock ajusté avec succès (${_isIncrement ? '+' : ''}$changement)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        Get.back();
      } else {
        Get.snackbar(
          'Erreur',
          controller.error ?? 'Erreur lors de l\'ajustement',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
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
