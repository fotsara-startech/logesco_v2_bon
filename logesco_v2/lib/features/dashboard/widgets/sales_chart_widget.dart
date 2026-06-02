import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget pour afficher le graphique des ventes en courbes
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
          Text(
            'dashboard_sales_evolution'.tr,
            style: const TextStyle(
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
              'dashboard_no_sales_data'.tr,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'dashboard_no_sales_data_hint'.tr,
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

    const chartHeight = 280.0;
    const chartWidth = 350.0;

    return Column(
      children: [
        // Légende
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('dashboard_sales_legend'.tr, const Color(0xFF4CAF50)),
            const SizedBox(width: 24),
            _buildLegendItem('dashboard_revenue_legend'.tr, const Color(0xFF2196F3)),
          ],
        ),
        const SizedBox(height: 20),

        // Graphique en courbes
        SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: _buildLineChart(maxSales, maxRevenue, chartHeight, chartWidth),
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

  Widget _buildLineChart(int maxSales, double maxRevenue, double chartHeight, double chartWidth) {
    if (chartData.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: LineChartPainter(
        chartData: chartData,
        maxSales: maxSales,
        maxRevenue: maxRevenue,
        chartHeight: chartHeight,
        chartWidth: chartWidth,
      ),
      child: Container(),
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

  Widget _buildDayLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final dayKeys = [
        'dashboard_day_sun',
        'dashboard_day_mon',
        'dashboard_day_tue',
        'dashboard_day_wed',
        'dashboard_day_thu',
        'dashboard_day_fri',
        'dashboard_day_sat',
      ];
      return Text(
        dayKeys[date.weekday % 7].tr,
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

/// Painter personnalisé pour dessiner un graphique en courbes
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> chartData;
  final int maxSales;
  final double maxRevenue;
  final double chartHeight;
  final double chartWidth;

  LineChartPainter({
    required this.chartData,
    required this.maxSales,
    required this.maxRevenue,
    required this.chartHeight,
    required this.chartWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chartData.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final padding = 30.0;

    // Dessiner les axes
    _drawAxes(canvas, width, height, padding);

    // Calculer les points
    final salesPoints = _calculatePoints(chartData, maxSales, true, width, height, padding);
    final revenuePoints = _calculatePoints(chartData, maxRevenue, false, width, height, padding);

    // Dessiner les courbes
    _drawCurve(canvas, salesPoints, const Color(0xFF4CAF50), width, height, padding);
    _drawCurve(canvas, revenuePoints, const Color(0xFF2196F3), width, height, padding);

    // Dessiner les points
    _drawPoints(canvas, salesPoints, const Color(0xFF4CAF50));
    _drawPoints(canvas, revenuePoints, const Color(0xFF2196F3));
  }

  void _drawAxes(Canvas canvas, double width, double height, double padding) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    // Axe Y (vertical)
    canvas.drawLine(
      Offset(padding, height - padding),
      Offset(padding, padding / 2),
      paint,
    );

    // Axe X (horizontal)
    canvas.drawLine(
      Offset(padding, height - padding),
      Offset(width - padding / 2, height - padding),
      paint,
    );

    // Grille horizontale
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = height - padding - (height - padding * 1.5) / 4 * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(width - padding / 2, y),
        gridPaint,
      );
    }
  }

  List<Offset> _calculatePoints(
    List<Map<String, dynamic>> data,
    num maxValue,
    bool isSales,
    double width,
    double height,
    double padding,
  ) {
    if (data.isEmpty || maxValue == 0) return [];

    final chartWidth = width - padding - padding / 2;
    final chartHeight = height - padding * 1.5;
    final pointSpacing = chartWidth / (data.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final value = isSales ? ((data[i]['sales'] ?? 0) as int).toDouble() : ((data[i]['revenue'] ?? 0.0) as num).toDouble();

      final x = padding + (pointSpacing * i);
      final y = height - padding - (value / maxValue * chartHeight);

      points.add(Offset(x, y));
    }

    return points;
  }

  void _drawCurve(Canvas canvas, List<Offset> points, Color color, double width, double height, double padding) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // Dessiner des courbes lisses (interpolation Catmull-Rom)
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

      const t = 0.5; // Tension pour la courbe
      final cp1x = p1.dx + (p2.dx - p0.dx) / 6 * t;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6 * t;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6 * t;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6 * t;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawPoints(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(point, 4, paint);
      canvas.drawCircle(point, 4, strokePaint);
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.chartData != chartData || oldDelegate.maxSales != maxSales || oldDelegate.maxRevenue != maxRevenue;
  }
}
