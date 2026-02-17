import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/activity_report_controller.dart';
import '../widgets/period_selector_widget.dart';
import '../widgets/report_summary_widget.dart';
import '../widgets/sales_analysis_widget.dart';
import '../widgets/financial_movements_widget.dart';
import '../widgets/customer_debts_widget.dart';
import '../widgets/profit_analysis_widget.dart';
import '../widgets/recommendations_widget.dart';

/// Page principale du bilan comptable d'activités
class ActivityReportPage extends StatelessWidget {
  const ActivityReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ActivityReportController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilan Comptable d\'Activités'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => controller.currentReport != null
              ? PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, controller),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Actualiser'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export_pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf),
                          SizedBox(width: 8),
                          Text('Exporter PDF'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.clear),
                          SizedBox(width: 8),
                          Text('Nouveau bilan'),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de période
          Container(
            color: Colors.blue.shade700,
            child: const PeriodSelectorWidget(),
          ),
          
          // Contenu principal
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Génération du bilan en cours...'),
                    ],
                  ),
                );
              }

              if (controller.currentReport == null) {
                return _buildEmptyState(controller);
              }

              return _buildReportContent(controller);
            }),
          ),
        ],
      ),
      floatingActionButton: Obx(() => controller.currentReport != null
          ? FloatingActionButton.extended(
              onPressed: controller.isGeneratingPdf ? null : controller.exportToPdf,
              icon: controller.isGeneratingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(controller.isGeneratingPdf ? 'Export...' : 'Export PDF'),
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            )
          : const SizedBox.shrink()),
    );
  }

  /// État vide (aucun bilan généré)
  Widget _buildEmptyState(ActivityReportController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun bilan généré',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sélectionnez une période et générez votre bilan comptable d\'activités pour obtenir une vue d\'ensemble de vos performances.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: controller.generateReport,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Générer le bilan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Text(
              'Période sélectionnée: ${controller.periodLabel}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Contenu du rapport
  Widget _buildReportContent(ActivityReportController controller) {
    final report = controller.currentReport!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé exécutif
          ReportSummaryWidget(report: report),
          const SizedBox(height: 20),

          // Analyse des ventes
          SalesAnalysisWidget(salesData: report.salesData),
          const SizedBox(height: 20),

          // Analyse des bénéfices
          ProfitAnalysisWidget(profitData: report.profitData),
          const SizedBox(height: 20),

          // Mouvements financiers
          FinancialMovementsWidget(financialData: report.financialMovements),
          const SizedBox(height: 20),

          // Dettes clients
          CustomerDebtsWidget(debtsData: report.customerDebts),
          const SizedBox(height: 20),

          // Recommandations
          RecommendationsWidget(recommendations: report.summary.recommendations),
          
          // Espace pour le FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Gère les actions du menu
  void _handleMenuAction(String action, ActivityReportController controller) {
    switch (action) {
      case 'refresh':
        controller.refreshReport();
        break;
      case 'export_pdf':
        controller.exportToPdf();
        break;
      case 'reset':
        _showResetConfirmation(controller);
        break;
    }
  }

  /// Affiche la confirmation de réinitialisation
  void _showResetConfirmation(ActivityReportController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Nouveau bilan'),
        content: const Text('Voulez-vous créer un nouveau bilan ? Le bilan actuel sera perdu.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.reset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}