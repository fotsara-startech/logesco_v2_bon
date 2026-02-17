/**
 * Dialogue pour créer une nouvelle commande d'approvisionnement
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../products/models/product.dart';
import '../../suppliers/models/supplier.dart';
import '../../suppliers/controllers/supplier_controller.dart';
import '../../products/controllers/product_controller.dart';
import '../../inventory/services/inventory_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/constants/constants.dart';
import '../controllers/procurement_controller.dart';
import '../models/procurement_models.dart';

class CreateCommandeDialog extends StatefulWidget {
  final ProcurementController controller;

  const CreateCommandeDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<CreateCommandeDialog> createState() => _CreateCommandeDialogState();
}

class _CreateCommandeDialogState extends State<CreateCommandeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.resetNouvelleCommande();
    // Définir la date de livraison par défaut à aujourd'hui + 7 jours
    widget.controller.dateLivraisonPrevue.value = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  const Icon(Icons.add_shopping_cart, size: 28, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nouvelle commande d\'approvisionnement',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Contenu principal
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonne de gauche - Informations générales
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fournisseur
                            _buildFournisseurSection(),

                            const SizedBox(height: 24),

                            // Date de livraison
                            _buildDateLivraisonSection(),

                            const SizedBox(height: 24),

                            // Mode de paiement
                            _buildModePaiementSection(),

                            const SizedBox(height: 24),

                            // Notes
                            _buildNotesSection(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 32),

                    // Colonne de droite - Produits
                    Expanded(
                      flex: 2,
                      child: _buildProduitsSection(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Montant total
                  Obx(() => Text(
                        'Total: ${CurrencyConstants.formatAmount(widget.controller.montantTotalNouvelleCommande)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      )),

                  // Boutons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      Obx(() => ElevatedButton(
                            onPressed: widget.controller.isCreating.value ? null : _creerCommande,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: widget.controller.isCreating.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Créer la commande'),
                          )),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFournisseurSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fournisseur *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.controller.fournisseurSelectionne.value != null
                  ? Row(
                      children: [
                        const Icon(Icons.business, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.controller.fournisseurSelectionne.value!.nom,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (widget.controller.fournisseurSelectionne.value!.telephone != null)
                                Text(
                                  widget.controller.fournisseurSelectionne.value!.telephone!,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => widget.controller.fournisseurSelectionne.value = null,
                          icon: const Icon(Icons.clear, color: Colors.red),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: _selectionnerFournisseur,
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Sélectionner un fournisseur',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
            )),
      ],
    );
  }

  Widget _buildDateLivraisonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date de livraison prévue',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Obx(() => InkWell(
              onTap: _selectionnerDateLivraison,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      widget.controller.dateLivraisonPrevue.value != null ? _formatDate(widget.controller.dateLivraisonPrevue.value!) : 'Sélectionner une date',
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildModePaiementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de paiement',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Obx(() => Column(
              children: ModePaiement.values.map((mode) {
                return RadioListTile<ModePaiement>(
                  title: Text(mode.label),
                  value: mode,
                  groupValue: widget.controller.modePaiement.value,
                  onChanged: (value) => widget.controller.modePaiement.value = value!,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Notes optionnelles...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => widget.controller.notes.value = value,
        ),
      ],
    );
  }

  Widget _buildProduitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Produits *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _ajouterProduit,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(() {
              if (widget.controller.detailsCommande.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Aucun produit ajouté',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: widget.controller.detailsCommande.length,
                itemBuilder: (context, index) {
                  final detail = widget.controller.detailsCommande[index];
                  return _buildProduitItem(detail);
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildProduitItem(DetailCommandeCreation detail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.produit.nom,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Réf: ${detail.produit.reference}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Qté: ${detail.quantite}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Prix: ${CurrencyConstants.formatAmount(detail.coutUnitaire)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyConstants.formatAmount(detail.montantTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: () => widget.controller.supprimerProduit(detail.produit.id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectionnerFournisseur() async {
    try {
      final supplierController = Get.find<SupplierController>();

      if (supplierController.suppliers.isEmpty) {
        await supplierController.loadSuppliers();
      }

      if (supplierController.suppliers.isEmpty) {
        Get.snackbar(
          'Aucun fournisseur',
          'Veuillez d\'abord créer des fournisseurs',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final selectedSupplier = await showDialog<Supplier>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sélectionner un fournisseur'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: ListView.builder(
              itemCount: supplierController.suppliers.length,
              itemBuilder: (context, index) {
                final supplier = supplierController.suppliers[index];
                return ListTile(
                  title: Text(supplier.nom),
                  subtitle: Text(supplier.telephone ?? 'Pas de téléphone'),
                  onTap: () => Navigator.of(context).pop(supplier),
                );
              },
            ),
          ),
        ),
      );

      if (selectedSupplier != null) {
        widget.controller.fournisseurSelectionne.value = selectedSupplier;
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les fournisseurs: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _selectionnerDateLivraison() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.controller.dateLivraisonPrevue.value ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      widget.controller.dateLivraisonPrevue.value = date;
    }
  }

  void _ajouterProduit() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _ProductSelectionDialog(),
      );

      if (result != null) {
        final product = result['product'] as Product;
        final quantity = result['quantity'] as int;
        final unitCost = result['unitCost'] as double;

        widget.controller.ajouterProduit(product, quantity, unitCost);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les produits: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _creerCommande() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await widget.controller.createCommande();
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = amount.toStringAsFixed(0);
    return result.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
  }
}

/// Dialogue pour sélectionner un produit avec recherche, quantité et coût unitaire
class _ProductSelectionDialog extends StatefulWidget {
  const _ProductSelectionDialog();

  @override
  State<_ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  late ProductController productController;
  late InventoryService inventoryService;
  Product? selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _unitCostController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late ScrollController _scrollController;

  List<Product> filteredProducts = [];
  bool _isSearching = false;
  final RxMap<int, int> _productStocks = RxMap<int, int>(); // Cache reactif pour les stocks

  @override
  void initState() {
    super.initState();
    productController = Get.find<ProductController>();
    inventoryService = InventoryService(Get.find<AuthService>());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Charger les produits au démarrage
    _loadAllProducts();
    _searchController.addListener(_filterProducts);
  }

  void _loadAllProducts() async {
    // Le ProductController charge maintenant tous les produits à la fois
    // Pas besoin de boucle while pour la pagination
    await productController.loadProducts();
    _filterProducts();

    // Charger les stocks de tous les produits en parallèle
    _loadProductStocks();
  }

  /// Charge les stocks de tous les produits affichés
  void _loadProductStocks() async {
    try {
      // Charger tous les stocks en parallèle pour une meilleure performance
      final futures = productController.products.map((product) async {
        try {
          final response = await inventoryService.getProductStock(product.id);
          if (response.success && response.data != null) {
            _productStocks[product.id] = response.data!.quantiteDisponible;
            print('📦 Stock chargé pour ${product.nom}: ${response.data!.quantiteDisponible}');
          }
        } catch (e) {
          print('⚠️ Erreur chargement stock ${product.nom}: $e');
          _productStocks[product.id] = 0; // Définir à 0 en cas d'erreur
        }
      });

      // Attendre que tous les stocks soient chargés
      await Future.wait(futures);
      print('✅ Tous les stocks ont été chargés');
    } catch (e) {
      print('❌ Erreur lors du chargement des stocks: $e');
    }
  }

  void _onScroll() {
    // Pagination infinie désactivée - tous les produits sont déjà chargés
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        filteredProducts = productController.products.where((product) => product.estActif && !product.estService).toList();
        print('🔍 Affichage: ${filteredProducts.length} produits actifs');
      } else {
        _isSearching = true;
        filteredProducts = productController.products.where((product) {
          return product.estActif &&
              !product.estService &&
              (product.nom.toLowerCase().contains(query) || product.reference.toLowerCase().contains(query) || (product.description?.toLowerCase().contains(query) ?? false));
        }).toList();
        print('🔍 Recherche "$query": ${filteredProducts.length} produits trouvés');
      }

      if (selectedProduct != null && !filteredProducts.contains(selectedProduct)) {
        selectedProduct = null;
        _unitCostController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  const Icon(Icons.add_shopping_cart, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ajouter un produit',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Recherche de produit
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher un produit',
                  hintText: 'Nom, référence ou description...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Liste des produits avec pagination
              Obx(() {
                final isLoading = productController.isLoading.value;
                final hasMoreData = productController.hasMoreData.value;
                final totalLoaded = productController.products.length;

                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sélectionner un produit (${filteredProducts.length} sur $totalLoaded produits):',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isLoading && filteredProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 12),
                                      Text('Chargement des produits...', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                )
                              : filteredProducts.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Aucun produit trouvé',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : Stack(
                                      children: [
                                        ListView.builder(
                                          controller: _scrollController,
                                          itemCount: filteredProducts.length + (hasMoreData && !_isSearching ? 1 : 0),
                                          itemBuilder: (context, index) {
                                            // Afficher le loading indicator à la fin
                                            if (index >= filteredProducts.length) {
                                              return Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: Center(
                                                  child: Column(
                                                    children: [
                                                      const CircularProgressIndicator(strokeWidth: 2),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Chargement de plus...',
                                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }

                                            final product = filteredProducts[index];
                                            final isSelected = selectedProduct?.id == product.id;

                                            return ListTile(
                                              selected: isSelected,
                                              selectedTileColor: Colors.blue.withOpacity(0.1),
                                              leading: CircleAvatar(
                                                backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                                                child: Icon(
                                                  Icons.inventory_2,
                                                  color: isSelected ? Colors.white : Colors.grey[600],
                                                ),
                                              ),
                                              title: Text(
                                                product.nom,
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Réf: ${product.reference}'),
                                                  if (product.description != null && product.description!.isNotEmpty)
                                                    Text(
                                                      product.description!,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  // Afficher le stock disponible
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: _buildStockIndicator(product),
                                                  ),
                                                ],
                                              ),
                                              trailing: Text(
                                                CurrencyConstants.formatAmount(product.prixUnitaire),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  selectedProduct = product;
                                                  _unitCostController.text = (product.prixAchat ?? product.prixUnitaire * 0.8).toStringAsFixed(0);
                                                  print('✅ Produit sélectionné: ${product.nom}');
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Formulaire de quantité et coût
              if (selectedProduct != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produit sélectionné: ${selectedProduct!.nom}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Quantité
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantité *',
                                border: OutlineInputBorder(),
                                suffixText: 'unités',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final quantity = int.tryParse(value);
                                if (quantity == null || quantity <= 0) {
                                  return 'Quantité invalide';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Coût unitaire
                          Expanded(
                            child: TextFormField(
                              controller: _unitCostController,
                              decoration: const InputDecoration(
                                labelText: 'Coût unitaire *',
                                border: OutlineInputBorder(),
                                suffixText: CurrencyConstants.defaultCurrency,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                final cost = double.tryParse(value);
                                if (cost == null || cost <= 0) {
                                  return 'Coût invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Calcul du total
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calculate, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Total: ${CurrencyConstants.formatAmount(_calculateTotal())}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: selectedProduct != null ? _addProduct : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit un indicateur visuel du stock disponible
  Widget _buildStockIndicator(Product product) {
    return Obx(() {
      // Utiliser le stock en cache si disponible, sinon afficher un placeholder
      final rawStock = _productStocks[product.id] ?? 0;
      final isLowStock = rawStock > 0 && rawStock <= product.seuilStockMinimum;
      final isOutOfStock = rawStock == 0;

      Color stockColor;
      String stockText;
      IconData stockIcon;

      if (isOutOfStock) {
        stockColor = Colors.red;
        stockIcon = Icons.cancel;
        stockText = 'Rupture de stock';
      } else if (isLowStock) {
        stockColor = Colors.orange;
        stockIcon = Icons.warning;
        stockText = 'Stock faible: $rawStock unités';
      } else {
        stockColor = Colors.green;
        stockIcon = Icons.check_circle;
        stockText = 'Disponible: $rawStock unités';
      }

      return Row(
        children: [
          Icon(
            stockIcon,
            size: 14,
            color: stockColor,
          ),
          const SizedBox(width: 6),
          Text(
            stockText,
            style: TextStyle(
              fontSize: 12,
              color: stockColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    });
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = amount.toStringAsFixed(0);
    return result.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
  }

  double _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitCost = double.tryParse(_unitCostController.text) ?? 0;
    return quantity * unitCost;
  }

  void _addProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final quantity = int.parse(_quantityController.text);
      final unitCost = double.parse(_unitCostController.text);

      Navigator.of(context).pop({
        'product': selectedProduct,
        'quantity': quantity,
        'unitCost': unitCost,
      });
    }
  }
}
