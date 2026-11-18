import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../products/controllers/expiration_date_controller.dart';
import '../../products/models/expiration_date.dart';
import '../../boutiques/controllers/boutique_controller.dart';

/// Vue de l'onglet Péremptions dans le module inventaire
///
/// MISE À JOUR : L'isolation par boutique est maintenant fonctionnelle
/// avec le champ boutiqueId dans la table DatePeremption.
/// Les données sont automatiquement filtrées par boutique active.
class ExpirationTabView extends StatefulWidget {
  const ExpirationTabView({super.key});

  @override
  State<ExpirationTabView> createState() => _ExpirationTabViewState();
}

class _ExpirationTabViewState extends State<ExpirationTabView> {
  late ExpirationDateController controller;
  late BoutiqueController boutiqueController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ExpirationDateController());

    // Obtenir le contrôleur de boutique s'il existe
    if (Get.isRegistered<BoutiqueController>()) {
      boutiqueController = Get.find<BoutiqueController>();

      // Écouter les changements de boutique active
      ever(boutiqueController.boutiquesActive, (_) {
        // Recharger les données quand la boutique change
        controller.loadAlerts();
      });
    }

    // Charger les alertes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
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
    final cards = <Widget>[
      _buildStatCard('stock_expiration_total_alerts'.tr, stats.totalAlertes.toString(), Icons.warning_amber, Colors.orange),
      _buildStatCard('stock_expiration_expired'.tr, stats.perimes.toString(), Icons.cancel, Colors.red),
      _buildStatCard('stock_expiration_critical'.tr, stats.critiques.toString(), Icons.error, Colors.deepOrange),
      _buildStatCard('stock_expiration_total_value'.tr, '${stats.valeurTotale.toStringAsFixed(0)} FCFA', Icons.attach_money, Colors.blue),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        // Écran étroit (mobile) : grille 2 x 2 au lieu de 4 colonnes écrasées
        final columns = constraints.maxWidth < 600 ? 2 : 4;
        final available = constraints.maxWidth - 32; // padding horizontal du conteneur
        final cardWidth = (available - spacing * (columns - 1)) / columns;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final card in cards) SizedBox(width: cardWidth, child: card),
            ],
          ),
        );
      },
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
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
    final search = TextField(
      decoration: InputDecoration(
        hintText: 'stock_expiration_search_hint'.tr,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: controller.updateSearch,
    );

    Widget filterDropdown() => Obx(() => DropdownButton<String>(
          value: controller.selectedFilter.value,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: 'all', child: Text('stock_expiration_filter_all'.tr)),
            DropdownMenuItem(value: 'expired', child: Text('stock_expiration_filter_expired'.tr)),
            DropdownMenuItem(value: 'critical', child: Text('stock_expiration_filter_critical'.tr)),
            DropdownMenuItem(value: 'warning', child: Text('stock_expiration_filter_warning'.tr)),
          ],
          onChanged: (value) {
            if (value != null) controller.setFilter(value);
          },
        ));

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 500;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [search, const SizedBox(height: 8), filterDropdown()],
                )
              : Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 12),
                    SizedBox(width: 180, child: filterDropdown()),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildExpirationCard(ExpirationDate date, ExpirationDateController controller) {
    final alertColor = _getColorFromHex(date.getAlertColor());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: alertColor.withValues(alpha: 0.3), width: 2),
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
                    PopupMenuItem(
                      value: 'exhausted',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18),
                          SizedBox(width: 8),
                          Text('expiration_list_mark_exhausted'.tr),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('suppliers_delete'.tr, style: TextStyle(color: Colors.red)),
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

            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text('inventory_unites'.trParams({'quantite': '${date.quantite}'}), style: const TextStyle(fontSize: 14)),
                  ],
                ),
                if (date.numeroLot != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text('inventory_lot'.trParams({'numeroLot': '${date.numeroLot}'}), style: const TextStyle(fontSize: 14)),
                    ],
                  ),
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
    // Défilable : sur un petit écran la colonne dépassait la zone disponible
    // (bandeau « BOTTOM OVERFLOWED »).
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'stock_expiration_no_alerts'.tr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'stock_expiration_all_good'.tr,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmMarkAsExhausted(ExpirationDate date, ExpirationDateController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('stock_expiration_mark_exhausted'.tr),
        content: Text('stock_expiration_confirm_exhausted'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.markAsExhausted(date.id);
            },
            child: Text('common_confirm'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ExpirationDate date, ExpirationDateController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('common_delete'.tr),
        content: Text('stock_expiration_confirm_delete'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.deleteExpirationDate(date.id);
            },
            child: Text('common_delete'.tr),
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
