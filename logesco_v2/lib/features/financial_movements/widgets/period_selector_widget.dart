import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget pour la sélection de période dans les rapports
class PeriodSelectorWidget extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime) onStartDateChanged;
  final Function(DateTime) onEndDateChanged;
  final Function(String) onPredefinedPeriodSelected;

  const PeriodSelectorWidget({
    super.key,
    this.startDate,
    this.endDate,
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
            Text(
              'financial_movements_reports_period_selector'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Boutons de période prédéfinie
            _buildPredefinedPeriods(),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Sélecteur de période personnalisée
            _buildCustomPeriodSelector(),

            if (startDate != null && endDate != null) ...[
              const SizedBox(height: 16),
              _buildSelectedPeriodInfo(),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit les boutons de période prédéfinie
  Widget _buildPredefinedPeriods() {
    final periods = [
      {'label': 'financial_movements_period_today'.tr, 'value': 'today'},
      {'label': 'financial_movements_period_yesterday'.tr, 'value': 'yesterday'},
      {'label': 'financial_movements_period_this_week'.tr, 'value': 'thisWeek'},
      {'label': 'financial_movements_period_last_week'.tr, 'value': 'lastWeek'},
      {'label': 'financial_movements_period_this_month'.tr, 'value': 'thisMonth'},
      {'label': 'financial_movements_period_last_month'.tr, 'value': 'lastMonth'},
      {'label': 'financial_movements_period_this_year'.tr, 'value': 'thisYear'},
      {'label': 'financial_movements_period_last_year'.tr, 'value': 'lastYear'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: periods.map((period) {
        return ElevatedButton(
          onPressed: () => onPredefinedPeriodSelected(period['value']!),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue.shade700,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.blue.shade200),
            ),
          ),
          child: Text(period['label']!),
        );
      }).toList(),
    );
  }

  /// Construit le sélecteur de période personnalisée
  Widget _buildCustomPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateSelector(
            'financial_movements_filter_start_date'.tr,
            startDate,
            onStartDateChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateSelector(
            'financial_movements_filter_end_date'.tr,
            endDate,
            onEndDateChanged,
          ),
        ),
      ],
    );
  }

  /// Construit un sélecteur de date
  Widget _buildDateSelector(
    String label,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: Get.context!,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('fr', 'FR'),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
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
                  Text(
                    selectedDate != null ? _formatDate(selectedDate) : 'financial_movements_filter_select'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'information sur la période sélectionnée
  Widget _buildSelectedPeriodInfo() {
    final dayCount = endDate!.difference(startDate!).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'financial_movements_selected_period'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_formatDate(startDate!)} - ${_formatDate(endDate!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dayCount > 1 ? 'financial_movements_days_plural'.tr.replaceAll('@count', '$dayCount') : 'financial_movements_days_singular'.tr.replaceAll('@count', '$dayCount'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formate une date pour l'affichage
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
