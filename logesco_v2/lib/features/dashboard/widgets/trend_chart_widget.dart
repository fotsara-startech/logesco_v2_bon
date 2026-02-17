import 'package:flutter/material.dart';

/// Widget de graphique de tendance simple
class TrendChartWidget extends StatelessWidget {
  final String title;
  final List<double> data;
  final List<String> labels;
  final Color color;
  final String? subtitle;

  const TrendChartWidget({
    super.key,
    required this.title,
    required this.data,
    required this.labels,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _TrendChartPainter(
                  data: data,
                  color: color,
                ),
                child: Container(),
              ),
            ),
            const SizedBox(height: 8),
            if (labels.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: labels
                    .map((label) => Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _TrendChartPainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) return;

    // Créer les points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      points.add(Offset(x, y));
    }

    // Dessiner la ligne
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      // Compléter le remplissage
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      // Dessiner le remplissage puis la ligne
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);

      // Dessiner les points
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (final point in points) {
        canvas.drawCircle(point, 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
