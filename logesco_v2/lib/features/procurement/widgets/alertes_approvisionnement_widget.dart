/**
 * Widget pour afficher les alertes d'approvisionnement
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/procurement_controller.dart';

class AlertesApprovisionnementWidget extends StatelessWidget {
  final ProcurementController controller;

  const AlertesApprovisionnementWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'procurement_alerts_title'.tr,
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

            // Statistiques
            Obx(() => _buildStatistiques(context)),

            const SizedBox(height: 16),

            // Liste des alertes
            Expanded(
              child: Obx(() {
                if (controller.alertes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Colors.green[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'procurement_no_alerts'.tr,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.green[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'procurement_all_stock_sufficient'.tr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.alertes.length,
                  itemBuilder: (context, index) {
                    final alerte = controller.alertes[index];
                    return _buildAlerteCard(context, alerte);
                  },
                );
              }),
            ),

            const Divider(),

            // Actions
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () => controller.loadAlertes(),
                  child: Text('procurement_refresh'.tr),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('common_close'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistiques(BuildContext context) {
    final alertes = controller.alertes;
    final ruptures = alertes.where((a) => a['typeAlerte'] == 'rupture').length;
    final stocksFaibles = alertes.where((a) => a['typeAlerte'] == 'stock_faible').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'procurement_alerts_total'.tr,
            alertes.length.toString(),
            Colors.orange,
            Icons.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'procurement_alerts_stockout'.tr,
            ruptures.toString(),
            Colors.red,
            Icons.error,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'procurement_alerts_low_stock'.tr,
            stocksFaibles.toString(),
            Colors.orange,
            Icons.warning_amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerteCard(BuildContext context, Map<String, dynamic> alerte) {
    final produit = alerte['produit'];
    final stock = alerte['stock'];
    final typeAlerte = alerte['typeAlerte'];
    final priorite = alerte['priorite'];

    Color couleurAlerte;
    IconData iconeAlerte;
    String messageAlerte;

    if (typeAlerte == 'rupture') {
      couleurAlerte = Colors.red;
      iconeAlerte = Icons.error;
      messageAlerte = 'procurement_stockout'.tr;
    } else {
      couleurAlerte = Colors.orange;
      iconeAlerte = Icons.warning;
      messageAlerte = 'procurement_low_stock'.tr;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleurAlerte.withOpacity(0.2),
          child: Icon(iconeAlerte, color: couleurAlerte),
        ),
        title: Text(
          produit['nom'] ?? 'Produit inconnu',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'procurement_reference'.tr}: ${produit['reference'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${'procurement_stock'.tr}: '),
                Text(
                  stock != null ? '${stock['quantiteDisponible']}' : '0',
                  style: TextStyle(
                    color: couleurAlerte,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(' / ${'procurement_threshold'.tr}: ${produit['seuilStockMinimum'] ?? 0}'),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: couleurAlerte.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                messageAlerte,
                style: TextStyle(
                  color: couleurAlerte,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${'procurement_priority'.tr}: $priorite',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Naviguer vers la création d'une commande pour ce produit
          Get.snackbar(
            'Info',
            'Création de commande pour ${produit['nom']} à implémenter',
          );
        },
      ),
    );
  }
}
