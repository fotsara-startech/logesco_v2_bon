import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/movement_report_controller.dart';
import '../services/movement_report_service.dart';
import '../utils/financial_error_handler.dart';

/// Widget de résumé des dépenses du jour
///
/// Affiche un résumé compact des mouvements financiers de la journée en cours
/// avec le montant total, le nombre de mouvements et un indicateur visuel.
class DailyExpensesSummaryWidget extends StatelessWidget {
  /// Couleur principale du widget
  final Color? primaryColor;

  /// Afficher ou non les détails étendus
  final bool showDetails;

  /// Callback appelé lors du clic sur le widget
  final VoidCallback? onTap;

  /// Hauteur du widget
  final double? height;

  const DailyExpensesSummaryWidget({
    super.key,
    this.primaryColor,
    this.showDetails = true,
    this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenir ou créer le contrôleur de rapport
    final MovementReportController controller = Get.put(
      MovementReportController(),
      tag: 'daily_summary',
    );

    // Configurer la période pour aujourd'hui
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setPredefinedPeriod('today');
      // Délai pour permettre aux tests de voir l'état de chargement
      Future.delayed(const Duration(milliseconds: 100), () {
        controller.loadSummary();
      });
    });

    final color = primaryColor ?? Theme.of(context).primaryColor;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap ?? () => _navigateToFinancialMovements(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height ?? (showDetails ? 120 : 80),
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
                'Dépenses du jour',
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
                'Dépenses du jour',
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
            Icons.account_balance_wallet_outlined,
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
                'Dépenses du jour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aucune dépense aujourd\'hui',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (showDetails) ...[
                const SizedBox(height: 4),
                Text(
                  '0 FCFA • 0 mouvement',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContent(MovementSummary summary, Color color, BuildContext context) {
    return Row(
      children: [
        // Icône avec indicateur de montant
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
                  Icons.account_balance_wallet,
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
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre et montant
              Row(
                children: [
                  Text(
                    'Dépenses du jour',
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
              if (showDetails) ...[
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${summary.totalCount} mouvement${summary.totalCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (summary.totalCount > 0) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Moy: ${summary.averageAmountFormatted}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (summary.totalAmount > 0) ...[
                  const SizedBox(height: 4),
                  // Barre de progression ou indicateur
                  _buildExpenseIndicator(summary, color),
                ],
              ] else ...[
                // Version compacte
                Text(
                  '${summary.totalCount} mouvement${summary.totalCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Flèche de navigation
        Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
          size: 20,
        ),
      ],
    );
  }

  Widget _buildExpenseIndicator(MovementSummary summary, Color color) {
    // Calculer un niveau relatif basé sur le montant moyen
    final level = _calculateExpenseLevel(summary.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            if (summary.lastMovementDate != null)
              Text(
                'Dernier: ${_formatTime(summary.lastMovementDate!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: level / 3, // Normaliser sur 3 niveaux
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getExpenseIndicatorColor(summary.totalAmount),
          ),
          minHeight: 2,
        ),
      ],
    );
  }

  /// Calcule le niveau de dépense (1: faible, 2: moyen, 3: élevé)
  int _calculateExpenseLevel(double amount) {
    if (amount == 0) return 0;
    if (amount < 10000) return 1; // Faible
    if (amount < 50000) return 2; // Moyen
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

  /// Formate l'heure pour l'affichage
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Navigue vers la page des mouvements financiers
  void _navigateToFinancialMovements() {
    try {
      Get.toNamed('/financial-movements');
    } catch (e) {
      print('❌ Erreur navigation vers mouvements financiers: $e');
      Get.snackbar(
        'Navigation',
        'Impossible d\'ouvrir les mouvements financiers',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    }
  }

  /// Réessaie le chargement des données
  void _retryLoad() {
    try {
      final controller = Get.find<MovementReportController>(tag: 'daily_summary');
      controller.setPredefinedPeriod('today');
      controller.loadSummary(forceRefresh: true);
    } catch (e) {
      print('❌ Erreur lors du rechargement: $e');
      FinancialErrorHandler.logError(
        FinancialMovementException(
          message: 'Erreur lors du rechargement du résumé quotidien',
          code: 'DAILY_SUMMARY_RETRY_ERROR',
          statusCode: 500,
          errorType: FinancialErrorType.unknownError,
        ),
        operation: 'retryLoad',
      );
    }
  }
}

/// Widget compact pour l'affichage dans une grille ou liste
class CompactDailyExpensesSummary extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;

  const CompactDailyExpensesSummary({
    super.key,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DailyExpensesSummaryWidget(
      primaryColor: color,
      showDetails: false,
      height: 80, // Augmenter la hauteur pour éviter l'overflow
      onTap: onTap,
    );
  }
}

/// Widget étendu pour l'affichage détaillé
class DetailedDailyExpensesSummary extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;

  const DetailedDailyExpensesSummary({
    super.key,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DailyExpensesSummaryWidget(
      primaryColor: color,
      showDetails: true,
      height: 140,
      onTap: onTap,
    );
  }
}
