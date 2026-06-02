import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget pour afficher les top produits du jour
class TopProductsCard extends StatelessWidget {
  final List<Map<String, dynamic>> topProducts;
  final bool isLoading;

  const TopProductsCard({
    super.key,
    required this.topProducts,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    // Prendre seulement les 5 premiers produits
    final products = topProducts.take(5).toList();

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Text(
            '⭐ ${'dashboard_top_products'.tr}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),

          // Liste des produits
          ...List.generate(products.length, (index) {
            final product = products[index];
            final rank = index + 1;
            final name = product['nom'] ?? 'Produit inconnu';
            final quantity = (product['quantite'] ?? product['count'] ?? 0) as int;
            final revenue = (product['revenue'] ?? 0.0) as double;

            // Couleur selon le rang
            final rankColors = [
              Colors.amber,
              Colors.grey.shade600,
              Colors.orange.shade700,
              Colors.blue,
              Colors.purple,
            ];
            final rankColor = rankColors[index % rankColors.length];

            return Padding(
              padding: EdgeInsets.only(bottom: index < products.length - 1 ? 12 : 0),
              child: Row(
                children: [
                  // Numéro du rang avec badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: rankColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: rankColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nom du produit et quantité
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$quantity ${'dashboard_units_sold'.tr}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Revenu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(revenue),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'FCFA',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'dashboard_no_top_products'.tr,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
          ),
        ),
      ),
    );
  }
}
