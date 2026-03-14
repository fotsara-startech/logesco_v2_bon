import 'package:flutter/material.dart';
import 'package:logesco_v2/shared/themes/app_theme.dart';
import 'package:get/get.dart';
import '../services/analytics_service.dart';
import '../models/product_analytics.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
// import '../../../core/theme/app_theme.dart';

class ProductAnalyticsPage extends StatefulWidget {
  const ProductAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<ProductAnalyticsPage> createState() => _ProductAnalyticsPageState();
}

class _ProductAnalyticsPageState extends State<ProductAnalyticsPage> {
  final AnalyticsService _analyticsService = Get.find<AnalyticsService>();

  ProductAnalyticsResponse? _analytics;
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'all';

  Map<String, String> get _periods => {
        '7days': 'analytics_7_days'.tr,
        '30days': 'analytics_30_days'.tr,
        '90days': 'analytics_90_days'.tr,
        'thisMonth': 'analytics_this_month'.tr,
        'lastMonth': 'analytics_last_month'.tr,
        'thisYear': 'analytics_this_year'.tr,
        'all': 'analytics_all_data'.tr,
      };

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics = await _analyticsService.getProductAnalyticsForPeriod(_selectedPeriod);
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('analytics_title'.tr),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'analytics_period'.tr + ': ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _periods.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                  _loadAnalytics();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return LoadingWidget(message: 'analytics_loading'.tr);
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: _error!,
        onRetry: _loadAnalytics,
      );
    }

    if (_analytics == null) {
      return Center(
        child: Text('analytics_no_data'.tr),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGlobalStats(),
          const SizedBox(height: 24),
          _buildTopProducts(),
          const SizedBox(height: 24),
          _buildLowPerformanceProducts(),
        ],
      ),
    );
  }

  Widget _buildGlobalStats() {
    final stats = _analytics!.statistiquesGlobales;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'analytics_global_stats'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'analytics_products_sold'.tr,
                    '${stats.nombreProduitsVendus}',
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'analytics_revenue'.tr,
                    '${stats.chiffreAffairesTotal.toStringAsFixed(0)} FCFA',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'analytics_total_quantity'.tr,
                    '${stats.quantiteTotaleVendue}',
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'analytics_transactions'.tr,
                    '${stats.nombreTransactionsTotal}',
                    Icons.receipt,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'analytics_top_products_title'.tr.replaceAll('@count', '${_analytics!.produits.length}'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analytics!.produits.take(20).length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = _analytics!.produits[index];
                return _buildProductTile(product, index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowPerformanceProducts() {
    if (_analytics!.produitsAFaiblePerformance.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_down, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'analytics_low_performance_title'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'analytics_low_performance_warning'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analytics!.produitsAFaiblePerformance.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = _analytics!.produitsAFaiblePerformance[index];
                return _buildProductTile(product, null, isLowPerformance: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(ProductAnalytics product, int? rank, {bool isLowPerformance = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: rank != null
          ? CircleAvatar(
              backgroundColor: _getRankColor(rank),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(
              Icons.warning,
              color: Colors.orange,
            ),
      title: Text(
        product.produit.nom,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${'analytics_ref'.tr}: ${product.produit.reference}'),
          if (product.produit.categorie != null) Text('${'analytics_category'.tr}: ${product.produit.categorie!.nom}'),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildMetric('analytics_ca'.tr, '${product.statistiques.chiffreAffaires.toStringAsFixed(0)} FCFA'),
              const SizedBox(width: 16),
              _buildMetric('analytics_qty'.tr, '${product.statistiques.quantiteVendue}'),
              const SizedBox(width: 16),
              _buildMetric('analytics_trans'.tr, '${product.statistiques.nombreTransactions}'),
            ],
          ),
          if (product.statistiques.pourcentageMarge > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${'analytics_margin'.tr}: ${product.statistiques.pourcentageMarge.toStringAsFixed(1)}%',
              style: TextStyle(
                color: product.statistiques.pourcentageMarge > 20 ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      trailing: isLowPerformance
          ? IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () => _showRecommendations(product),
            )
          : null,
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return Colors.green;
    if (rank <= 5) return Colors.blue;
    if (rank <= 10) return Colors.orange;
    return Colors.grey;
  }

  void _showRecommendations(ProductAnalytics product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'analytics_recommendations_title'.tr} - ${product.produit.nom}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.recommandation ?? 'analytics_no_recommendation'.tr),
              const SizedBox(height: 16),
              Text(
                'analytics_suggested_actions'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'analytics_action_market'.tr}'),
              Text('• ${'analytics_action_pricing'.tr}'),
              Text('• ${'analytics_action_visibility'.tr}'),
              Text('• ${'analytics_action_promotions'.tr}'),
              Text('• ${'analytics_action_quality'.tr}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('sales_close'.tr),
          ),
        ],
      ),
    );
  }
}
