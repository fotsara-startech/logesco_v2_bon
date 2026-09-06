import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/proforma_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Filtres du listing proforma — mêmes filtres que la page de vente
/// (vendeur pour les admins, période/plage de dates). Le filtre commercial
/// n'existe pas ici : VenteProforma n'a pas de champ commercial/zone/ville.
class ProformaFilters extends StatefulWidget {
  const ProformaFilters({super.key});

  @override
  State<ProformaFilters> createState() => _ProformaFiltersState();
}

class _ProformaFiltersState extends State<ProformaFilters> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedPeriod;
  bool _showPeriodFilters = false;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProformaController>(
      builder: (controller) => Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Première ligne : titre et boutons d'action
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text('sales_filters'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          controller.clearFilters();
                          setState(() {
                            _selectedStartDate = null;
                            _selectedEndDate = null;
                            _selectedPeriod = null;
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: Text('sales_clear_filters'.tr),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _showPeriodFilters = !_showPeriodFilters),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_showPeriodFilters ? Icons.expand_less : Icons.expand_more, size: 20),
                            const SizedBox(width: 4),
                            Text('sales_filter_by_period'.tr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Filtre par vendeur (admins uniquement)
              Builder(builder: (context) {
                bool isAdmin = false;
                try {
                  isAdmin = Get.find<AuthController>().currentUser.value?.role.isAdmin ?? false;
                } catch (_) {}
                if (!isAdmin || controller.vendeurs.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Autocomplete<Map<String, dynamic>>(
                            initialValue: controller.vendeurIdFilter > 0
                                ? TextEditingValue(
                                    text: controller.vendeurs.firstWhere(
                                      (v) => v['id'] == controller.vendeurIdFilter,
                                      orElse: () => {'nomUtilisateur': ''},
                                    )['nomUtilisateur'] as String,
                                  )
                                : const TextEditingValue(),
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) return controller.vendeurs;
                              final query = textEditingValue.text.toLowerCase();
                              return controller.vendeurs.where((v) => (v['nomUtilisateur'] as String).toLowerCase().contains(query));
                            },
                            displayStringForOption: (v) => v['nomUtilisateur'] as String,
                            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'sales_filter_by_seller'.tr,
                                  hintText: 'sales_filter_all_sellers'.tr,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: textEditingController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: () {
                                            textEditingController.clear();
                                            controller.setVendeurFilter(0);
                                          },
                                        )
                                      : null,
                                ),
                              );
                            },
                            onSelected: (v) => controller.setVendeurFilter(v['id'] as int),
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          return ListTile(
                                            dense: true,
                                            title: Text('sales_filter_all_sellers'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            onTap: () {
                                              controller.setVendeurFilter(0);
                                              onSelected({'id': 0, 'nomUtilisateur': ''});
                                            },
                                          );
                                        }
                                        final v = options.elementAt(index - 1);
                                        return ListTile(
                                          dense: true,
                                          title: Text(v['nomUtilisateur'] as String),
                                          onTap: () => onSelected(v),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),

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
                Text('sales_custom_period'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                        label: Text(_selectedStartDate != null ? 'Du: ${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}' : 'sales_start_date'.tr),
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
                        label: Text(_selectedEndDate != null ? 'Au: ${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}' : 'sales_end_date'.tr),
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
      ),
    );
  }

  Widget _buildPeriodButton(String label, String periodKey, ProformaController controller) {
    final isSelected = _selectedPeriod == periodKey;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = selected ? periodKey : null;
          _selectedStartDate = null;
          _selectedEndDate = null;
        });
        if (selected) {
          final dates = _getDateRangeForPeriod(periodKey);
          controller.setDateFilter(dates['start'], dates['end']);
        } else {
          controller.setDateFilter(null, null);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.orange.shade200,
    );
  }

  Map<String, DateTime?> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    switch (period) {
      case 'today':
        return {'start': today, 'end': endOfToday};
      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return {'start': yesterday, 'end': yesterday.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))};
      case 'this_week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return {'start': weekStart, 'end': endOfToday};
      case 'last_week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1 + 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return {'start': weekStart, 'end': weekEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))};
      case 'this_month':
        return {'start': DateTime(now.year, now.month, 1), 'end': endOfToday};
      case 'last_month':
        final lastMonthStart = now.month == 1 ? DateTime(now.year - 1, 12, 1) : DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = now.month == 1 ? DateTime(now.year - 1, 12, 31) : DateTime(now.year, now.month, 0);
        return {'start': lastMonthStart, 'end': lastMonthEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))};
      case 'this_quarter':
        final quarter = ((now.month - 1) ~/ 3);
        return {'start': DateTime(now.year, quarter * 3 + 1, 1), 'end': endOfToday};
      case 'last_quarter':
        final quarter = ((now.month - 1) ~/ 3);
        final lastQuarter = quarter == 0 ? 3 : quarter - 1;
        final lastYear = quarter == 0 ? now.year - 1 : now.year;
        final quarterStart = DateTime(lastYear, lastQuarter * 3 + 1, 1);
        final quarterEnd = DateTime(lastYear, lastQuarter * 3 + 3, _getDaysInMonth(lastYear, lastQuarter * 3 + 3));
        return {'start': quarterStart, 'end': quarterEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))};
      case 'this_year':
        return {'start': DateTime(now.year, 1, 1), 'end': endOfToday};
      case 'last_year':
        final lastYearStart = DateTime(now.year - 1, 1, 1);
        final lastYearEnd = DateTime(now.year - 1, 12, 31);
        return {'start': lastYearStart, 'end': lastYearEnd.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))};
      default:
        return {'start': null, 'end': null};
    }
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    }
    return [31, 31, 30, 31, 30, 31, 31, 31, 30, 31, 30, 31][month - 1];
  }
}
