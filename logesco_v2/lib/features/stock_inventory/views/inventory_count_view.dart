import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/inventory_model.dart';
import '../controllers/stock_inventory_controller.dart';

/// Vue de comptage d'inventaire - Fonctionnalité principale
class InventoryCountView extends StatefulWidget {
  const InventoryCountView({super.key});

  @override
  State<InventoryCountView> createState() => _InventoryCountViewState();
}

class _InventoryCountViewState extends State<InventoryCountView> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _countControllers = {};

  String _searchQuery = '';
  bool _showOnlyVariances = false;

  late final StockInventoryController _controller;
  int? _inventoryId;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<StockInventoryController>();

    // Attendre que le widget soit construit avant de charger les données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInventoryData();
    });
  }

  void _loadInventoryData() async {
    // Récupérer l'ID de l'inventaire depuis les paramètres de route
    final String? inventoryIdStr = Get.parameters['id'];
    print('🔍 ID inventaire depuis paramètres: $inventoryIdStr');

    if (inventoryIdStr != null) {
      _inventoryId = int.tryParse(inventoryIdStr);
      print('🔍 ID inventaire parsé: $_inventoryId');

      if (_inventoryId != null) {
        // S'assurer que les inventaires sont chargés
        if (_controller.inventories.isEmpty) {
          print('📦 Chargement des inventaires...');
          await _controller.loadInventories();
        }

        // Charger les articles de l'inventaire
        print('📋 Chargement des articles pour inventaire $_inventoryId...');
        await _controller.loadInventoryItems(_inventoryId!);
        print('📋 Articles chargés: ${_controller.currentInventoryItems.length}');

        // Sélectionner l'inventaire dans le contrôleur
        final inventory = _controller.inventories.firstWhereOrNull(
          (inv) => inv.id == _inventoryId,
        );
        print('🎯 Inventaire trouvé: ${inventory?.nom}');

        if (inventory != null) {
          _controller.selectInventory(inventory);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Disposer tous les contrôleurs de comptage
    for (var controller in _countControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Obtenir ou créer un contrôleur pour un article spécifique
  TextEditingController _getCountController(int itemId) {
    if (!_countControllers.containsKey(itemId)) {
      _countControllers[itemId] = TextEditingController();
    }
    return _countControllers[itemId]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final inventory = _controller.selectedInventory.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Comptage Inventaire'),
              Text(
                inventory?.nom ?? 'Inventaire',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInventorySheet,
            tooltip: 'Imprimer feuille de comptage',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Exporter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'close_inventory',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Clôturer inventaire'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          _buildFiltersSection(),
          Expanded(
            child: _buildInventoryList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildProgressHeader() {
    return Obx(() {
      final items = _controller.currentInventoryItems;
      final countedItems = items.where((item) => item.isCounted).length;
      final totalItems = items.length;
      final progress = totalItems > 0 ? countedItems / totalItems : 0.0;
      final varianceItems = items.where((item) => item.hasVariance).length;

      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.blue.shade50,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progression: $countedItems/$totalItems articles',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
            ),
            if (varianceItems > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$varianceItems écart(s) détecté(s)',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou code produit...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Afficher seulement les écarts'),
                  value: _showOnlyVariances,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyVariances = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return Obx(() {
      final filteredItems = _getFilteredItems();

      if (filteredItems.isEmpty) {
        return const Center(
          child: Text('Aucun article trouvé'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildInventoryItemCard(item);
        },
      );
    });
  }

  List<InventoryItem> _getFilteredItems() {
    print('🔍 Filtrage des articles: ${_controller.currentInventoryItems.length} articles disponibles');
    var filtered = _controller.currentInventoryItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty || item.nomProduit.toLowerCase().contains(_searchQuery) || (item.codeProduit?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesVarianceFilter = !_showOnlyVariances || item.hasVariance;

      return matchesSearch && matchesVarianceFilter;
    }).toList();

    // Trier par statut (non comptés en premier, puis écarts)
    filtered.sort((a, b) {
      if (!a.isCounted && b.isCounted) return -1;
      if (a.isCounted && !b.isCounted) return 1;
      if (a.hasVariance && !b.hasVariance) return -1;
      if (!a.hasVariance && b.hasVariance) return 1;
      return a.nomProduit.compareTo(b.nomProduit);
    });

    print('🔍 Articles filtrés: ${filtered.length}');
    return filtered;
  }

  Widget _buildInventoryItemCard(InventoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        item.nomProduit,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.codeProduit != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${item.codeProduit}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (item.categorieProduit != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.categorieProduit!,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusIndicator(item),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuantitySection(item),
            if (item.isCounted) ...[
              const SizedBox(height: 12),
              _buildCountingInfo(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(InventoryItem item) {
    if (!item.isCounted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'À compter',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    if (item.hasVariance) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 12, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Écart',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            'OK',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection(InventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qté Système',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      item.quantiteSysteme.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qté Comptée',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.isCounted)
                      Text(
                        item.quantiteComptee!.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _getCountController(item.id!),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _saveCount(item),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (item.isCounted) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Écart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        item.calculatedEcart >= 0 ? '+${item.calculatedEcart.toStringAsFixed(0)}' : item.calculatedEcart.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: item.calculatedEcart == 0
                              ? Colors.green
                              : item.calculatedEcart > 0
                                  ? Colors.blue
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountingInfo(InventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.person, size: 14, color: Colors.blue.shade600),
          const SizedBox(width: 4),
          Text(
            'Compté par ${item.nomUtilisateurComptage} le ${_formatDateTime(item.dateComptage!)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => _editCount(item),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 12, color: Colors.blue.shade600),
                const SizedBox(width: 2),
                Text(
                  'Modifier',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Obx(() {
      final items = _controller.currentInventoryItems;
      final countedItems = items.where((item) => item.isCounted).length;
      final totalItems = items.length;
      final isComplete = countedItems == totalItems;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _printInventorySheet,
                icon: const Icon(Icons.print),
                label: const Text('Imprimer feuille'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isComplete ? _finalizeInventory : null,
                icon: const Icon(Icons.check_circle),
                label: Text(isComplete ? 'Finaliser' : 'Incomplet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete ? Colors.green : null,
                  foregroundColor: isComplete ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _saveCount(InventoryItem item) async {
    final countController = _getCountController(item.id!);
    final countText = countController.text.trim();
    if (countText.isEmpty) return;

    final count = double.tryParse(countText);
    if (count == null) {
      Get.snackbar('Erreur', 'Veuillez entrer un nombre valide');
      return;
    }

    // Utiliser le contrôleur pour mettre à jour l'article
    final success = await _controller.updateInventoryItem(item.id!, count, null);

    if (success) {
      countController.clear();
    }
  }

  void _editCount(InventoryItem item) {
    final countController = _getCountController(item.id!);
    countController.text = item.quantiteComptee?.toStringAsFixed(0) ?? '';

    Get.dialog(
      AlertDialog(
        title: Text('Modifier le comptage - ${item.nomProduit}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quantité système: ${item.quantiteSysteme.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nouvelle quantité comptée',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _saveCount(item);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _printInventorySheet() {
    if (_inventoryId != null) {
      _controller.printCountingSheet(_inventoryId!);
    } else {
      Get.snackbar(
        'Erreur',
        'ID d\'inventaire manquant',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void _finalizeInventory() {
    final items = _controller.currentInventoryItems;
    final varianceItems = items.where((item) => item.hasVariance).length;

    Get.dialog(
      AlertDialog(
        title: const Text('Finaliser l\'inventaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Résumé de l\'inventaire:'),
            const SizedBox(height: 8),
            Text('• Articles comptés: ${items.where((i) => i.isCounted).length}'),
            Text('• Écarts détectés: $varianceItems'),
            const SizedBox(height: 16),
            if (varianceItems > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Attention: $varianceItems écart(s) seront appliqués au stock.',
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ),
            const SizedBox(height: 8),
            const Text('Voulez-vous finaliser cet inventaire ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _processFinalization();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finaliser'),
          ),
        ],
      ),
    );
  }

  void _processFinalization() async {
    if (_inventoryId == null) return;

    // Utiliser le contrôleur pour finaliser l'inventaire
    final success = await _controller.finishInventory(_inventoryId!);

    if (success) {
      Get.back(); // Retourner à la liste des inventaires
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        Get.snackbar('Export', 'Exportation en cours...');
        break;
      case 'close_inventory':
        _finalizeInventory();
        break;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
