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

  final Map<String, String> _periods = {
    '7days': '7 derniers jours',
    '30days': '30 derniers jours',
    '90days': '90 derniers jours',
    'thisMonth': 'Ce mois',
    'lastMonth': 'Mois dernier',
    'thisYear': 'Cette année',
    'all': 'Toutes les données',
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
        title: const Text('Analyse des Ventes par Produit'),
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
          const Text(
            'Période: ',
            style: TextStyle(
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
      return const LoadingWidget(message: 'Chargement des analytics...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: _error!,
        onRetry: _loadAnalytics,
      );
    }

    if (_analytics == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
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
            const Text(
              'Statistiques Globales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Produits Vendus',
                    '${stats.nombreProduitsVendus}',
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Chiffre d\'Affaires',
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
                    'Quantité Totale',
                    '${stats.quantiteTotaleVendue}',
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Transactions',
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
                    'Top Produits par Chiffre d\'Affaires (${_analytics!.produits.length} produits)',
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
                const Text(
                  'Produits à Faible Performance',
                  style: TextStyle(
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
                  const Expanded(
                    child: Text(
                      'Ces produits nécessitent une attention particulière pour améliorer leurs performances.',
                      style: TextStyle(
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
          Text('Réf: ${product.produit.reference}'),
          if (product.produit.categorie != null) Text('Catégorie: ${product.produit.categorie!.nom}'),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildMetric('CA', '${product.statistiques.chiffreAffaires.toStringAsFixed(0)} FCFA'),
              const SizedBox(width: 16),
              _buildMetric('Qté', '${product.statistiques.quantiteVendue}'),
              const SizedBox(width: 16),
              _buildMetric('Trans.', '${product.statistiques.nombreTransactions}'),
            ],
          ),
          if (product.statistiques.pourcentageMarge > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Marge: ${product.statistiques.pourcentageMarge.toStringAsFixed(1)}%',
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
        title: Text('Recommandations - ${product.produit.nom}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.recommandation ?? 'Aucune recommandation disponible'),
              const SizedBox(height: 16),
              const Text(
                'Actions suggérées:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Analyser la demande du marché'),
              const Text('• Revoir la stratégie de prix'),
              const Text('• Améliorer la visibilité du produit'),
              const Text('• Considérer des promotions ciblées'),
              const Text('• Évaluer la qualité du produit'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
