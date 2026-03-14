import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';

class StockSummaryCard extends StatelessWidget {
  const StockSummaryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<InventoryController>(
      builder: (controller) {
        if (controller.isLoadingSummary && controller.summary == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (controller.summaryError != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[300],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur: ${controller.summaryError}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => controller.loadSummary(),
                    child: Text('stock_retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = controller.summary;
        if (summary == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Aucune donnée disponible',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dashboard,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Résumé du Stock',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    if (controller.isLoadingSummary)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Statistiques principales
                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        title: 'Total Produits',
                        value: summary.totalProduits.toString(),
                        icon: Icons.inventory_2,
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        title: 'En Stock',
                        value: summary.produitsEnStock.toString(),
                        subtitle: '${summary.pourcentageEnStock}%',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        title: 'En Alerte',
                        value: summary.produitsEnAlerte.toString(),
                        subtitle: '${summary.pourcentageEnAlerte}%',
                        icon: Icons.warning,
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        title: 'En Rupture',
                        value: summary.produitsEnRupture.toString(),
                        subtitle: '${summary.pourcentageEnRupture}%',
                        icon: Icons.error,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Valeur totale du stock
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valeur Totale du Stock',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatCurrency(summary.valeurTotaleStock)} FCFA',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withOpacity(0.8),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
