import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';

/// Dialog pour filtrer les mouvements de stock
class MovementFilterDialog extends StatelessWidget {
  const MovementFilterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryGetxController>();

    return AlertDialog(
      title: const Text('Filtrer les mouvements'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtre par type de mouvement
            const Text(
              'Type de mouvement',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: controller.movementTypeFilter.value,
                  hint: const Text('Tous les types'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tous les types')),
                    DropdownMenuItem(value: 'achat', child: Text('Achat')),
                    DropdownMenuItem(value: 'vente', child: Text('Vente')),
                    DropdownMenuItem(value: 'ajustement', child: Text('Ajustement')),
                    DropdownMenuItem(value: 'retour', child: Text('Retour')),
                    DropdownMenuItem(value: 'approvisionnement', child: Text('Approvisionnement')),
                  ],
                  onChanged: (value) {
                    controller.movementTypeFilter.value = value;
                  },
                )),

            const SizedBox(height: 16),

            // Filtre par période
            const Text(
              'Période',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Date de début
            Obx(() => TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date de début',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: controller.dateDebutFilter.value != null
                        ? _formatDate(controller.dateDebutFilter.value!)
                        : '',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: controller.dateDebutFilter.value ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.dateDebutFilter.value = date;
                    }
                  },
                )),

            const SizedBox(height: 12),

            // Date de fin
            Obx(() => TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date de fin',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: controller.dateFinFilter.value != null
                        ? _formatDate(controller.dateFinFilter.value!)
                        : '',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: controller.dateFinFilter.value ?? DateTime.now(),
                      firstDate: controller.dateDebutFilter.value ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.dateFinFilter.value = date;
                    }
                  },
                )),

            const SizedBox(height: 16),

            // Boutons de période rapide
            const Text(
              'Périodes rapides',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildQuickPeriodChip(
                  'Aujourd\'hui',
                  () => _setQuickPeriod(controller, 0),
                ),
                _buildQuickPeriodChip(
                  '7 derniers jours',
                  () => _setQuickPeriod(controller, 7),
                ),
                _buildQuickPeriodChip(
                  '30 derniers jours',
                  () => _setQuickPeriod(controller, 30),
                ),
                _buildQuickPeriodChip(
                  'Ce mois',
                  () => _setCurrentMonth(controller),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Effacer les filtres de mouvement
            controller.movementTypeFilter.value = null;
            controller.dateDebutFilter.value = null;
            controller.dateFinFilter.value = null;
            controller.loadMovements(refresh: true);
            Get.back();
          },
          child: const Text('Effacer'),
        ),
        ElevatedButton(
          onPressed: () {
            // Appliquer les filtres
            controller.loadMovements(refresh: true);
            Get.back();
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  /// Construit un chip pour les périodes rapides
  Widget _buildQuickPeriodChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: onTap,
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
    );
  }

  /// Définit une période rapide (nombre de jours depuis aujourd'hui)
  void _setQuickPeriod(InventoryGetxController controller, int days) {
    final now = DateTime.now();
    if (days == 0) {
      // Aujourd'hui
      controller.dateDebutFilter.value = DateTime(now.year, now.month, now.day);
      controller.dateFinFilter.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      // X derniers jours
      controller.dateDebutFilter.value = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
      controller.dateFinFilter.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  /// Définit le mois courant
  void _setCurrentMonth(InventoryGetxController controller) {
    final now = DateTime.now();
    controller.dateDebutFilter.value = DateTime(now.year, now.month, 1);
    controller.dateFinFilter.value = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}