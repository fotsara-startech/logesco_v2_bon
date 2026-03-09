import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sales_controller.dart';

class SalesFilters extends StatefulWidget {
  const SalesFilters({super.key});

  @override
  State<SalesFilters> createState() => _SalesFiltersState();
}

class _SalesFiltersState extends State<SalesFilters> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedPeriod;
  bool _showPeriodFilters = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SalesController>();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Première ligne: Titre et boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'sales_filters'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            controller.clearFilters();
                            setState(() {
                              _selectedStartDate = null;
                              _selectedEndDate = null;
                              _selectedPeriod = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: Text('sales_clear_filters'.tr),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => setState(() => _showPeriodFilters = !_showPeriodFilters),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showPeriodFilters ? Icons.expand_less : Icons.expand_more,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'sales_filter_by_period'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_showPeriodFilters) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPeriodButton('sales_today'.tr, 'today', controller),
                  _buildPeriodButton('sales_yesterday'.tr, 'yesterday', controller),
                  _buildPeriodButton('sales_this_week'.tr, 'this_week', controller),
                  _buildPeriodButton('sales_last_week'.tr, 'last_week', controller),
                  _buildPeriodButton('sales_this_month'.tr, 'this_month', controller),
                  _buildPeriodButton('sales_last_month'.tr, 'last_month', controller),
                  _buildPeriodButton('Ce trimestre', 'this_quarter', controller),
                  _buildPeriodButton('Trimestre dernier', 'last_quarter', controller),
                  _buildPeriodButton('sales_this_year'.tr, 'this_year', controller),
                  _buildPeriodButton('Année dernière', 'last_year', controller),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'sales_custom_period'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            _selectedStartDate = selectedDate;
                            _selectedPeriod = null;
                          });

                          controller.setDateFilter(selectedDate, _selectedEndDate);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedStartDate != null ? 'Du: ${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}' : 'sales_start_date'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedEndDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            _selectedEndDate = selectedDate;
                            _selectedPeriod = null;
                          });

                          controller.setDateFilter(_selectedStartDate, selectedDate);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedEndDate != null ? 'Au: ${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}' : 'sales_end_date'.tr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_selectedStartDate != null || _selectedEndDate != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedStartDate = null;
                          _selectedEndDate = null;
                        });
                        controller.setDateFilter(null, null);
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Effacer les dates',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit un bouton de période prédéfinie
  Widget _buildPeriodButton(String label, String periodKey, SalesController controller) {
    final isSelected = _selectedPeriod == periodKey;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        print('📅 [FILTRE] Clic sur période: $label (key: $periodKey), selected: $selected');
        setState(() {
          _selectedPeriod = selected ? periodKey : null;
          _selectedStartDate = null;
          _selectedEndDate = null;
        });

        if (selected) {
          final dates = _getDateRangeForPeriod(periodKey);
          print('📅 [FILTRE] Dates finales pour API: start=${dates['start']}, end=${dates['end']}');
          print('📅 [FILTRE] ISO8601 - start=${dates['start']?.toIso8601String()}, end=${dates['end']?.toIso8601String()}');
          controller.setDateFilter(dates['start'], dates['end']);
        } else {
          print('📅 [FILTRE] Désélection de la période');
          controller.setDateFilter(null, null);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade300,
    );
  }

  /// Retourne la plage de dates pour une période prédéfinie
  Map<String, DateTime?> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    print('📅 [DATE_RANGE] Calcul pour période: $period');

    switch (period) {
      case 'today':
        print('📅 [DATE_RANGE] Aujourd\'hui: $today à $endOfToday');
        return {'start': today, 'end': endOfToday};

      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        final endOfYesterday = yesterday.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        print('📅 [DATE_RANGE] Hier: $yesterday à $endOfYesterday');
        return {'start': yesterday, 'end': endOfYesterday};

      case 'this_week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        print('📅 [DATE_RANGE] Cette semaine: $weekStart à $endOfToday');
        return {'start': weekStart, 'end': endOfToday};

      case 'last_week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1 + 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final endOfWeek = weekEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        print('📅 [DATE_RANGE] Semaine dernière: $weekStart à $endOfWeek');
        return {'start': weekStart, 'end': endOfWeek};

      case 'this_month':
        final monthStart = DateTime(now.year, now.month, 1);
        print('📅 [DATE_RANGE] Ce mois: $monthStart à $endOfToday');
        return {'start': monthStart, 'end': endOfToday};

      case 'last_month':
        final lastMonthStart = now.month == 1 ? DateTime(now.year - 1, 12, 1) : DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = now.month == 1 ? DateTime(now.year - 1, 12, 31) : DateTime(now.year, now.month, 0);
        final endOfLastMonth = lastMonthEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        print('📅 [DATE_RANGE] Mois dernier: $lastMonthStart à $endOfLastMonth');
        return {'start': lastMonthStart, 'end': endOfLastMonth};

      case 'this_quarter':
        final quarter = ((now.month - 1) ~/ 3);
        final quarterStart = DateTime(now.year, quarter * 3 + 1, 1);
        print('📅 [DATE_RANGE] Ce trimestre: $quarterStart à $endOfToday');
        return {'start': quarterStart, 'end': endOfToday};

      case 'last_quarter':
        final quarter = ((now.month - 1) ~/ 3);
        final lastQuarter = quarter == 0 ? 3 : quarter - 1;
        final lastYear = quarter == 0 ? now.year - 1 : now.year;
        final quarterStart = DateTime(lastYear, lastQuarter * 3 + 1, 1);
        final quarterEnd = DateTime(lastYear, lastQuarter * 3 + 3, _getDaysInMonth(lastYear, lastQuarter * 3 + 3));
        final endOfQuarter = quarterEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        print('📅 [DATE_RANGE] Trimestre dernier: $quarterStart à $endOfQuarter');
        return {'start': quarterStart, 'end': endOfQuarter};

      case 'this_year':
        final yearStart = DateTime(now.year, 1, 1);
        print('📅 [DATE_RANGE] Cette année: $yearStart à $endOfToday');
        return {'start': yearStart, 'end': endOfToday};

      case 'last_year':
        final lastYearStart = DateTime(now.year - 1, 1, 1);
        final lastYearEnd = DateTime(now.year - 1, 12, 31);
        final endOfLastYear = lastYearEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        print('📅 [DATE_RANGE] Année dernière: $lastYearStart à $endOfLastYear');
        return {'start': lastYearStart, 'end': endOfLastYear};

      default:
        print('📅 [DATE_RANGE] Période inconnue: $period');
        return {'start': null, 'end': null};
    }
  }

  /// Retourne le nombre de jours dans un mois
  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    }
    return [31, 31, 30, 31, 30, 31, 31, 31, 30, 31, 30, 31][month - 1];
  }
}
