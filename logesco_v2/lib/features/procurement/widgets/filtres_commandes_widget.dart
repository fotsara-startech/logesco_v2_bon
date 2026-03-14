/**
 * Widget pour filtrer les commandes d'approvisionnement
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/procurement_controller.dart';
import '../models/procurement_models.dart';

class FiltresCommandesWidget extends StatelessWidget {
  final ProcurementController controller;

  const FiltresCommandesWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Expanded(
                  child: Text(
                    'procurement_filter_orders'.tr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const Divider(),

            // Filtre par statut
            Text(
              'procurement_filter_status'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Obx(() => DropdownButtonFormField<CommandeStatut?>(
                  value: controller.statutFiltre.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'procurement_filter_all_status'.tr,
                  ),
                  items: [
                    DropdownMenuItem<CommandeStatut?>(
                      value: null,
                      child: Text('procurement_filter_all_status'.tr),
                    ),
                    ...CommandeStatut.values.map((statut) {
                      return DropdownMenuItem<CommandeStatut?>(
                        value: statut,
                        child: Text(statut.label),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) => controller.statutFiltre.value = value,
                )),

            const SizedBox(height: 16),

            // Filtre par période
            Text(
              'procurement_filter_period'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Obx(() => InkWell(
                        onTap: () => _selectDateDebut(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  controller.dateDebutFiltre.value != null ? _formatDate(controller.dateDebutFiltre.value!) : 'procurement_filter_start_date'.tr,
                                  style: TextStyle(
                                    color: controller.dateDebutFiltre.value != null ? Colors.black : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 16),
                            ],
                          ),
                        ),
                      )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => InkWell(
                        onTap: () => _selectDateFin(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  controller.dateFinFiltre.value != null ? _formatDate(controller.dateFinFiltre.value!) : 'procurement_filter_end_date'.tr,
                                  style: TextStyle(
                                    color: controller.dateFinFiltre.value != null ? Colors.black : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 16),
                            ],
                          ),
                        ),
                      )),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    controller.resetFiltres();
                    Navigator.of(context).pop();
                  },
                  child: Text('procurement_filter_reset'.tr),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('common_cancel'.tr),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    controller.appliquerFiltres();
                    Navigator.of(context).pop();
                  },
                  child: Text('procurement_filter_apply'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectDateDebut(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.dateDebutFiltre.value ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      controller.dateDebutFiltre.value = date;
    }
  }

  void _selectDateFin(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.dateFinFiltre.value ?? DateTime.now(),
      firstDate: controller.dateDebutFiltre.value ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      controller.dateFinFiltre.value = date;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
