import 'package:flutter/material.dart';
import '../controllers/accounting_controller.dart';

/// Widget de sélection de période pour l'analyse comptable
class PeriodSelectorWidget extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final Function(PredefinedPeriod) onPredefinedPeriodSelected;

  const PeriodSelectorWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onPredefinedPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Période d\'analyse',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    // Déclencher le rechargement en appelant les callbacks
                    if (startDate != null && endDate != null) {
                      onStartDateChanged(startDate!);
                    }
                  },
                  tooltip: 'Actualiser les données',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sélecteurs de date
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    context,
                    'Date de début',
                    startDate,
                    onStartDateChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateSelector(
                    context,
                    'Date de fin',
                    endDate,
                    onEndDateChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Périodes prédéfinies
            const Text(
              'Périodes rapides',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PredefinedPeriod.values.map((period) {
                return _buildPeriodChip(period);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un sélecteur de date
  Widget _buildDateSelector(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? '${date.day}/${date.month}/${date.year}' : 'Sélectionner',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: date != null ? Colors.black : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une puce de période prédéfinie
  Widget _buildPeriodChip(PredefinedPeriod period) {
    return ActionChip(
      label: Text(
        period.label,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () => onPredefinedPeriodSelected(period),
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
    );
  }
}
