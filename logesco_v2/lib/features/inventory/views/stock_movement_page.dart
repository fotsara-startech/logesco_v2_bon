import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../models/stock_model.dart';
import '../services/stock_movement_service.dart';

class StockMovementPage extends StatefulWidget {
  final Stock? initialStock;

  const StockMovementPage({
    super.key,
    this.initialStock,
  });

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _movementService = StockMovementService();

  Stock? _selectedStock;
  bool _isLoading = false;
  String _selectedType = 'entree';
  String _selectedMotif = '';
  List<TypeMouvement> _typesMouvements = [];

  @override
  void initState() {
    super.initState();
    _selectedStock = widget.initialStock;
    _typesMouvements = _movementService.getTypesMouvements();
    if (_typesMouvements.isNotEmpty) {
      _selectedMotif = _typesMouvements.first.motifs.first;
    }
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
        title: Text('stock_movement_title'.tr),
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
                          'stock_movement_select_product'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _selectProduct,
                          icon: const Icon(Icons.search),
                          label: Text('stock_movement_search_product'.tr),
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
                                  if (_selectedStock!.produit != null)
                                    Text(
                                      '${'stock_product_reference'.tr}: ${_selectedStock!.produit!.reference}',
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
                              child: Text('stock_movement_change'.tr),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStockInfo(
                                'stock_movement_current_stock'.tr,
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

                // Type de mouvement
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'stock_movement_type'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'stock_movement_type'.tr,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.swap_horiz),
                          ),
                          items: _typesMouvements.map((type) {
                            return DropdownMenuItem(
                              value: type.code,
                              child: Text(type.libelle.tr),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value!;
                              // Réinitialiser le motif
                              final type = _typesMouvements.firstWhere((t) => t.code == value);
                              _selectedMotif = type.motifs.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Motif
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'stock_movement_reason'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedMotif,
                          decoration: InputDecoration(
                            labelText: 'stock_movement_reason'.tr,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.description),
                          ),
                          items: _getMotifsByType(_selectedType).map((motif) {
                            return DropdownMenuItem(
                              value: motif,
                              child: Text(motif.tr),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMotif = value!;
                            });
                          },
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
                          'stock_movement_quantity'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: 'stock_movement_quantity'.tr,
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              _getIconForType(_selectedType),
                              color: _getColorForType(_selectedType),
                            ),
                            suffixText: 'stock_units'.tr,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'stock_movement_quantity_required'.tr;
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'stock_movement_quantity_invalid'.tr;
                            }
                            if (_selectedType == 'sortie' && quantity > _selectedStock!.quantiteDisponible) {
                              return 'stock_movement_quantity_exceeds'.tr;
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
                                  'stock_movement_new_stock'.trParams({'stock': _calculateNewStock().toString()}),
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
                          'stock_movement_notes_optional'.tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'stock_movement_notes_details'.tr,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.note),
                            hintText: 'stock_movement_notes_hint'.tr,
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
                  onPressed: _isLoading ? null : _submitMovement,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _getColorForType(_selectedType),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          'stock_movement_submit'.tr,
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

  List<String> _getMotifsByType(String type) {
    final typeMovement = _typesMouvements.firstWhere(
      (t) => t.code == type,
      orElse: () => TypeMouvement(code: '', libelle: '', description: '', motifs: []),
    );
    return typeMovement.motifs;
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'entree':
        return Icons.add_circle;
      case 'sortie':
        return Icons.remove_circle;
      case 'correction':
        return Icons.edit;
      case 'transfert':
        return Icons.swap_horiz;
      default:
        return Icons.swap_horiz;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'entree':
        return Colors.green;
      case 'sortie':
        return Colors.red;
      case 'correction':
        return Colors.orange;
      case 'transfert':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  int _calculateNewStock() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final currentStock = _selectedStock?.quantiteDisponible ?? 0;

    switch (_selectedType) {
      case 'entree':
        return currentStock + quantity;
      case 'sortie':
        return currentStock - quantity;
      case 'correction':
        // Pour les corrections, on peut avoir des valeurs positives ou négatives
        return currentStock + quantity;
      case 'transfert':
        return currentStock - quantity;
      default:
        return currentStock;
    }
  }

  void _selectProduct() async {
    try {
      final controller = Get.find<InventoryGetxController>();

      // Charger les stocks si nécessaire
      if (controller.stocks.isEmpty) {
        await controller.loadStocks(refresh: true);
      }

      // Afficher un dialog de sélection
      final selectedStock = await showDialog<Stock>(
        context: context,
        builder: (context) => _ProductSelectionDialog(
          stocks: controller.stocks,
        ),
      );

      if (selectedStock != null) {
        setState(() {
          _selectedStock = selectedStock;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('stock_movement_selection_error'.trParams({'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitMovement() async {
    if (!_formKey.currentState!.validate() || _selectedStock == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final quantity = int.parse(_quantityController.text);
      final controller = Get.find<InventoryGetxController>();

      final success = await controller.createStockMovement(
        productId: _selectedStock!.produitId,
        typeMouvement: _selectedType,
        quantite: quantity,
        motif: _selectedMotif,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('stock_movement_success'.tr),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Dialog de sélection de produit
class _ProductSelectionDialog extends StatefulWidget {
  final List<Stock> stocks;

  const _ProductSelectionDialog({
    required this.stocks,
  });

  @override
  State<_ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Stock> _filteredStocks = [];

  @override
  void initState() {
    super.initState();
    _filteredStocks = widget.stocks;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStocks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStocks = widget.stocks;
      } else {
        _filteredStocks = widget.stocks.where((stock) {
          final produit = stock.produit;
          if (produit == null) return false;

          final searchLower = query.toLowerCase();
          return produit.nom.toLowerCase().contains(searchLower) || produit.reference.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'stock_movement_select_product'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'stock_movement_search_hint'.tr,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterStocks('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _filterStocks,
              ),
            ),
            const SizedBox(height: 16),

            // Liste des produits
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _filteredStocks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'stock_movement_no_products'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredStocks.length,
                        itemBuilder: (context, index) {
                          final stock = _filteredStocks[index];
                          final produit = stock.produit;

                          if (produit == null) return const SizedBox.shrink();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: stock.quantiteDisponible > 0 ? Colors.green.shade100 : Colors.red.shade100,
                                child: Icon(
                                  Icons.inventory_2,
                                  color: stock.quantiteDisponible > 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                produit.nom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${'stock_product_reference'.tr}: ${produit.reference}'),
                                  Text(
                                    '${'stock_quantities_available'.tr}: ${stock.quantiteDisponible} ${'stock_units'.tr}',
                                    style: TextStyle(
                                      color: stock.quantiteDisponible > 0 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.of(context).pop(stock),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
