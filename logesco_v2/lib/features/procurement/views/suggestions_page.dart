import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/procurement_controller.dart';
import '../services/suggestion_service.dart';
import '../../suppliers/models/supplier.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({Key? key}) : super(key: key);

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  final ProcurementController _controller = Get.find<ProcurementController>();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  Supplier? _selectedSupplier;
  int _periodeAnalyse = 30;
  String _filtreUrgence = 'tous'; // tous, urgentes, normales
  final List<SuggestionApprovisionnement> _selectedSuggestions = [];
  final Map<int, double> _modifiedQuantities = {}; // Pour stocker les quantités modifiées
  final Map<int, TextEditingController> _quantityControllers = {}; // Contrôleurs pour les champs de saisie
  final List<Supplier> _availableSuppliers = []; // Liste des fournisseurs réels

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadSuppliers();
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadSuppliers() async {
    try {
      // Charger les fournisseurs depuis l'API
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/procurement/suppliers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final fournisseurs = (data['data']['fournisseurs'] as List).map((json) => Supplier.fromJson(json)).toList();

          setState(() {
            _availableSuppliers.clear();
            _availableSuppliers.addAll(fournisseurs);

            // Sélectionner automatiquement le premier fournisseur
            if (fournisseurs.isNotEmpty && _selectedSupplier == null) {
              _selectedSupplier = fournisseurs.first;
            }
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des fournisseurs: $e');
      // En cas d'erreur, utiliser un fournisseur par défaut
      setState(() {
        _availableSuppliers.add(Supplier(
          id: 1,
          nom: 'Fournisseur par défaut',
          dateCreation: DateTime.now(),
          dateModification: DateTime.now(),
        ));
        _selectedSupplier = _availableSuppliers.first;
      });
    }
  }

  Future<String?> _getToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: AppConstants.authTokenKey);
  }

  void _loadSuggestions() {
    _controller.loadSuggestions(
      fournisseurId: _selectedSupplier?.id,
      periodeAnalyse: _periodeAnalyse,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('procurement_suggestions_title'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuggestions,
          ),
          if (_selectedSuggestions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: _showGenerateOrderDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          _buildFilters(),

          // Liste des suggestions
          Expanded(
            child: Obx(() {
              if (_controller.isLoadingSuggestions.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final suggestions = _getFilteredSuggestions();

              if (suggestions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'procurement_suggestions_no_data'.tr,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return _buildSuggestionCard(suggestion);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: _selectedSuggestions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showGenerateOrderDialog,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('procurement_suggestions_selected_count'.tr.replaceAll('@count', _selectedSuggestions.length.toString())),
            )
          : null,
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'procurement_suggestions_filters'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Période d'analyse
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _periodeAnalyse,
                    decoration: InputDecoration(
                      labelText: 'procurement_suggestions_period'.tr,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    items: [
                      DropdownMenuItem(value: 7, child: Text('procurement_period_7_days'.tr)),
                      DropdownMenuItem(value: 15, child: Text('procurement_period_15_days'.tr)),
                      DropdownMenuItem(value: 30, child: Text('procurement_period_30_days'.tr)),
                      DropdownMenuItem(value: 60, child: Text('procurement_period_60_days'.tr)),
                      DropdownMenuItem(value: 90, child: Text('procurement_period_90_days'.tr)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _periodeAnalyse = value!;
                      });
                      _loadSuggestions();
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Filtre urgence
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtreUrgence,
                    decoration: InputDecoration(
                      labelText: 'procurement_suggestions_urgency'.tr,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.priority_high),
                    ),
                    items: [
                      DropdownMenuItem(value: 'tous', child: Text('procurement_suggestions_all'.tr)),
                      DropdownMenuItem(value: 'urgentes', child: Text('procurement_suggestions_urgent'.tr)),
                      DropdownMenuItem(value: 'normales', child: Text('procurement_suggestions_normal'.tr)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtreUrgence = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(SuggestionApprovisionnement suggestion) {
    final isSelected = _selectedSuggestions.contains(suggestion);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedSuggestions.remove(suggestion);
            } else {
              _selectedSuggestions.add(suggestion);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec sélection
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedSuggestions.add(suggestion);
                        } else {
                          _selectedSuggestions.remove(suggestion);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.produit.nom,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (suggestion.produit.reference.isNotEmpty)
                          Text(
                            'Réf: ${suggestion.produit.reference}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  _buildPriorityChip(suggestion.priorite),
                ],
              ),

              const SizedBox(height: 12),

              // Informations de stock
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'procurement_suggestion_current_stock',
                      suggestion.stockActuel.toString(),
                      Icons.inventory,
                      suggestion.estEnRupture ? Colors.red : Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'procurement_suggestion_min_threshold',
                      suggestion.seuilMinimum.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'procurement_suggestion_days_remaining',
                      suggestion.joursStockRestant.toString(),
                      Icons.schedule,
                      suggestion.joursStockRestant <= 3 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Suggestion et coût
              Row(
                children: [
                  Expanded(
                    child: _buildEditableQuantityItem(suggestion),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'procurement_suggestion_unit_cost',
                      _currencyFormat.format(suggestion.coutUnitaireEstime),
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'procurement_suggestion_total_cost',
                      _currencyFormat.format(_calculateTotal(suggestion)),
                      Icons.calculate,
                      Colors.indigo,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Raison et statistiques
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'procurement_suggestion_reason'.tr}: ${suggestion.raison}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'procurement_suggestion_avg_sales'.tr}: ${suggestion.moyenneVentesJournalieres.toStringAsFixed(1)} • '
                      '${'procurement_suggestion_rotation_rate'.tr}: ${(suggestion.tauxRotation * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label.tr,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String priorite) {
    Color color;
    IconData icon;

    switch (priorite) {
      case 'haute':
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 'moyenne':
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case 'faible':
        color = Colors.green;
        icon = Icons.keyboard_arrow_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    String translationKey = 'procurement_priority_${priorite}';

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        translationKey.tr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildEditableQuantityItem(SuggestionApprovisionnement suggestion) {
    // Initialiser le contrôleur si nécessaire
    if (!_quantityControllers.containsKey(suggestion.id)) {
      final currentQuantity = _modifiedQuantities[suggestion.id] ?? suggestion.quantiteSuggeree;
      _quantityControllers[suggestion.id] = TextEditingController(
        text: currentQuantity.toStringAsFixed(1),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Icon(Icons.edit, color: Colors.green, size: 20),
          const SizedBox(height: 4),
          Text(
            'procurement_suggestion_suggested_qty'.tr,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _quantityControllers[suggestion.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _isQuantityModified(suggestion) ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                border: const OutlineInputBorder(),
                suffixIcon: _isQuantityModified(suggestion) ? const Icon(Icons.edit, size: 12, color: Colors.orange) : null,
              ),
              onChanged: (value) {
                final quantity = double.tryParse(value) ?? suggestion.quantiteSuggeree;
                setState(() {
                  _modifiedQuantities[suggestion.id] = quantity;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal(SuggestionApprovisionnement suggestion) {
    final quantity = _modifiedQuantities[suggestion.id] ?? suggestion.quantiteSuggeree;
    return quantity * suggestion.coutUnitaireEstime;
  }

  double _calculateSelectedTotal() {
    return _selectedSuggestions.fold(0.0, (total, suggestion) {
      return total + _calculateTotal(suggestion);
    });
  }

  bool _isQuantityModified(SuggestionApprovisionnement suggestion) {
    final modifiedQty = _modifiedQuantities[suggestion.id];
    return modifiedQty != null && modifiedQty != suggestion.quantiteSuggeree;
  }

  List<SuggestionApprovisionnement> _getFilteredSuggestions() {
    var suggestions = _controller.suggestions.toList();

    switch (_filtreUrgence) {
      case 'urgentes':
        suggestions = suggestions.where((s) => s.estUrgente).toList();
        break;
      case 'normales':
        suggestions = suggestions.where((s) => !s.estUrgente).toList();
        break;
    }

    // Trier par priorité puis par jours restants
    suggestions.sort((a, b) {
      final priorityOrder = {'haute': 0, 'moyenne': 1, 'faible': 2};
      final aPriority = priorityOrder[a.priorite] ?? 3;
      final bPriority = priorityOrder[b.priorite] ?? 3;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      return a.joursStockRestant.compareTo(b.joursStockRestant);
    });

    return suggestions;
  }

  void _showGenerateOrderDialog() {
    if (_selectedSuggestions.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('procurement_generate_dialog_title'.tr),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('procurement_generate_products_selected'.tr.replaceAll('@count', _selectedSuggestions.length.toString())),
                const SizedBox(height: 8),
                Text(
                  'procurement_generate_total_amount'.tr.replaceAll('@amount', _currencyFormat.format(_calculateSelectedTotal())),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Sélection du fournisseur
                Text(
                  'procurement_generate_supplier'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Supplier>(
                  value: _selectedSupplier,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'procurement_generate_select_supplier'.tr,
                    prefixIcon: const Icon(Icons.business),
                  ),
                  items: _getAvailableSuppliers().map((supplier) {
                    return DropdownMenuItem<Supplier>(
                      value: supplier,
                      child: Text(supplier.nom),
                    );
                  }).toList(),
                  onChanged: (supplier) {
                    setDialogState(() {
                      _selectedSupplier = supplier;
                    });
                  },
                ),

                const SizedBox(height: 16),
                Text('procurement_generate_message'.tr),

                // Résumé des quantités modifiées
                if (_modifiedQuantities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'procurement_generate_modified_quantities'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _selectedSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _selectedSuggestions[index];
                        final originalQty = suggestion.quantiteSuggeree;
                        final modifiedQty = _modifiedQuantities[suggestion.id] ?? originalQty;
                        final isModified = modifiedQty != originalQty;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  suggestion.produit.nom,
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${modifiedQty.toStringAsFixed(1)}${isModified ? ' (${originalQty.toStringAsFixed(1)})' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isModified ? Colors.orange : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: _selectedSupplier != null
                  ? () {
                      Navigator.of(context).pop();
                      _generateOrder();
                    }
                  : null,
              child: Text('procurement_generate_button'.tr),
            ),
          ],
        ),
      ),
    );
  }

  List<Supplier> _getAvailableSuppliers() {
    // Retourner les fournisseurs chargés depuis l'API
    return _availableSuppliers;
  }

  void _generateOrder() async {
    if (_selectedSupplier == null) {
      Get.snackbar(
        'error'.tr,
        'procurement_generate_error_no_supplier'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Préparer les suggestions avec les quantités modifiées
    final suggestionsAvecQuantitesModifiees = _selectedSuggestions.map((suggestion) {
      final quantiteModifiee = _modifiedQuantities[suggestion.id] ?? suggestion.quantiteSuggeree;

      // Créer une nouvelle suggestion avec la quantité modifiée
      return SuggestionApprovisionnement(
        id: suggestion.id,
        produit: suggestion.produit,
        stockActuel: suggestion.stockActuel,
        seuilMinimum: suggestion.seuilMinimum,
        moyenneVentesJournalieres: suggestion.moyenneVentesJournalieres,
        quantiteSuggeree: quantiteModifiee,
        coutUnitaireEstime: suggestion.coutUnitaireEstime,
        montantTotal: quantiteModifiee * suggestion.coutUnitaireEstime,
        priorite: suggestion.priorite,
        raison: suggestion.raison,
        joursStockRestant: suggestion.joursStockRestant,
        tauxRotation: suggestion.tauxRotation,
      );
    }).toList();

    final success = await _controller.genererCommandeAutomatique(
      fournisseurId: _selectedSupplier!.id,
      suggestionsSelectionnees: suggestionsAvecQuantitesModifiees,
    );

    if (success) {
      setState(() {
        _selectedSuggestions.clear();
        _modifiedQuantities.clear();
        // Nettoyer les contrôleurs
        for (var controller in _quantityControllers.values) {
          controller.dispose();
        }
        _quantityControllers.clear();
      });
      _loadSuggestions();

      Get.snackbar(
        'success'.tr,
        'procurement_generate_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}
