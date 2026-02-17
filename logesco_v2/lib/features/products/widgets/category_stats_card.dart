import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';

/// Widget affichant les statistiques des catégories
class CategoryStatsCard extends GetView<ProductController> {
  const CategoryStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.products.isEmpty) {
        return const SizedBox.shrink();
      }

      final categoryStats = _calculateCategoryStats();

      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Répartition par catégorie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (categoryStats.isEmpty)
                const Text(
                  'Aucune catégorie définie',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...categoryStats.entries.map((entry) => _buildCategoryStatItem(context, entry.key, entry.value)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoryStatItem(BuildContext context, String category, int count) {
    final total = controller.products.length;
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              category.isEmpty ? 'Sans catégorie' : category,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '$count ($percentage%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateCategoryStats() {
    final stats = <String, int>{};

    for (final product in controller.products) {
      final category = product.categorie ?? '';
      stats[category] = (stats[category] ?? 0) + 1;
    }

    // Trier par nombre de produits (décroissant)
    final sortedEntries = stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }
}
