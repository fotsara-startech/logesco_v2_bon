import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/movement_report_controller.dart';
import '../services/movement_report_service.dart';
import '../utils/financial_error_handler.dart';
import '../../../core/routes/app_routes.dart';

/// Widget de résumé financier hebdomadaire pour le dashboard
///
/// Affiche un résumé compact des mouvements financiers de la semaine
/// avec comparaison par rapport à la semaine précédente.
class WeeklyFinancialSummaryWidget extends StatelessWidget {
  /// Couleur principale du widget
  final Color? primaryColor;

  /// Callback appelé lors du clic sur le widget
  final VoidCallback? onTap;

  const WeeklyFinancialSummaryWidget({
    super.key,
    this.primaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenir ou créer le contrôleur de rapport
    final MovementReportController controller = Get.put(
      MovementReportController(),
      tag: 'weekly_summary',
    );

    // Configurer la période pour cette semaine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setPredefinedPeriod('thisWeek');
      Future.delayed(const Duration(milliseconds: 100), () {
        controller.loadSummary();
      });
    });

    final color = primaryColor ?? Theme.of(context).primaryColor;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap ?? () => _navigateToFinancialReports(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Obx(() => _buildContent(controller, color, context)),
        ),
      ),
    );
  }

  Widget _buildContent(MovementReportController controller, Color color, BuildContext context) {
    if (controller.isLoadingSummary.value) {
      return _buildLoadingState(color);
    }

    if (controller.error.value.isNotEmpty) {
      return _buildErrorState(controller.error.value, color);
    }

    final summary = controller.currentSummary.value;
    if (summary == null) {
      return _buildNoDataState(color);
    }

    return _buildSummaryContent(summary, color, context);
  }

  Widget _buildLoadingState(Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Résumé hebdomadaire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chargement...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Résumé hebdomadaire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _retryLoad(),
          icon: const Icon(Icons.refresh, color: Colors.red),
          tooltip: 'Réessayer',
        ),
      ],
    );
  }

  Widget _buildNoDataState(Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.trending_up,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Résumé hebdomadaire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aucune dépense cette semaine',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '0 FCFA • 0 mouvement',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContent(MovementSummary summary, Color color, BuildContext context) {
    return Column(
      children: [
        // Ligne principale
        Row(
          children: [
            // Icône avec indicateur
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.trending_up,
                      color: color,
                      size: 24,
                    ),
                  ),
                  // Indicateur de niveau de dépense
                  if (summary.totalAmount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getExpenseIndicatorColor(summary.totalAmount),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Contenu principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et montant
                  Row(
                    children: [
                      Text(
                        'Résumé hebdomadaire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        summary.totalAmountFormatted,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: summary.totalAmount > 0 ? Colors.red[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Détails
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.totalCount} mouvement${summary.totalCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (summary.totalCount > 0) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_view_week,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Moy/jour: ${(summary.totalAmount / 7).toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Barre de progression ou indicateur de tendance
        if (summary.totalAmount > 0) ...[
          const SizedBox(height: 12),
          _buildWeeklyTrend(summary, color),
        ],
      ],
    );
  }

  Widget _buildWeeklyTrend(MovementSummary summary, Color color) {
    final level = _calculateExpenseLevel(summary.totalAmount);

    return Column(
      children: [
        Row(
          children: [
            Text(
              _getExpenseLevelText(level),
              style: TextStyle(
                fontSize: 10,
                color: _getExpenseIndicatorColor(summary.totalAmount),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              'Cette semaine',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: level / 3, // Normaliser sur 3 niveaux
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getExpenseIndicatorColor(summary.totalAmount),
          ),
          minHeight: 3,
        ),
      ],
    );
  }

  /// Calcule le niveau de dépense hebdomadaire (1: faible, 2: moyen, 3: élevé)
  int _calculateExpenseLevel(double amount) {
    if (amount == 0) return 0;
    if (amount < 50000) return 1; // Faible
    if (amount < 200000) return 2; // Moyen
    return 3; // Élevé
  }

  /// Obtient la couleur de l'indicateur selon le montant
  Color _getExpenseIndicatorColor(double amount) {
    final level = _calculateExpenseLevel(amount);
    switch (level) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtient le texte du niveau de dépense
  String _getExpenseLevelText(int level) {
    switch (level) {
      case 0:
        return 'Aucune dépense';
      case 1:
        return 'Dépenses faibles';
      case 2:
        return 'Dépenses modérées';
      case 3:
        return 'Dépenses élevées';
      default:
        return '';
    }
  }

  /// Navigue vers la page des rapports financiers
  void _navigateToFinancialReports() {
    try {
      Get.toNamed(AppRoutes.financialMovementReports);
    } catch (e) {
      print('❌ Erreur navigation vers rapports financiers: $e');
      Get.snackbar(
        'Navigation',
        'Impossible d\'ouvrir les rapports financiers',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    }
  }

  /// Réessaie le chargement des données
  void _retryLoad() {
    try {
      final controller = Get.find<MovementReportController>(tag: 'weekly_summary');
      controller.setPredefinedPeriod('thisWeek');
      controller.loadSummary(forceRefresh: true);
    } catch (e) {
      print('❌ Erreur lors du rechargement: $e');
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: 'Erreur lors du rechargement du résumé hebdomadaire',
          code: 'WEEKLY_SUMMARY_RETRY_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.unknownError,
        ),
        operation: 'retryLoad',
      );
    }
  }
}
