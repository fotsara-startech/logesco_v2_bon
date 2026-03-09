import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/discount_report_controller.dart';
import '../models/discount_report.dart';
import '../../../shared/constants/constants.dart';
import '../../../shared/widgets/empty_states.dart';

class DiscountReportView extends StatelessWidget {
  const DiscountReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DiscountReportController());

    return Scaffold(
      appBar: AppBar(
        title: Text('reports_discount_title'.tr),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.refreshAllData,
            icon: const Icon(Icons.refresh),
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshAllData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtres
              _buildFiltersSection(controller),
              const SizedBox(height: 24),

              // Statistiques générales
              _buildStatsCards(controller),
              const SizedBox(height: 24),

              // Graphiques
              _buildChartsSection(controller),
              const SizedBox(height: 24),

              // Top des remises
              _buildTopDiscountsSection(controller),
              const SizedBox(height: 24),

              // Rapport par vendeur
              _buildVendorReportSection(controller),
            ],
          ),
        ),
      ),
    );
  }

  /// Section des filtres
  Widget _buildFiltersSection(DiscountReportController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'reports_discount_filters'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: controller.clearDateFilters,
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text('reports_discount_clear'.tr),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Groupement
            Row(
              children: [
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: controller.selectedGroupBy.value,
                        decoration: InputDecoration(
                          labelText: 'reports_discount_group_by'.tr,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: 'vendeur', child: Text('reports_discount_group_vendor'.tr)),
                          DropdownMenuItem(value: 'produit', child: Text('reports_discount_group_product'.tr)),
                          DropdownMenuItem(value: 'jour', child: Text('reports_discount_group_day'.tr)),
                          DropdownMenuItem(value: 'mois', child: Text('reports_discount_group_month'.tr)),
                        ],
                        onChanged: (value) {
                          if (value != null) controller.updateGroupBy(value);
                        },
                      )),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filtres de date
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.dateDebutController,
                    decoration: InputDecoration(
                      labelText: 'reports_discount_date_start'.tr,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(controller, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: controller.dateFinController,
                    decoration: InputDecoration(
                      labelText: 'reports_discount_date_end'.tr,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(controller, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Cartes de statistiques
  Widget _buildStatsCards(DiscountReportController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final stats = controller.summaryStats;
      if (stats.isEmpty) {
        return const SizedBox.shrink();
      }

      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'reports_discount_total'.tr,
              '${stats['totalRemises']?.toStringAsFixed(0) ?? '0'} ${CurrencyConstants.defaultCurrency}',
              Icons.discount,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'reports_discount_count'.tr,
              '${stats['nombreRemises'] ?? 0}',
              Icons.receipt_long,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'reports_discount_average'.tr,
              '${stats['remiseMoyenne']?.toStringAsFixed(0) ?? '0'} ${CurrencyConstants.defaultCurrency}',
              Icons.trending_up,
              Colors.orange,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section des graphiques
  Widget _buildChartsSection(DiscountReportController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (!controller.hasData) {
        return Card(
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            child: EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'reports_discount_no_data'.tr,
              subtitle: 'reports_discount_no_data_subtitle'.tr,
            ),
          ),
        );
      }

      return Row(
        children: [
          // Graphique en secteurs
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'reports_discount_distribution'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildPieChart(controller),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Graphique en barres
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'reports_discount_by_group'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildBarChart(controller),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Graphique en secteurs
  Widget _buildPieChart(DiscountReportController controller) {
    final data = controller.pieChartData;
    if (data.isEmpty) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final colors = [
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.purple,
            Colors.red,
            Colors.teal,
          ];

          return PieChartSectionData(
            value: item['value'],
            title: '${item['percentage'].toStringAsFixed(1)}%',
            color: colors[index % colors.length],
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  /// Graphique en barres
  Widget _buildBarChart(DiscountReportController controller) {
    final data = controller.barChartData;
    if (data.isEmpty) return const SizedBox.shrink();

    return BarChart(
      BarChartData(
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item['totalRemises'],
                color: Colors.blue,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index]['label'],
                      style: const TextStyle(fontSize: 10),
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
        gridData: const FlGridData(show: true),
      ),
    );
  }

  /// Section du top des remises
  Widget _buildTopDiscountsSection(DiscountReportController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'reports_discount_top_title'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.isLoadingTopDiscounts.value) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.topDiscounts.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'reports_discount_no_discounts'.tr,
                    subtitle: 'reports_discount_no_discounts_subtitle'.tr,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.topDiscounts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final discount = controller.topDiscounts[index];
                  return _buildTopDiscountItem(discount, index + 1);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDiscountItem(TopDiscount discount, int rank) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRankColor(rank),
        child: Text(
          '$rank',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(discount.produit.nom),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('reports_discount_reference'.trParams({'reference': discount.produit.reference})),
          if (discount.justification != null)
            Text(
              'reports_discount_justification'.trParams({'text': discount.justification!}),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${discount.remiseAppliquee.toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'reports_discount_percent_used'.trParams({'percent': discount.pourcentageUtilise.toStringAsFixed(1)}),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  /// Section du rapport par vendeur
  Widget _buildVendorReportSection(DiscountReportController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'reports_discount_by_vendor'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.isLoadingVendors.value) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final report = controller.vendorReport.value;
              if (report == null || report.statistiques.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: EmptyState(
                    icon: Icons.people_outline,
                    title: 'reports_discount_vendor_no_data'.tr,
                    subtitle: 'reports_discount_vendor_no_data_subtitle'.tr,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: report.statistiques.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final stats = report.statistiques[index];
                  return _buildVendorStatsItem(stats);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorStatsItem(VendorDiscountStats stats) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          stats.vendeur.nomUtilisateur.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(stats.vendeur.nomUtilisateur),
      subtitle:
          Text('reports_discount_vendor_sales'.trParams({'count': stats.nombreVentes.toString()}) + ' • ' + 'reports_discount_vendor_products'.trParams({'count': stats.nombreProduits.toString()})),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${stats.totalRemises.toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'reports_discount_vendor_average'.trParams({'amount': '${stats.remiseMoyenne.toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}'}),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Sélecteur de date
  Future<void> _selectDate(DiscountReportController controller, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      if (isStartDate) {
        controller.updateDateDebut(picked);
      } else {
        controller.updateDateFin(picked);
      }
    }
  }
}
