import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../products/controllers/expiration_date_controller.dart';
import '../../products/models/expiration_date.dart';

/// Vue de l'onglet Péremptions dans le module inventaire
class ExpirationTabView extends StatelessWidget {
  const ExpirationTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExpirationDateController());

    // Charger les alertes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAlerts();
    });

    return Column(
      children: [
        // Statistiques
        Obx(() {
          final stats = controller.alertStats.value;
          if (stats != null) {
            return _buildStatsCards(stats);
          }
          return const SizedBox.shrink();
        }),

        const SizedBox(height: 16),

        // Filtres
        _buildFilters(controller),

        const SizedBox(height: 16),

        // Liste des dates
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final dates = controller.filteredDates;

            if (dates.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadAlerts(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: dates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildExpirationCard(dates[index], controller);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatsCards(ExpirationAlertStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total alertes',
              stats.totalAlertes.toString(),
              Icons.warning_amber,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Périmés',
              stats.perimes.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Critiques',
              stats.critiques.toString(),
              Icons.error,
              Colors.deepOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Valeur totale',
              '${stats.valeurTotale.toStringAsFixed(0)} FCFA',
              Icons.attach_money,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ExpirationDateController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit ou lot...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: controller.updateSearch,
            ),
          ),
          const SizedBox(width: 12),
          Obx(() => DropdownButton<String>(
                value: controller.selectedFilter.value,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous')),
                  DropdownMenuItem(value: 'expired', child: Text('Périmés')),
                  DropdownMenuItem(value: 'critical', child: Text('Critiques')),
                  DropdownMenuItem(value: 'warning', child: Text('Avertissements')),
                ],
                onChanged: (value) {
                  if (value != null) controller.setFilter(value);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildExpirationCard(ExpirationDate date, ExpirationDateController controller) {
    final alertColor = _getColorFromHex(date.getAlertColor());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: alertColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Badge de niveau d'alerte
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: alertColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    date.getAlertLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                // Menu d'actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'exhausted':
                        _confirmMarkAsExhausted(date, controller);
                        break;
                      case 'delete':
                        _confirmDelete(date, controller);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'exhausted',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18),
                          SizedBox(width: 8),
                          Text('Marquer épuisé'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nom du produit
            if (date.produit != null) ...[
              Text(
                date.produit!.nom,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Réf: ${date.produit!.reference}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Informations de péremption
            Row(
              children: [
                Icon(Icons.event, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Expire le ${DateFormat('dd/MM/yyyy').format(date.datePeremption)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  date.getStatusDescription(),
                  style: TextStyle(
                    fontSize: 14,
                    color: alertColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.inventory_2, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${date.quantite} unités',
                  style: const TextStyle(fontSize: 14),
                ),
                if (date.numeroLot != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.qr_code, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Lot: ${date.numeroLot}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),

            if (date.notes != null && date.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucune alerte de péremption',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous vos produits sont en bon état',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _confirmMarkAsExhausted(ExpirationDate date, ExpirationDateController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Marquer comme épuisé'),
        content: const Text('Voulez-vous marquer ce lot comme épuisé ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.markAsExhausted(date.id);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ExpirationDate date, ExpirationDateController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cette date de péremption ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.deleteExpirationDate(date.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
