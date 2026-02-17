import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/expiration_date_controller.dart';
import '../models/expiration_date.dart';
import '../services/expiration_date_service.dart';
import 'expiration_date_dialog.dart';

/// Widget pour afficher la liste des dates de péremption d'un produit
class ExpirationDatesListWidget extends StatefulWidget {
  final int produitId;
  final bool gestionPeremption;

  const ExpirationDatesListWidget({
    super.key,
    required this.produitId,
    required this.gestionPeremption,
  });

  @override
  State<ExpirationDatesListWidget> createState() => _ExpirationDatesListWidgetState();
}

class _ExpirationDatesListWidgetState extends State<ExpirationDatesListWidget> {
  final ExpirationDateService _service = ExpirationDateService();
  Map<String, dynamic>? _stats;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    if (widget.gestionPeremption) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    try {
      final stats = await _service.getProductStats(widget.produitId);
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      print('Erreur chargement stats: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.gestionPeremption) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'La gestion des dates de péremption n\'est pas activée pour ce produit',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    final controller = Get.put(ExpirationDateController());

    // Charger les dates pour ce produit une seule fois
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.expirationDates.isEmpty || !controller.expirationDates.any((d) => d.produitId == widget.produitId)) {
        controller.loadExpirationDates(produitId: widget.produitId);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête avec bouton d'ajout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dates de péremption',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context, widget.produitId, controller),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Statistiques de cohérence
        if (_stats != null) _buildStatsCard(),
        if (_stats != null) const SizedBox(height: 12),

        // Liste des dates
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final dates = controller.expirationDates.where((d) => d.produitId == widget.produitId && !d.estEpuise).toList();

          if (dates.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.blue.shade300),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune date de péremption enregistrée',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final date = dates[index];
              return _buildDateCard(context, date, controller);
            },
          );
        }),
      ],
    );
  }

  Widget _buildDateCard(BuildContext context, ExpirationDate date, ExpirationDateController controller) {
    final alertColor = _getColorFromHex(date.getAlertColor());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: alertColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Indicateur de couleur
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: alertColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(date.datePeremption),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: alertColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          date.getAlertLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: alertColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.getStatusDescription(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${date.quantite} unités',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (date.numeroLot != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.qr_code, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Lot: ${date.numeroLot}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditDialog(context, date, controller);
                    break;
                  case 'exhausted':
                    _markAsExhausted(context, date, controller);
                    break;
                  case 'delete':
                    _confirmDelete(context, date, controller);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
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
      ),
    );
  }

  void _showAddDialog(BuildContext context, int produitId, ExpirationDateController controller) {
    showDialog(
      context: context,
      builder: (context) => ExpirationDateDialog(produitId: produitId),
    ).then((_) => _loadStats()); // Recharger les stats après ajout
  }

  Widget _buildStatsCard() {
    final stockDisponible = _stats!['stockDisponible'] as int;
    final quantiteEnregistree = _stats!['quantiteEnregistree'] as int;
    final quantiteRestante = _stats!['quantiteRestante'] as int;
    final pourcentage = _stats!['pourcentageEnregistre'] as int;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Cohérence des quantités',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Stock', stockDisponible.toString(), Colors.blue),
              _buildStatItem('Enregistré', quantiteEnregistree.toString(), Colors.green),
              _buildStatItem('Restant', quantiteRestante.toString(), quantiteRestante > 0 ? Colors.orange : Colors.grey),
              _buildStatItem('Couverture', '$pourcentage%', pourcentage >= 80 ? Colors.green : Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, ExpirationDate date, ExpirationDateController controller) {
    showDialog(
      context: context,
      builder: (context) => ExpirationDateDialog(
        produitId: date.produitId,
        expirationDate: date,
      ),
    ).then((_) => _loadStats()); // Recharger les stats après modification
  }

  void _markAsExhausted(BuildContext context, ExpirationDate date, ExpirationDateController controller) {
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
              controller.markAsExhausted(date.id).then((_) => _loadStats());
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpirationDate date, ExpirationDateController controller) {
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
              controller.deleteExpirationDate(date.id).then((_) => _loadStats());
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
