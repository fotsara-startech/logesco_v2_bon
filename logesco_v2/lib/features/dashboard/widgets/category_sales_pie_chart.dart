import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

/// Widget camembert pour la répartition des ventes par catégories
class CategorySalesPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> categoryData;
  final bool isLoading;

  const CategorySalesPieChart({
    super.key,
    required this.categoryData,
    this.isLoading = false,
  });

  @override
  State<CategorySalesPieChart> createState() => _CategorySalesPieChartState();
}

class _CategorySalesPieChartState extends State<CategorySalesPieChart> {
  String _mode = 'revenue'; // 'revenue' ou 'quantity'

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dashboard_category_distribution'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              // Sélecteur de mode
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _mode,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF1565C0)),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'revenue',
                        child: Text('dashboard_by_revenue'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'quantity',
                        child: Text('dashboard_by_quantity'.tr),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _mode = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.isLoading) _buildLoadingState() else if (widget.categoryData.isEmpty) _buildEmptyState() else _buildPieChart(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'dashboard_no_category_data'.tr,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'dashboard_no_category_data_hint'.tr,
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

  Widget _buildPieChart() {
    // Calculer le total
    final total = _mode == 'revenue'
        ? widget.categoryData.fold<double>(0, (sum, item) => sum + ((item['revenue'] ?? 0.0) as num).toDouble())
        : widget.categoryData.fold<double>(0, (sum, item) => sum + ((item['quantity'] ?? 0) as num).toDouble());

    if (total == 0) return _buildEmptyState();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Camembert
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 280,
            child: PieChart(
              PieChartData(
                sections: _buildSections(total),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                startDegreeOffset: -90,
                borderData: FlBorderData(show: false),
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Gérer l'interaction si nécessaire
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Légende
        Expanded(
          flex: 2,
          child: _buildLegend(total),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    final colors = _generateColors(widget.categoryData.length);

    return widget.categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      final value = _mode == 'revenue' ? ((item['revenue'] ?? 0.0) as num).toDouble() : ((item['quantity'] ?? 0) as num).toDouble();

      final percentage = (value / total * 100);
      final color = colors[index % colors.length];

      return PieChartSectionData(
        value: value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: null,
      );
    }).toList();
  }

  Widget _buildLegend(double total) {
    final colors = _generateColors(widget.categoryData.length);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.categoryData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final categoryName = item['categoryName'] ?? 'dashboard_category_unknown'.tr;

          final value = _mode == 'revenue' ? ((item['revenue'] ?? 0.0) as num).toDouble() : ((item['quantity'] ?? 0) as num).toDouble();

          final percentage = (value / total * 100);
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _mode == 'revenue' ? '${value.toStringAsFixed(0)} FCFA (${percentage.toStringAsFixed(1)}%)' : '${value.toStringAsFixed(0)} unités (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Color> _generateColors(int count) {
    return [
      const Color(0xFF4CAF50), // Vert
      const Color(0xFF2196F3), // Bleu
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Violet
      const Color(0xFFF44336), // Rouge
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Jaune
      const Color(0xFF795548), // Marron
      const Color(0xFF607D8B), // Bleu gris
      const Color(0xFFE91E63), // Rose
    ];
  }
}
