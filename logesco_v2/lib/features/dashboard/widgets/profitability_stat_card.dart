import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../accounting/controllers/accounting_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/permission_widget.dart';

/// Carte de statistique de rentabilité pour la grille du dashboard
class ProfitabilityStatCard extends StatelessWidget {
  const ProfitabilityStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionWidget(
      module: 'accounting',
      privilege: 'READ',
      child: GetBuilder<AccountingController>(
        init: AccountingController(),
        builder: (controller) {
          return Obx(() {
            final summary = controller.quickSummary;

            if (summary.isEmpty) {
              return _buildLoadingCard();
            }

            final isProfitable = summary['isProfitable'] ?? false;
            final netProfit = (summary['netProfit'] ?? 0.0) as double;
            final profitMargin = (summary['profitMargin'] ?? 0.0) as double;
            final statusColor = _parseColor(summary['statusColor'] ?? '#6B7280');

            return InkWell(
              onTap: () => Get.toNamed(AppRoutes.accounting),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: statusColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec icône
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.analytics,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isProfitable ? Icons.trending_up : Icons.trending_down,
                          color: statusColor,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Titre
                    Text(
                      'Rentabilité',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Valeur principale
                    Text(
                      '${netProfit.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Marge
                    Text(
                      'Marge: ${profitMargin.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Indicateur de statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isProfitable ? 'Rentable' : 'À surveiller',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  /// Carte de chargement
  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Titre
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),

          // Valeur
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),

          // Sous-titre
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
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
