import 'package:flutter/material.dart';

/// Widget pour afficher le graphique des ventes
class SalesChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;
  final bool isLoading;

  const SalesChartWidget({
    super.key,
    required this.chartData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Évolution des ventes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 20),
          if (isLoading) _buildLoadingState() else if (chartData.isEmpty) _buildEmptyState() else _buildChart(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée de vente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les données apparaîtront une fois que vous aurez des ventes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Calculer les valeurs max pour la normalisation
    final maxSales = chartData.map((e) => (e['sales'] ?? 0) as int).reduce((a, b) => a > b ? a : b);
    final maxRevenue = chartData.map((e) => ((e['revenue'] ?? 0.0) as num).toDouble()).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Légende
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Ventes', const Color(0xFF4CAF50)),
            const SizedBox(width: 24),
            _buildLegendItem('Revenus', const Color(0xFF2196F3)),
          ],
        ),
        const SizedBox(height: 20),

        // Graphique simple avec des barres
        SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.map((data) => _buildBar(data, maxSales, maxRevenue)).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Labels des jours
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: chartData.map((data) => _buildDayLabel(data['date'] ?? '')).toList(),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBar(Map<String, dynamic> data, int maxSales, double maxRevenue) {
    final sales = (data['sales'] ?? 0) as int;
    final revenue = ((data['revenue'] ?? 0.0) as num).toDouble();

    // Normaliser les hauteurs (minimum 10% pour la visibilité)
    final salesHeight = maxSales > 0 ? (sales / maxSales * 150).clamp(sales > 0 ? 15.0 : 0.0, 150.0) : 0.0;
    final revenueHeight = maxRevenue > 0 ? (revenue / maxRevenue * 150).clamp(revenue > 0 ? 15.0 : 0.0, 150.0) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Tooltip avec les valeurs
        if (sales > 0 || revenue > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$sales',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        const SizedBox(height: 4),

        // Barres
        Row(
          children: [
            // Barre des ventes
            Container(
              width: 8,
              height: salesHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 2),

            // Barre des revenus
            Container(
              width: 8,
              height: revenueHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
      return Text(
        dayNames[date.weekday % 7],
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      );
    } catch (e) {
      return Text(
        'N/A',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      );
    }
  }
}
