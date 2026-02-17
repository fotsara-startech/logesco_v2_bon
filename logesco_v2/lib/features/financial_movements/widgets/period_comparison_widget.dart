import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/movement_report_controller.dart';
import '../services/movement_report_service.dart';

/// Widget pour afficher la comparaison entre deux périodes
class PeriodComparisonWidget extends StatelessWidget {
  final MovementReportController controller = Get.find<MovementReportController>();

  PeriodComparisonWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasComparison) {
        return _buildComparisonSetup();
      }

      final comparison = controller.currentComparison.value!;
      return _buildComparisonResults(comparison);
    });
  }

  /// Interface de configuration de la comparaison
  Widget _buildComparisonSetup() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Comparaison entre périodes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Période principale
            _buildPeriodSelector(
              title: 'Période principale',
              startDate: controller.startDate.value,
              endDate: controller.endDate.value,
              onDateChanged: (start, end) => controller.setPeriod(start, end),
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Période de comparaison
            _buildPeriodSelector(
              title: 'Période de comparaison',
              startDate: controller.comparisonStartDate.value,
              endDate: controller.comparisonEndDate.value,
              onDateChanged: (start, end) => controller.setComparisonPeriod(start, end),
              color: Colors.orange,
            ),

            const SizedBox(height: 16),

            // Boutons de périodes prédéfinies pour la comparaison
            Text(
              'Périodes de comparaison suggérées:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPredefinedPeriodChip('Période précédente', 'previous'),
                _buildPredefinedPeriodChip('Mois précédent', 'previousMonth'),
                _buildPredefinedPeriodChip('Année précédente', 'previousYear'),
                _buildPredefinedPeriodChip('Trimestre précédent', 'previousQuarter'),
              ],
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.canCompare && !controller.isLoadingComparison.value ? () => controller.comparePeriods() : null,
                    icon: controller.isLoadingComparison.value
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.analytics),
                    label: Text(controller.isLoadingComparison.value ? 'Comparaison...' : 'Comparer les périodes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: controller.canCompare ? () => controller.swapPeriods() : null,
                  icon: Icon(Icons.swap_horiz),
                  tooltip: 'Échanger les périodes',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Résultats de la comparaison
  Widget _buildComparisonResults(PeriodComparison comparison) {
    return Column(
      children: [
        // En-tête avec résumé
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Comparaison des périodes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.currentComparison.value = null,
                      icon: Icon(Icons.close),
                      tooltip: 'Fermer la comparaison',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Période 1',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                          Text(comparison.period1Formatted),
                        ],
                      ),
                    ),
                    Icon(Icons.compare_arrows, color: Colors.grey),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Période 2',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                          Text(comparison.period2Formatted),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: comparison.hasIncreasedExpenses
                        ? Colors.red.shade100
                        : comparison.hasDecreasedExpenses
                            ? Colors.green.shade100
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        comparison.hasIncreasedExpenses
                            ? Icons.trending_up
                            : comparison.hasDecreasedExpenses
                                ? Icons.trending_down
                                : Icons.trending_flat,
                        color: comparison.hasIncreasedExpenses
                            ? Colors.red
                            : comparison.hasDecreasedExpenses
                                ? Colors.green
                                : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          comparison.comparisonSummary,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: comparison.hasIncreasedExpenses
                                ? Colors.red.shade700
                                : comparison.hasDecreasedExpenses
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Statistiques générales
        _buildGeneralStats(comparison),

        const SizedBox(height: 16),

        // Comparaison par catégorie
        _buildCategoryComparison(comparison),
      ],
    );
  }

  /// Sélecteur de période
  Widget _buildPeriodSelector({
    required String title,
    required DateTime? startDate,
    required DateTime? endDate,
    required Function(DateTime, DateTime) onDateChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  startDate != null && endDate != null ? '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}' : 'Sélectionner une période',
                  style: TextStyle(
                    color: startDate != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _selectDateRange(onDateChanged),
                icon: Icon(Icons.calendar_today, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Chip pour période prédéfinie
  Widget _buildPredefinedPeriodChip(String label, String period) {
    return ActionChip(
      label: Text(label),
      onPressed: controller.hasPeriodSelected ? () => controller.setComparisonPredefinedPeriod(period) : null,
      backgroundColor: Colors.grey.shade100,
    );
  }

  /// Statistiques générales de comparaison
  Widget _buildGeneralStats(PeriodComparison comparison) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques générales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Montant total
            _buildStatRow(
              'Montant total',
              comparison.period1Summary.totalAmountFormatted,
              comparison.period2Summary.totalAmountFormatted,
              comparison.totalAmountDifference,
              comparison.totalAmountVariationPercent,
              isAmount: true,
            ),

            const Divider(),

            // Nombre de mouvements
            _buildStatRow(
              'Nombre de mouvements',
              comparison.period1Summary.totalCount.toString(),
              comparison.period2Summary.totalCount.toString(),
              comparison.countDifference.toDouble(),
              comparison.countVariationPercent,
              isAmount: false,
            ),

            const Divider(),

            // Montant moyen
            _buildStatRow(
              'Montant moyen',
              comparison.period1Summary.averageAmountFormatted,
              comparison.period2Summary.averageAmountFormatted,
              comparison.averageAmountDifference,
              comparison.averageAmountVariationPercent,
              isAmount: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Ligne de statistique
  Widget _buildStatRow(String label, String value1, String value2, double difference, double variationPercent, {required bool isAmount}) {
    final isPositive = difference > 0;
    final isNeutral = difference.abs() < (isAmount ? 1 : 0.1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Période 1',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    Text(value1),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Période 2',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                    Text(value2),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          isNeutral
                              ? Icons.remove
                              : isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                          size: 16,
                          color: isNeutral
                              ? Colors.grey
                              : isPositive
                                  ? Colors.red
                                  : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${variationPercent >= 0 ? '+' : ''}${variationPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isNeutral
                                ? Colors.grey
                                : isPositive
                                    ? Colors.red
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (isAmount)
                      Text(
                        '${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(2)} FCFA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Comparaison par catégorie
  Widget _buildCategoryComparison(PeriodComparison comparison) {
    final categoryComparisons = comparison.categoryComparisons;

    if (categoryComparisons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Aucune donnée de catégorie disponible'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparaison par catégorie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryComparisons.map((catComparison) => _buildCategoryComparisonRow(catComparison)).toList(),
          ],
        ),
      ),
    );
  }

  /// Ligne de comparaison de catégorie
  Widget _buildCategoryComparisonRow(CategoryComparison catComparison) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            width: 4,
            color: Color(int.parse(catComparison.categoryColor.replaceFirst('#', '0xFF'))),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(catComparison.categoryIcon),
                size: 20,
                color: Color(int.parse(catComparison.categoryColor.replaceFirst('#', '0xFF'))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  catComparison.categoryDisplayName,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catComparison.hasIncreased
                      ? Colors.red.shade100
                      : catComparison.hasDecreased
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  catComparison.variationPercentFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: catComparison.hasIncreased
                        ? Colors.red.shade700
                        : catComparison.hasDecreased
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Période 1',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      catComparison.period1AmountFormatted,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${catComparison.period1Count} mouvement${catComparison.period1Count > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Période 2',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      catComparison.period2AmountFormatted,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${catComparison.period2Count} mouvement${catComparison.period2Count > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Différence',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      catComparison.amountDifferenceFormatted,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: catComparison.hasIncreased
                            ? Colors.red
                            : catComparison.hasDecreased
                                ? Colors.green
                                : Colors.grey,
                      ),
                    ),
                    Text(
                      '${catComparison.countDifference >= 0 ? '+' : ''}${catComparison.countDifference} mouvement${catComparison.countDifference.abs() > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sélection de plage de dates
  Future<void> _selectDateRange(Function(DateTime, DateTime) onDateChanged) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      onDateChanged(picked.start, picked.end);
    }
  }

  /// Obtient l'icône pour une catégorie
  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
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
