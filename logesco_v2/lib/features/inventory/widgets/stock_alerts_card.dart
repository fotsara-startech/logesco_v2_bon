import 'package:flutter/material.dart';
import '../models/stock_model.dart';

class StockAlertsCard extends StatelessWidget {
  final List<Stock> alerts;

  const StockAlertsCard({
    Key? key,
    required this.alerts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune alerte de stock',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Tous les produits ont un stock suffisant',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final stock = alerts[index];
        return StockAlertItem(stock: stock);
      },
    );
  }
}

class StockAlertItem extends StatelessWidget {
  final Stock stock;

  const StockAlertItem({
    Key? key,
    required this.stock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = stock.produit;
    final isOutOfStock = stock.quantiteDisponible == 0;
    final urgencyLevel = _getUrgencyLevel();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: _getCardColor(urgencyLevel),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIconColor(urgencyLevel),
          child: Icon(
            isOutOfStock ? Icons.error : Icons.warning,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          product?.nom ?? 'Produit inconnu',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product?.reference != null)
              Text(
                'Réf: ${product!.reference}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Stock actuel: ${stock.quantiteDisponible}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.trending_down,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Seuil: ${product?.seuilStockMinimum ?? 0}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildUrgencyIndicator(urgencyLevel),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAlertChip(isOutOfStock),
            const SizedBox(height: 4),
            Text(
              _getTimeAgo(stock.derniereMaj),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: () => _showStockActions(context),
      ),
    );
  }

  AlertUrgency _getUrgencyLevel() {
    final product = stock.produit;
    if (product == null) return AlertUrgency.medium;

    if (stock.quantiteDisponible == 0) {
      return AlertUrgency.critical;
    }

    final ratio = stock.quantiteDisponible / product.seuilStockMinimum;
    if (ratio <= 0.2) return AlertUrgency.high;
    if (ratio <= 0.5) return AlertUrgency.medium;
    return AlertUrgency.low;
  }

  Color _getCardColor(AlertUrgency urgency) {
    switch (urgency) {
      case AlertUrgency.critical:
        return Colors.red.withOpacity(0.05);
      case AlertUrgency.high:
        return Colors.orange.withOpacity(0.05);
      case AlertUrgency.medium:
        return Colors.yellow.withOpacity(0.05);
      case AlertUrgency.low:
        return Colors.blue.withOpacity(0.05);
    }
  }

  Color _getIconColor(AlertUrgency urgency) {
    switch (urgency) {
      case AlertUrgency.critical:
        return Colors.red;
      case AlertUrgency.high:
        return Colors.orange;
      case AlertUrgency.medium:
        return Colors.yellow[700]!;
      case AlertUrgency.low:
        return Colors.blue;
    }
  }

  Widget _buildUrgencyIndicator(AlertUrgency urgency) {
    String label;
    Color color;

    switch (urgency) {
      case AlertUrgency.critical:
        label = 'CRITIQUE - Rupture de stock';
        color = Colors.red;
        break;
      case AlertUrgency.high:
        label = 'URGENT - Stock très faible';
        color = Colors.orange;
        break;
      case AlertUrgency.medium:
        label = 'ATTENTION - Stock faible';
        color = Colors.yellow[700]!;
        break;
      case AlertUrgency.low:
        label = 'INFO - Approche du seuil';
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAlertChip(bool isOutOfStock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOutOfStock ? Colors.red : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOutOfStock ? 'RUPTURE' : 'ALERTE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  void _showStockActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StockActionSheet(stock: stock),
    );
  }
}

class StockActionSheet extends StatelessWidget {
  final Stock stock;

  const StockActionSheet({
    Key? key,
    required this.stock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stock.produit?.nom ?? 'Produit',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.green),
            title: const Text('Ajuster le stock'),
            subtitle: const Text('Modifier la quantité disponible'),
            onTap: () {
              Navigator.of(context).pop();
              _showAdjustmentDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.blue),
            title: const Text('Commander'),
            subtitle: const Text('Créer une commande d\'approvisionnement'),
            onTap: () {
              Navigator.of(context).pop();
              _showOrderDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.orange),
            title: const Text('Voir l\'historique'),
            subtitle: const Text('Consulter les mouvements de stock'),
            onTap: () {
              Navigator.of(context).pop();
              _showStockHistory(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context) {
    // TODO: Implémenter le dialogue d'ajustement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajustement de stock - À implémenter')),
    );
  }

  void _showOrderDialog(BuildContext context) {
    // TODO: Implémenter le dialogue de commande
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande d\'approvisionnement - À implémenter')),
    );
  }

  void _showStockHistory(BuildContext context) {
    // TODO: Implémenter l'historique des mouvements
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique des mouvements - À implémenter')),
    );
  }
}

enum AlertUrgency {
  critical,
  high,
  medium,
  low,
}
