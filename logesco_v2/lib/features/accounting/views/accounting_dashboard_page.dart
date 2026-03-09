import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/accounting_controller.dart';
import '../widgets/profitability_overview_widget.dart';
import '../widgets/financial_balance_widget.dart';
import '../widgets/period_selector_widget.dart';
import '../widgets/kpi_indicators_widget.dart';
import '../widgets/revenue_expenses_chart_widget.dart';
import '../widgets/daily_balance_chart_widget.dart';
import '../widgets/category_breakdown_widget.dart';
import '../widgets/margin_explanation_widget.dart';
import '../widgets/period_info_widget.dart';

/// Page principale du tableau de bord comptable
class AccountingDashboardPage extends StatelessWidget {
  const AccountingDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountingController>(
      init: AccountingController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text('accounting_title'.tr),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => controller.refreshAllData(),
                tooltip: 'refresh'.tr,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'export_pdf':
                      _exportToPdf(controller);
                      break;
                    case 'export_excel':
                      _exportToExcel(controller);
                      break;
                    case 'settings':
                      _showSettings();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export_pdf',
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('accounting_export_pdf'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_excel',
                    child: Row(
                      children: [
                        const Icon(Icons.table_chart, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('accounting_export_excel'.tr),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('settings'.tr),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value && !controller.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('accounting_calculating'.tr),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.refreshAllData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vue d'ensemble de la rentabilité
                    ProfitabilityOverviewWidget(),
                    const SizedBox(height: 16),

                    // Sélecteur de période
                    Stack(
                      children: [
                        PeriodSelectorWidget(
                          startDate: controller.startDate.value,
                          endDate: controller.endDate.value,
                          onStartDateChanged: (date) {
                            controller.startDate.value = date;
                            if (controller.endDate.value != null) {
                              controller.loadFinancialBalance();
                            }
                          },
                          onEndDateChanged: (date) {
                            controller.endDate.value = date;
                            if (controller.startDate.value != null) {
                              controller.loadFinancialBalance();
                            }
                          },
                          onPredefinedPeriodSelected: (period) {
                            controller.setPredefinedPeriod(period);
                            controller.loadFinancialBalance();
                          },
                        ),
                        if (controller.isLoading.value)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'loading'.tr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filtre par catégorie de produit
                    Obx(() {
                      if (controller.productCategories.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.filter_list, size: 20, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'accounting_filter_by_category'.tr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int?>(
                                value: controller.selectedCategoryId.value,
                                decoration: InputDecoration(
                                  labelText: 'categories_title'.tr,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('accounting_all_categories'.tr),
                                  ),
                                  ...controller.productCategories.map((category) {
                                    return DropdownMenuItem<int?>(
                                      value: category['id'] as int,
                                      child: Text(category['nom'] as String),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  controller.setCategoryFilter(value);
                                },
                              ),
                              if (controller.selectedCategoryId.value != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'accounting_category_filter_info'.tr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Informations sur la période
                    if (controller.hasPeriodSelected && controller.currentBalance.value != null)
                      PeriodInfoWidget(
                        startDate: controller.startDate.value!,
                        endDate: controller.endDate.value!,
                        totalMovements: controller.currentBalance.value!.totalSales + controller.currentBalance.value!.totalExpenseItems,
                        totalAmount: controller.currentBalance.value!.totalRevenue,
                      ),
                    const SizedBox(height: 16),

                    // Bilan financier principal
                    if (controller.currentBalance.value != null)
                      FinancialBalanceWidget(
                        balance: controller.currentBalance.value!,
                      ),
                    const SizedBox(height: 16),

                    // Explication du calcul de la marge
                    if (controller.currentBalance.value != null)
                      MarginExplanationWidget(
                        balance: controller.currentBalance.value!,
                      ),
                    const SizedBox(height: 16),

                    // Indicateurs KPI
                    if (controller.kpiIndicators.value != null)
                      KPIIndicatorsWidget(
                        kpis: controller.kpiIndicators.value!,
                      ),
                    const SizedBox(height: 16),

                    // Graphiques revenus vs dépenses
                    if (controller.currentBalance.value != null)
                      RevenueExpensesChartWidget(
                        balance: controller.currentBalance.value!,
                      ),
                    const SizedBox(height: 16),

                    // Graphique de l'évolution quotidienne
                    if (controller.currentBalance.value != null && controller.currentBalance.value!.dailyBalances.isNotEmpty)
                      DailyBalanceChartWidget(
                        dailyBalances: controller.currentBalance.value!.dailyBalances,
                      ),
                    const SizedBox(height: 16),

                    // Répartition par catégorie
                    if (controller.currentBalance.value != null)
                      CategoryBreakdownWidget(
                        balance: controller.currentBalance.value!,
                      ),

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

  /// Construit le message d'absence de données
  Widget _buildNoDataMessage(AccountingController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.account_balance,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'accounting_no_data'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.hasPeriodSelected ? 'accounting_no_data_period'.trParams({'period': controller.periodFormatted}) : 'accounting_select_period'.tr,
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (controller.hasPeriodSelected) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadFinancialBalance(),
                icon: const Icon(Icons.refresh),
                label: Text('refresh'.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Exporte le bilan en PDF
  void _exportToPdf(AccountingController controller) {
    // TODO: Implémenter l'export PDF
    Get.snackbar(
      'accounting_export_pdf'.tr,
      'accounting_feature_in_development'.tr,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  /// Exporte le bilan en Excel
  void _exportToExcel(AccountingController controller) {
    // TODO: Implémenter l'export Excel
    Get.snackbar(
      'accounting_export_excel'.tr,
      'accounting_feature_in_development'.tr,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }

  /// Affiche les paramètres
  void _showSettings() {
    // TODO: Implémenter les paramètres comptables
    Get.snackbar(
      'settings'.tr,
      'accounting_feature_in_development'.tr,
      backgroundColor: Colors.grey.shade100,
      colorText: Colors.grey.shade800,
    );
  }
}
