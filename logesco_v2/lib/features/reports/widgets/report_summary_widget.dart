import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/activity_report.dart';

/// Widget pour afficher le résumé exécutif du bilan
class ReportSummaryWidget extends StatelessWidget {
  final ActivityReport report;

  const ReportSummaryWidget({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'reports_summary_title'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        report.reportPeriod,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: 20),

            // Message de statut
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      report.summary.statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Métriques clés
            Text(
              'reports_summary_key_indicators'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildKeyMetricsGrid(),

            const SizedBox(height: 20),

            // Points saillants
            Text(
              'reports_summary_highlights'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildHighlights(),
          ],
        ),
      ),
    );
  }

  /// En-tête avec informations complètes de l'entreprise
  Widget _buildCompanyHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre principal
          Row(
            children: [
              Icon(
                Icons.business,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'reports_pdf_title'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      report.companyInfo.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informations de l'entreprise
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'reports_pdf_company_info'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),

                // Grille d'informations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonne 1
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (report.companyInfo.address.isNotEmpty) _buildInfoRow(Icons.location_on, 'reports_pdf_address'.tr, report.companyInfo.address),
                          if (report.companyInfo.location.isNotEmpty) _buildInfoRow(Icons.place, 'reports_pdf_location'.tr, report.companyInfo.location),
                          if (report.companyInfo.phone.isNotEmpty) _buildInfoRow(Icons.phone, 'reports_pdf_phone'.tr, report.companyInfo.phone),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Colonne 2
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (report.companyInfo.email.isNotEmpty) _buildInfoRow(Icons.email, 'reports_pdf_email'.tr, report.companyInfo.email),
                          if (report.companyInfo.nuiRccm.isNotEmpty) _buildInfoRow(Icons.assignment, 'NUI RCCM', report.companyInfo.nuiRccm),
                          _buildInfoRow(Icons.calendar_today, 'reports_pdf_period'.tr, report.reportPeriod),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne d'information avec icône
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de statut
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        report.summary.overallStatus,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Grille des métriques clés
  Widget _buildKeyMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: report.summary.keyMetrics.map((metric) => _buildMetricCard(metric)).toList(),
    );
  }

  /// Carte de métrique
  Widget _buildMetricCard(KeyMetric metric) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                metric.trend == 'up' ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: metric.trend == 'up' ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${metric.value} ${metric.unit}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getColorFromHex(metric.color),
            ),
          ),
        ],
      ),
    );
  }

  /// Points saillants
  Widget _buildHighlights() {
    final highlights = [
      'reports_summary_revenue'.tr.replaceAll('@amount', report.salesData.totalRevenueFormatted),
      'reports_summary_sales_count'.tr.replaceAll('@count', report.salesData.totalSales.toString()),
      'reports_summary_net_profit'.tr.replaceAll('@amount', report.profitData.netProfitFormatted),
      'reports_summary_profit_margin'.tr.replaceAll('@percent', report.profitData.profitMarginFormatted),
      'reports_summary_customer_debts'.tr.replaceAll('@amount', report.customerDebts.totalOutstandingDebtFormatted),
      'reports_summary_cash_flow'.tr.replaceAll('@amount', report.financialMovements.netCashFlowFormatted),
    ];

    return Column(
      children: highlights
          .map((highlight) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        highlight,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  /// Obtient la couleur du statut
  Color _getStatusColor() {
    return _getColorFromHex(report.summary.statusColor);
  }

  /// Obtient l'icône du statut
  IconData _getStatusIcon() {
    final status = report.summary.overallStatus.toLowerCase();
    if (status == 'excellent') return Icons.star;
    if (status == 'bon' || status == 'good') return Icons.thumb_up;
    if (status == 'modéré' || status == 'modere' || status == 'moderate') return Icons.info;
    if (status == 'attention' || status == 'warning') return Icons.warning;
    if (status == 'critique' || status == 'critical') return Icons.error;
    return Icons.help;
  }

  /// Convertit une couleur hexadécimale en Color
  Color _getColorFromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
