import 'package:flutter/material.dart';
import '../models/financial_balance.dart';

/// Widget de graphique de l'évolution quotidienne
class DailyBalanceChartWidget extends StatelessWidget {
  final List<DailyBalance> dailyBalances;

  const DailyBalanceChartWidget({
    super.key,
    required this.dailyBalances,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyBalances.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Évolution Quotidienne',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Graphique linéaire simple
            _buildLineChart(),
            const SizedBox(height: 16),

            // Statistiques rapides
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  /// Construit un graphique linéaire simple
  Widget _buildLineChart() {
    final maxProfit = dailyBalances.map((d) => d.profit).reduce((a, b) => a > b ? a : b);
    final minProfit = dailyBalances.map((d) => d.profit).reduce((a, b) => a < b ? a : b);
    final range = maxProfit - minProfit;

    if (range == 0) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          'Bénéfice constant: ${dailyBalances.first.profitFormatted}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _LineChartPainter(dailyBalances, minProfit, range),
      ),
    );
  }

  /// Construit les statistiques rapides
  Widget _buildQuickStats() {
    final profitableDays = dailyBalances.where((d) => d.profit > 0).length;
    final totalDays = dailyBalances.length;
    final averageProfit = dailyBalances.fold<double>(0.0, (sum, d) => sum + d.profit) / totalDays;
    final bestDay = dailyBalances.reduce((a, b) => a.profit > b.profit ? a : b);
    final worstDay = dailyBalances.reduce((a, b) => a.profit < b.profit ? a : b);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Jours Rentables',
            '$profitableDays/$totalDays',
            Icons.calendar_today,
            Colors.green.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Moyenne/Jour',
            '${averageProfit.toStringAsFixed(0)} FCFA',
            Icons.trending_up,
            averageProfit > 0 ? Colors.blue.shade600 : Colors.red.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Meilleur Jour',
            bestDay.profitFormatted,
            Icons.star,
            Colors.amber.shade600,
          ),
        ),
      ],
    );
  }

  /// Construit une carte de statistique
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Painter pour le graphique linéaire
class _LineChartPainter extends CustomPainter {
  final List<DailyBalance> dailyBalances;
  final double minProfit;
  final double range;

  _LineChartPainter(this.dailyBalances, this.minProfit, this.range);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final profitablePaint = Paint()
      ..color = Colors.green.shade600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final lossPaint = Paint()
      ..color = Colors.red.shade600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final profitablePath = Path();
    final lossPath = Path();

    for (int i = 0; i < dailyBalances.length; i++) {
      final x = (i / (dailyBalances.length - 1)) * size.width;
      final normalizedProfit = (dailyBalances[i].profit - minProfit) / range;
      final y = size.height - (normalizedProfit * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        if (dailyBalances[i].profit > 0) {
          profitablePath.moveTo(x, y);
        } else {
          lossPath.moveTo(x, y);
        }
      } else {
        path.lineTo(x, y);
        if (dailyBalances[i].profit > 0) {
          profitablePath.lineTo(x, y);
        } else {
          lossPath.lineTo(x, y);
        }
      }

      // Dessiner un point
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()
          ..color = dailyBalances[i].profit > 0 ? Colors.green : Colors.red
          ..style = PaintingStyle.fill,
      );
    }

    // Ligne de zéro
    final zeroY = size.height - ((-minProfit) / range * size.height);
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
