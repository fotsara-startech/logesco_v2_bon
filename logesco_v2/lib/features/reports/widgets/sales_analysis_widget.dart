import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/activity_report.dart';

/// Widget pour afficher l'analyse des ventes
class SalesAnalysisWidget extends StatelessWidget {
  final SalesData salesData;

  const SalesAnalysisWidget({
    super.key,
    required this.salesData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Colors.green.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'reports_sales_title'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Résumé des ventes
            _buildSalesSummary(),

            const SizedBox(height: 20),

            // Ventes par catégorie
            if (salesData.salesByCategory.isNotEmpty) ...[
              _buildSectionTitle('reports_sales_by_category'.tr),
              const SizedBox(height: 12),
              _buildCategoriesTable(),
              const SizedBox(height: 20),
            ],

            // Produits les plus vendus
            if (salesData.topProducts.isNotEmpty) ...[
              _buildSectionTitle('reports_sales_top_products'.tr),
              const SizedBox(height: 12),
              _buildTopProductsList(),
            ],
          ],
        ),
      ),
    );
  }

  /// Résumé des ventes
  Widget _buildSalesSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'reports_sales_count'.tr,
              salesData.totalSales.toString(),
              Icons.receipt_long,
              Colors.blue.shade600,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.green.shade200,
          ),
          Expanded(
            child: _buildSummaryItem(
              'reports_sales_revenue'.tr,
              salesData.totalRevenueFormatted,
              Icons.attach_money,
              Colors.green.shade600,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.green.shade200,
          ),
          Expanded(
            child: _buildSummaryItem(
              'reports_sales_average'.tr,
              salesData.averageSaleAmountFormatted,
              Icons.trending_up,
              Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Item de résumé
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Titre de section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Tableau des catégories
  Widget _buildCategoriesTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'reports_sales_category_header'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'reports_sales_amount_header'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'reports_sales_percent_header'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Données
          ...salesData.salesByCategory.take(5).map((category) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(category.categoryName),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        category.amountFormatted,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        category.percentageFormatted,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Liste des produits les plus vendus
  Widget _buildTopProductsList() {
    return Column(
      children: salesData.topProducts
          .take(5)
          .map((product) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'reports_sales_quantity_sold'.trParams({'quantity': product.quantitySold.toString()}),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.revenueFormatted,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'reports_sales_revenue_generated'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
