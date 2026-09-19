import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../controllers/commercial_report_controller.dart';
import '../../financial_movements/widgets/period_selector_widget.dart';
import '../../../core/widgets/permission_widget.dart';

/// Palette cyclique — les groupes (commercial/zone/ville) n'ont pas de
/// couleur propre en base, contrairement aux catégories de dépenses.
const List<Color> _kPieColors = [
  Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFF4CAF50), Color(0xFF9C27B0),
  Color(0xFFF44336), Color(0xFF00BCD4), Color(0xFF795548), Color(0xFFFFC107),
  Color(0xFF3F51B5), Color(0xFF8BC34A),
];

/// Rapport « ventes par commercial / zone / ville ».
///
/// Fonctionnalité optionnelle : l'entrée de menu qui mène ici ne s'affiche
/// que si des commerciaux existent (voir modern_dashboard_page.dart).
class CommercialReportView extends StatelessWidget {
  const CommercialReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommercialReportController());

    return PermissionWidget(
      module: 'reports',
      privilege: 'READ',
      showFallback: true,
      fallback: Scaffold(
        appBar: AppBar(title: const Text('Ventes par commercial')),
        body: const Center(child: Text('Accès refusé')),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ventes par commercial'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: controller.loadReport),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value && !controller.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.loadReport,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PeriodSelectorWidget(
                    startDate: controller.startDate.value,
                    endDate: controller.endDate.value,
                    onStartDateChanged: (date) {
                      controller.startDate.value = date;
                      controller.loadReport();
                    },
                    onEndDateChanged: (date) {
                      controller.endDate.value = date;
                      controller.loadReport();
                    },
                    onPredefinedPeriodSelected: controller.setPredefinedPeriod,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCards(controller),
                  const SizedBox(height: 16),
                  _buildGroupBySelector(controller),
                  const SizedBox(height: 16),
                  if (!controller.hasData) _buildEmptyState() else _buildPieChart(controller),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCards(CommercialReportController controller) {
    final summary = controller.summary.value;
    final fmt = (double v) => '${v.toStringAsFixed(0)} FCFA';

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Ventes attribuées',
            fmt(summary?.totalAmount ?? 0),
            Icons.point_of_sale,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Nombre de ventes',
            '${summary?.totalCount ?? 0}',
            Icons.receipt_long,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'Commerciaux actifs',
            '${summary?.commerciauxActifsCount ?? 0}',
            Icons.badge_outlined,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupBySelector(CommercialReportController controller) {
    return Obx(() => SegmentedButton<CommercialReportGroupBy>(
          segments: const [
            ButtonSegment(value: CommercialReportGroupBy.commercial, label: Text('Par commercial'), icon: Icon(Icons.badge_outlined, size: 16)),
            ButtonSegment(value: CommercialReportGroupBy.zone, label: Text('Par zone'), icon: Icon(Icons.map_outlined, size: 16)),
            ButtonSegment(value: CommercialReportGroupBy.ville, label: Text('Par ville'), icon: Icon(Icons.location_city, size: 16)),
          ],
          selected: {controller.groupBy.value},
          onSelectionChanged: (selection) => controller.setGroupBy(selection.first),
        ));
  }

  Widget _buildPieChart(CommercialReportController controller) {
    return Obx(() {
      final groups = controller.groupedRows;
      final total = groups.fold<double>(0, (s, g) => s + g.montant);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Répartition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(groups, total),
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: _buildPieChartLegend(groups, total),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<PieChartSectionData> _buildPieChartSections(List<CommercialReportGroup> groups, double total) {
    return groups.asMap().entries.map((entry) {
      final index = entry.key;
      final g = entry.value;
      final percentage = total > 0 ? (g.montant / total * 100) : 0.0;
      final color = _kPieColors[index % _kPieColors.length];

      return PieChartSectionData(
        value: g.montant,
        title: percentage > 8 ? '${percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: 75,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildPieChartLegend(List<CommercialReportGroup> groups, double total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.asMap().entries.map((entry) {
        final index = entry.key;
        final g = entry.value;
        final percentage = total > 0 ? (g.montant / total * 100) : 0.0;
        final color = _kPieColors[index % _kPieColors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${g.montant.toStringAsFixed(0)} FCFA · ${percentage.toStringAsFixed(1)}% · ${g.count} vente(s)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucune vente attribuée à un commercial sur cette période', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
