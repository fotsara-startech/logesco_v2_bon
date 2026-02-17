import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/activity_report_controller.dart';

/// Widget pour sélectionner la période du bilan
class PeriodSelectorWidget extends StatelessWidget {
  const PeriodSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ActivityReportController>();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Période d\'analyse',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Périodes prédéfinies
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPeriodChip('today', 'Aujourd\'hui', controller),
              _buildPeriodChip('yesterday', 'Hier', controller),
              _buildPeriodChip('thisWeek', 'Cette semaine', controller),
              _buildPeriodChip('lastWeek', 'Semaine dernière', controller),
              _buildPeriodChip('thisMonth', 'Ce mois', controller),
              _buildPeriodChip('lastMonth', 'Mois dernier', controller),
              _buildPeriodChip('thisQuarter', 'Ce trimestre', controller),
              _buildPeriodChip('thisYear', 'Cette année', controller),
              _buildPeriodChip('lastYear', 'Année dernière', controller),
            ],
          ),

          const SizedBox(height: 16),

          // Sélection personnalisée
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'Date de début',
                  controller.selectedStartDate,
                  () => controller.selectStartDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateSelector(
                  'Date de fin',
                  controller.selectedEndDate,
                  () => controller.selectEndDate(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bouton de génération
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isLoading ? null : controller.generateReport,
                  icon: controller.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : const Icon(Icons.assessment),
                  label: Text(controller.isLoading ? 'Génération...' : 'Générer le bilan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  /// Chip pour une période prédéfinie
  Widget _buildPeriodChip(String period, String label, ActivityReportController controller) {
    return Obx(() {
      final isSelected = controller.selectedPeriod == period;

      return GestureDetector(
        onTap: () => controller.selectPeriod(period),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue.shade700 : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Sélecteur de date personnalisé
  Widget _buildDateSelector(String label, DateTime? selectedDate, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedDate != null ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}' : 'Sélectionner',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
