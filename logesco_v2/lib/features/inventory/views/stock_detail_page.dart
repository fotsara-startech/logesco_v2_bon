import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../controllers/inventory_getx_controller.dart';
import '../models/stock_model.dart';
import '../services/inventory_service.dart';
import '../../../core/services/auth_service.dart';
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

  // Mouvements locaux — chargés indépendamment du controller partagé
  final List<StockMovement> _movements = [];
  bool _isLoadingMovements = false;
  String? _movementsError;

  late final InventoryService _inventoryService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentStock = widget.stock;
    _inventoryService = InventoryService(Get.find<AuthService>());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStockData();
      _loadMovements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMovements = true;
      _movementsError = null;
    });
    try {
      final result = await _inventoryService.getStockMovements(
        produitId: widget.stock.produitId,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _movements
            ..clear()
            ..addAll(result.data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _movementsError = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoadingMovements = false);
    }
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
        SnackbarHelper.error('stock_refresh_error'.trParams({'error': e.toString()}));
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
        title: Text(product?.nom ?? 'stock_detail_title'.tr),
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
              // PopupMenuItem(
              //   value: 'adjust',
              //   child: ListTile(
              //     leading: const Icon(Icons.tune),
              //     title: Text('stock_detail_adjust'.tr),
              //     contentPadding: EdgeInsets.zero,
              //   ),
              // ),
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('stock_detail_history'.tr),
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
              text: 'stock_detail_product_info'.tr,
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'stock_movements_title'.tr,
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _navigateToAdjustment(stock),
      //   tooltip: 'stock_detail_adjust'.tr,
      //   child: const Icon(Icons.tune),
      // ),
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
                      'stock_detail_low_stock_threshold'.tr,
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
                    'stock_detail_product_info'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (product != null) ...[
                    _buildInfoRow('stock_product_name'.tr, product.nom),
                    _buildInfoRow('stock_product_reference'.tr, product.reference),
                    _buildInfoRow('stock_product_min_threshold'.tr, '${product.seuilStockMinimum} ${'stock_units'.tr}'),
                    _buildInfoRow('stock_product_status'.tr, product.estActif == true ? 'stock_status_active'.tr : 'stock_status_inactive'.tr),
                  ] else ...[
                    Text('stock_product_info_unavailable'.tr),
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
                    'stock_detail_quantities'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuantityCard(
                          'stock_quantities_available'.tr,
                          stock.quantiteDisponible.toString(),
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuantityCard(
                          'stock_quantities_reserved'.tr,
                          stock.quantiteReservee.toString(),
                          Icons.lock,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuantityCard(
                    'stock_quantities_total'.tr,
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
                    'stock_detail_last_update'.tr,
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
    if (_isLoadingMovements) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_movementsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_movementsError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMovements,
              child: Text('common_retry'.tr),
            ),
          ],
        ),
      );
    }
    if (_movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('stock_no_movements'.tr, style: const TextStyle(fontSize: 18)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMovements,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _movements.length,
        itemBuilder: (context, index) {
          final movement = _movements[index];
          final isPositive = movement.changementQuantite > 0;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _movementColor(movement.typeMouvement),
                child: Icon(_movementIcon(movement.typeMouvement), color: Colors.white, size: 20),
              ),
              title: Text(
                stock.produit?.nom ?? 'Produit inconnu',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stock.produit?.reference != null) Text('Réf: ${stock.produit!.reference}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(_formatDate(movement.dateMouvement), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.category, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(_movementLabel(movement.typeMouvement), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]),
                  if (movement.notes != null && movement.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.note, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(movement.notes!.tr, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${movement.changementQuantite}',
                      style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(_timeAgo(movement.dateMouvement), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _movementColor(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
      case 'approvisionnement':
        return Colors.green;
      case 'vente':
        return Colors.blue;
      case 'ajustement':
        return Colors.orange;
      case 'retour':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _movementIcon(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
      case 'approvisionnement':
        return Icons.add_shopping_cart;
      case 'vente':
        return Icons.shopping_bag;
      case 'ajustement':
        return Icons.tune;
      case 'retour':
        return Icons.undo;
      default:
        return Icons.swap_horiz;
    }
  }

  String _movementLabel(String type) {
    switch (type.toLowerCase()) {
      case 'achat':
        return 'Achat';
      case 'vente':
        return 'Vente';
      case 'ajustement':
        return 'Ajustement';
      case 'retour':
        return 'Retour';
      case 'approvisionnement':
        return 'Approvisionnement';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (d == today) return '${'time_today'.tr} $time';
    if (d == yesterday) return '${'time_yesterday'.tr} $time';
    return '${date.day}/${date.month}/${date.year} $time';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'time_ago_days'.trParams({'count': diff.inDays.toString()});
    if (diff.inHours > 0) return 'time_ago_hours'.trParams({'count': diff.inHours.toString()});
    if (diff.inMinutes > 0) return 'time_ago_minutes'.trParams({'count': diff.inMinutes.toString()});
    return 'time_just_now'.tr;
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
    if (isOutOfStock) return 'stock_status_stockout'.tr;
    if (isLowStock) return 'stock_status_low_stock'.tr;
    return 'stock_status_ok'.tr;
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
