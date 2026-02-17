import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/movement_report_service.dart';

/// Widget d'analyse avancée des catégories avec graphiques multiples
class CategoryAnalysisWidget extends StatefulWidget {
  final List<CategorySummary> categorySummaries;
  final double totalAmount;

  const CategoryAnalysisWidget({
    super.key,
    required this.categorySummaries,
    required this.totalAmount,
  });

  @override
  State<CategoryAnalysisWidget> createState() => _CategoryAnalysisWidgetState();
}

class _CategoryAnalysisWidgetState extends State<CategoryAnalysisWidget> {
  int _selectedChartType = 0; // 0: Pie, 1: Bar, 2: Horizontal Bar

  @override
  Widget build(BuildContext context) {
    if (widget.categorySummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildChartTypeSelector(),
            const SizedBox(height: 16),
            _buildSelectedChart(),
            const SizedBox(height: 16),
            _buildCategoryRanking(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.analytics, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        const Text(
          'Analyse par catégorie',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            '${widget.categorySummaries.length} catégories',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeSelector() {
    return Row(
      children: [
        const Text(
          'Type de graphique:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChartTypeButton(0, Icons.pie_chart, 'Camembert'),
                const SizedBox(width: 8),
                _buildChartTypeButton(1, Icons.bar_chart, 'Barres'),
                const SizedBox(width: 8),
                _buildChartTypeButton(2, Icons.align_horizontal_left, 'Barres H.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeButton(int index, IconData icon, String label) {
    final isSelected = _selectedChartType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChartType = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (_selectedChartType) {
      case 0:
        return _buildPieChart();
      case 1:
        return _buildBarChart();
      case 2:
        return _buildHorizontalBarChart();
      default:
        return _buildPieChart();
    }
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                centerSpaceRadius: 60,
                sectionsSpace: 3,
                startDegreeOffset: -90,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildPieChartLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxAmount() * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final category = widget.categorySummaries[group.x.toInt()];
                return BarTooltipItem(
                  '${category.categoryDisplayName}\n${category.amountFormatted}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < widget.categorySummaries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Icon(
                        _parseIcon(widget.categorySummaries[index].categoryIcon),
                        size: 16,
                        color: _parseColor(widget.categorySummaries[index].categoryColor),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildBarGroups(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxAmount() / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBarChart() {
    return SizedBox(
      height: widget.categorySummaries.length * 60.0 + 50,
      child: ListView.builder(
        itemCount: widget.categorySummaries.length,
        itemBuilder: (context, index) {
          final category = widget.categorySummaries[index];
          final percentage = (category.amount / widget.totalAmount) * 100;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _parseColor(category.categoryColor).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _parseIcon(category.categoryIcon),
                          size: 14,
                          color: _parseColor(category.categoryColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.categoryDisplayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _parseColor(category.categoryColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.amountFormatted,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryRanking() {
    final sortedCategories = List<CategorySummary>.from(widget.categorySummaries)..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.leaderboard, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text(
              'Classement des dépenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedCategories.take(5).map((category) {
          final rank = sortedCategories.indexOf(category) + 1;
          return _buildRankingItem(category, rank);
        }).toList(),
      ],
    );
  }

  Widget _buildRankingItem(CategorySummary category, int rank) {
    Color rankColor;
    IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = Colors.amber;
        rankIcon = Icons.looks_one;
        break;
      case 2:
        rankColor = Colors.grey;
        rankIcon = Icons.looks_two;
        break;
      case 3:
        rankColor = Colors.brown;
        rankIcon = Icons.looks_3;
        break;
      default:
        rankColor = Colors.blue;
        rankIcon = Icons.fiber_manual_record;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: rankColor.withOpacity(0.3)),
            ),
            child: Icon(
              rankIcon,
              size: 16,
              color: rankColor,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _parseColor(category.categoryColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _parseIcon(category.categoryIcon),
              size: 16,
              color: _parseColor(category.categoryColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${category.count} mouvements',
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
                category.amountFormatted,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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

  List<PieChartSectionData> _buildPieChartSections() {
    return widget.categorySummaries.map((category) {
      final color = _parseColor(category.categoryColor);
      return PieChartSectionData(
        value: category.amount,
        title: category.percentage > 8 ? '${category.percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: category.percentage > 15
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
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildPieChartLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.categorySummaries.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
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
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.categoryDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      category.percentageFormatted,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
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

  List<BarChartGroupData> _buildBarGroups() {
    return widget.categorySummaries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final color = _parseColor(category.categoryColor);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: category.amount,
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxAmount() {
    if (widget.categorySummaries.isEmpty) return 1000;
    return widget.categorySummaries.map((c) => c.amount).reduce((a, b) => a > b ? a : b);
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

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
