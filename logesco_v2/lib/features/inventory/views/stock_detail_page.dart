import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';
import '../models/stock_model.dart';
import '../widgets/stock_movements_view.dart';
import 'stock_adjustment_page.dart';

class StockDetailPage extends StatefulWidget {
  final Stock stock;

  const StockDetailPage({
    Key? key,
    required this.stock,
  }) : super(key: key);

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Stock? _currentStock;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentStock = widget.stock;

    // Utiliser addPostFrameCallback pour éviter l'erreur d'inherited widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStockData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshStockData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final controller = Get.find<InventoryGetxController>();

      // Recharger les stocks pour obtenir les données à jour
      await controller.loadStocks(refresh: true);

      // Trouver le stock mis à jour dans la liste
      final updatedStock = controller.stocks.firstWhereOrNull(
        (stock) => stock.produitId == widget.stock.produitId,
      );

      if (updatedStock != null && mounted) {
        setState(() {
          _currentStock = updatedStock;
        });
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          'inventory_refresh_error'.trParams({'error': e.toString()}),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
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

  @override
  Widget build(BuildContext context) {
    final stock = _currentStock ?? widget.stock;
    final product = stock.produit;

    return Scaffold(
      appBar: AppBar(
        title: Text(product?.nom ?? 'inventory_detail_title'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStockData,
            tooltip: 'refresh'.tr,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'adjust',
                child: ListTile(
                  leading: const Icon(Icons.tune),
                  title: Text('inventory_detail_adjust'.tr),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('inventory_detail_history'.tr),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.info),
              text: 'inventory_detail_info'.tr,
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'inventory_detail_movements'.tr,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(stock),
          _buildMovementsTab(stock),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdjustment(stock),
        tooltip: 'inventory_detail_adjust'.tr,
        child: const Icon(Icons.tune),
      ),
    );
  }

  Widget _buildInfoTab(Stock stock) {
    final product = stock.produit;
    final isLowStock = stock.stockFaible ?? false;
    final isOutOfStock = stock.quantiteDisponible == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Statut du stock
          Card(
            color: _getStatusColor(isOutOfStock, isLowStock).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(isOutOfStock, isLowStock),
                    size: 48,
                    color: _getStatusColor(isOutOfStock, isLowStock),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(isOutOfStock, isLowStock),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _getStatusColor(isOutOfStock, isLowStock),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (isLowStock && !isOutOfStock)
                    Text(
                      'Stock inférieur au seuil minimum',
                      style: TextStyle(
                        color: _getStatusColor(isOutOfStock, isLowStock),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Informations du produit
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations du produit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (product != null) ...[
                    _buildInfoRow('Nom', product.nom),
                    _buildInfoRow('Référence', product.reference),
                    _buildInfoRow('Seuil minimum', '${product.seuilStockMinimum} unités'),
                    _buildInfoRow('Statut', product.estActif == true ? 'Actif' : 'Inactif'),
                  ] else ...[
                    const Text('Informations du produit non disponibles'),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quantités en stock
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantités en stock',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuantityCard(
                          'Disponible',
                          stock.quantiteDisponible.toString(),
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuantityCard(
                          'Réservé',
                          stock.quantiteReservee.toString(),
                          Icons.lock,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuantityCard(
                    'Total',
                    stock.quantiteTotale.toString(),
                    Icons.inventory_2,
                    Colors.green,
                    isWide: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dernière mise à jour
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dernière mise à jour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(stock.derniereMaj),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildMovementsTab(Stock stock) {
    // Filtrer les mouvements pour ce produit spécifique
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<InventoryGetxController>();
      controller.applyMovementFilters(produitId: stock.produitId);
    });

    return const StockMovementsView();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isOutOfStock, bool isLowStock) {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon(bool isOutOfStock, bool isLowStock) {
    if (isOutOfStock) return Icons.error;
    if (isLowStock) return Icons.warning;
    return Icons.check_circle;
  }

  String _getStatusText(bool isOutOfStock, bool isLowStock) {
    if (isOutOfStock) return 'RUPTURE DE STOCK';
    if (isLowStock) return 'STOCK FAIBLE';
    return 'STOCK OK';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'adjust':
        _navigateToAdjustment(_currentStock ?? widget.stock);
        break;
      case 'history':
        _tabController.animateTo(1);
        break;
    }
  }

  void _navigateToAdjustment(Stock stock) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => StockAdjustmentPage(initialStock: stock),
      ),
    )
        .then((_) {
      // Rafraîchir les données après l'ajustement
      _refreshStockData();
    });
  }
}
