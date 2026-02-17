import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/movement_report_controller.dart';
import '../widgets/period_selector_widget.dart';
import '../widgets/financial_charts_widget.dart';
import '../widgets/summary_statistics_widget.dart';
import '../widgets/category_analysis_widget.dart';
import '../widgets/period_comparison_widget.dart';
import '../widgets/report_actions_widget.dart';
import '../widgets/period_info_widget.dart';

/// Page des rapports et statistiques des mouvements financiers
class MovementReportsPage extends StatelessWidget {
  const MovementReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MovementReportController>(
      init: MovementReportController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rapports et Statistiques'),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.refreshAllReportData(),
                tooltip: 'Actualiser',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.file_download),
                tooltip: 'Exporter',
                onSelected: (value) async {
                  if (value == 'pdf') {
                    final filePath = await controller.exportToPdf();
                    if (filePath != null) {
                      Get.snackbar(
                        'Export réussi',
                        'Rapport PDF sauvegardé',
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.green.shade800,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  } else if (value == 'excel') {
                    final filePath = await controller.exportToExcel();
                    if (filePath != null) {
                      Get.snackbar(
                        'Export réussi',
                        'Rapport Excel sauvegardé',
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.green.shade800,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Exporter en PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Exporter en Excel'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value && !controller.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des rapports...'),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.refreshAllReportData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélecteur de période
                    PeriodSelectorWidget(
                      startDate: controller.startDate.value,
                      endDate: controller.endDate.value,
                      onStartDateChanged: (date) {
                        controller.startDate.value = date;
                        if (controller.endDate.value != null) {
                          controller.loadAllReportData();
                        }
                      },
                      onEndDateChanged: (date) {
                        controller.endDate.value = date;
                        if (controller.startDate.value != null) {
                          controller.loadAllReportData();
                        }
                      },
                      onPredefinedPeriodSelected: (period) {
                        controller.setPredefinedPeriod(period);
                        controller.loadAllReportData();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Actions rapides
                    ReportActionsWidget(
                      onExportPdf: () async {
                        final filePath = await controller.exportToPdf();
                        if (filePath != null) {
                          Get.snackbar(
                            'Export réussi',
                            'Rapport PDF sauvegardé',
                            backgroundColor: Colors.green.shade100,
                            colorText: Colors.green.shade800,
                          );
                        }
                      },
                      onExportExcel: () async {
                        final filePath = await controller.exportToExcel();
                        if (filePath != null) {
                          Get.snackbar(
                            'Export réussi',
                            'Rapport Excel sauvegardé',
                            backgroundColor: Colors.green.shade100,
                            colorText: Colors.green.shade800,
                          );
                        }
                      },
                      onRefresh: () => controller.refreshAllReportData(),
                      isLoading: controller.isLoading.value,
                    ),
                    const SizedBox(height: 16),

                    // Résumé général
                    if (controller.currentSummary.value != null)
                      SummaryStatisticsWidget(
                        summary: controller.currentSummary.value!,
                        periodDays: controller.periodDayCount,
                      ),
                    const SizedBox(height: 16),

                    // Informations sur la période
                    if (controller.hasPeriodSelected && controller.currentSummary.value != null)
                      PeriodInfoWidget(
                        startDate: controller.startDate.value!,
                        endDate: controller.endDate.value!,
                        totalMovements: controller.currentSummary.value!.totalCount,
                        totalAmount: controller.currentSummary.value!.totalAmount,
                      ),
                    const SizedBox(height: 16),

                    // Analyse avancée par catégorie
                    if (controller.categorySummaries.isNotEmpty && controller.currentSummary.value != null)
                      CategoryAnalysisWidget(
                        categorySummaries: controller.categorySummaries,
                        totalAmount: controller.currentSummary.value!.totalAmount,
                      ),
                    const SizedBox(height: 16),

                    // Graphiques
                    if (controller.categorySummaries.isNotEmpty || controller.dailySummaries.isNotEmpty)
                      FinancialChartsWidget(
                        categorySummaries: controller.categorySummaries,
                        dailySummaries: controller.dailySummaries,
                      ),
                    const SizedBox(height: 16),

                    // Comparaison entre périodes
                    PeriodComparisonWidget(),
                    const SizedBox(height: 16),

                    // Liste détaillée par catégorie
                    if (controller.categorySummaries.isNotEmpty) _buildCategoryList(controller),

                    // Message si aucune donnée
                    if (!controller.hasData && !controller.isLoading.value) _buildNoDataMessage(controller),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Construit la liste des catégories
  Widget _buildCategoryList(MovementReportController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Détail par catégorie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.categorySummaries.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final category = controller.categorySummaries[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(category.categoryColor).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _parseIcon(category.categoryIcon),
                      color: _parseColor(category.categoryColor),
                    ),
                  ),
                  title: Text(
                    category.categoryDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('${category.count} mouvements'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le message d'absence de données
  Widget _buildNoDataMessage(MovementReportController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.hasPeriodSelected ? 'Aucun mouvement financier trouvé pour la période sélectionnée' : 'Sélectionnez une période pour voir les rapports',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (controller.hasPeriodSelected) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadAllReportData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
              ),
            ],
          ],
        ),
      ),
    );
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
