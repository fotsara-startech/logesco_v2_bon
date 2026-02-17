import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../accounting/controllers/accounting_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/permission_widget.dart';

/// Widget de résumé comptable pour le dashboard
class AccountingSummaryWidget extends StatelessWidget {
  const AccountingSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      module: 'accounting',
      privilege: 'READ',
      child: GetBuilder<AccountingController>(
        init: AccountingController(),
        builder: (controller) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.accounting),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade50,
                      Colors.green.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Comptabilité & Rentabilité',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Analyse financière du mois',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Contenu principal
                    Obx(() {
                      final summary = controller.quickSummary;

                      if (summary.isEmpty) {
                        return _buildLoadingState();
                      }

                      return _buildSummaryContent(summary);
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// État de chargement
  Widget _buildLoadingState() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricSkeleton(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricSkeleton(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  /// Squelette de métrique
  Widget _buildMetricSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            height: 16,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Contenu du résumé
  Widget _buildSummaryContent(Map<String, dynamic> summary) {
    final isProfitable = summary['isProfitable'] ?? false;
    final netProfit = (summary['netProfit'] ?? 0.0) as double;
    final profitMargin = (summary['profitMargin'] ?? 0.0) as double;
    final statusMessage = summary['statusMessage'] ?? 'Statut inconnu';
    final statusColor = _parseColor(summary['statusColor'] ?? '#6B7280');
    final totalRevenue = (summary['totalRevenue'] ?? 0.0) as double;
    final totalExpenses = (summary['totalExpenses'] ?? 0.0) as double;

    return Column(
      children: [
        // Métriques principales
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Bénéfice Net',
                '${netProfit.toStringAsFixed(0)} FCFA',
                isProfitable ? Icons.trending_up : Icons.trending_down,
                isProfitable ? Colors.green.shade600 : Colors.red.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Marge',
                '${profitMargin.toStringAsFixed(1)}%',
                Icons.percent,
                statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Revenus et dépenses
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Revenus',
                '${totalRevenue.toStringAsFixed(0)} FCFA',
                Icons.attach_money,
                Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Dépenses',
                '${totalExpenses.toStringAsFixed(0)} FCFA',
                Icons.money_off,
                Colors.orange.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Statut de rentabilité
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isProfitable ? Icons.check_circle : Icons.warning,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
              Text(
                'Voir détails',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit une carte de métrique
  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
}
