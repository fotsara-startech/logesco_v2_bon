import 'package:flutter/material.dart';
import '../models/financial_balance.dart';

/// Widget de répartition par catégorie
class CategoryBreakdownWidget extends StatelessWidget {
  final FinancialBalance balance;

  const CategoryBreakdownWidget({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Répartition des revenus
        if (balance.revenueByCategory.isNotEmpty)
          _buildCategorySection(
            'Répartition des Revenus',
            balance.revenueByCategory,
            Icons.attach_money,
            Colors.green.shade600,
          ),

        if (balance.revenueByCategory.isNotEmpty && balance.expensesByCategory.isNotEmpty) const SizedBox(height: 16),

        // Répartition des dépenses
        if (balance.expensesByCategory.isNotEmpty)
          _buildCategorySection(
            'Répartition des Dépenses',
            balance.expensesByCategory,
            Icons.money_off,
            Colors.red.shade600,
          ),
      ],
    );
  }

  /// Construit une section de catégories
  Widget _buildCategorySection(
    String title,
    List<CategoryBalance> categories,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Liste des catégories
            ...categories.map((category) => _buildCategoryItem(category)),
          ],
        ),
      ),
    );
  }

  /// Construit un élément de catégorie
  Widget _buildCategoryItem(CategoryBalance category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icône de catégorie
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _parseColor(category.categoryColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _parseIcon(category.categoryIcon),
              color: _parseColor(category.categoryColor),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Informations de catégorie
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryDisplayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${category.count} transactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Montant et pourcentage
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                category.amountFormatted,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _parseColor(category.categoryColor),
                ),
              ),
              Text(
                category.percentageFormatted,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Parse une couleur depuis une chaîne hexadécimale
  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// Parse une icône depuis une chaîne
  IconData _parseIcon(String iconString) {
    switch (iconString) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'people':
        return Icons.people;
      case 'build':
        return Icons.build;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }
}
