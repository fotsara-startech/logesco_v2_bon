import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/movement_report_service.dart';

/// Widget pour les graphiques financiers
class FinancialChartsWidget extends StatelessWidget {
  final List<CategorySummary> categorySummaries;
  final List<DailySummary> dailySummaries;

  const FinancialChartsWidget({
    super.key,
    required this.categorySummaries,
    required this.dailySummaries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (categorySummaries.isNotEmpty) ...[
          _buildCategoryChart(),
          const SizedBox(height: 16),
        ],
        if (dailySummaries.isNotEmpty) ...[
          _buildDailyTrendChart(),
        ],
      ],
    );
  }

  /// Construit le graphique par catégorie (camembert)
  Widget _buildCategoryChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'financial_movements_category_distribution'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  // Graphique
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        centerSpaceRadius: 50,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                  ),

                  // Légende
                  Expanded(
                    flex: 1,
                    child: _buildChartLegend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit les sections du graphique en camembert
  List<PieChartSectionData> _buildPieChartSections() {
    return categorySummaries.map((category) {
      final color = _parseColor(category.categoryColor);
      return PieChartSectionData(
        value: category.amount,
        title: category.percentage > 5 ? '${category.percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: category.percentage > 10
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _parseIcon(category.categoryIcon),
                  size: 16,
                  color: color,
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  /// Construit la légende du graphique
  Widget _buildChartLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categorySummaries.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _parseColor(category.categoryColor),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.categoryDisplayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${category.amountFormatted} (${category.percentageFormatted})',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Construit le graphique des tendances quotidiennes
  Widget _buildDailyTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'financial_movements_daily_evolution'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _calculateHorizontalInterval(),
                    verticalInterval: _calculateVerticalInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatAmount(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _calculateBottomTitleInterval(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dailySummaries.length) {
                            final date = dailySummaries[index].date;
                            return Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildLineChartSpots(),
                      isCurved: true,
                      color: Colors.blue.shade600,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue.shade600,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.shade100.withOpacity(0.3),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: (dailySummaries.length - 1).toDouble(),
                  minY: 0,
                  maxY: _getMaxAmount() * 1.1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTrendSummary(),
          ],
        ),
      ),
    );
  }

  /// Construit les points du graphique linéaire
  List<FlSpot> _buildLineChartSpots() {
    return dailySummaries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.amount);
    }).toList();
  }

  /// Construit le résumé des tendances
  Widget _buildTrendSummary() {
    if (dailySummaries.length < 2) return const SizedBox.shrink();

    final totalAmount = dailySummaries.fold(0.0, (sum, day) => sum + day.amount);
    final averageAmount = totalAmount / dailySummaries.length;
    final maxAmount = dailySummaries.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final minAmount = dailySummaries.map((d) => d.amount).reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrendStat('financial_movements_trend_average'.tr, '${averageAmount.toStringAsFixed(0)} FCFA', Icons.trending_flat),
          _buildTrendStat('financial_movements_trend_maximum'.tr, '${maxAmount.toStringAsFixed(0)} FCFA', Icons.trending_up),
          _buildTrendStat('financial_movements_trend_minimum'.tr, '${minAmount.toStringAsFixed(0)} FCFA', Icons.trending_down),
        ],
      ),
    );
  }

  /// Construit une statistique de tendance
  Widget _buildTrendStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Calcule l'intervalle horizontal pour la grille
  double _calculateHorizontalInterval() {
    if (dailySummaries.isEmpty) return 1000;
    final maxAmount = _getMaxAmount();
    return maxAmount / 5;
  }

  /// Calcule l'intervalle vertical pour la grille
  double _calculateVerticalInterval() {
    if (dailySummaries.isEmpty) return 1;
    return (dailySummaries.length / 7).ceil().toDouble();
  }

  /// Calcule l'intervalle pour les titres du bas
  double _calculateBottomTitleInterval() {
    if (dailySummaries.length <= 7) return 1;
    if (dailySummaries.length <= 14) return 2;
    if (dailySummaries.length <= 31) return 3;
    return 7;
  }

  /// Obtient le montant maximum
  double _getMaxAmount() {
    if (dailySummaries.isEmpty) return 1000;
    return dailySummaries.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
  }

  /// Formate un montant pour l'affichage
  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      return value.toStringAsFixed(0);
    }
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
      default:
        return Icons.category;
    }
  }
}
