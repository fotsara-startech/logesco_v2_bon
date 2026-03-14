/**
 * Dialog pour la réception d'une commande d'approvisionnement
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/procurement_models.dart';
import '../controllers/procurement_controller.dart';

class ReceiveCommandeDialog extends StatefulWidget {
  final CommandeApprovisionnement commande;
  final ProcurementController controller;

  const ReceiveCommandeDialog({
    Key? key,
    required this.commande,
    required this.controller,
  }) : super(key: key);

  @override
  State<ReceiveCommandeDialog> createState() => _ReceiveCommandeDialogState();
}

class _ReceiveCommandeDialogState extends State<ReceiveCommandeDialog> {
  final Map<int, TextEditingController> _quantityControllers = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les quantités restantes
    for (final detail in widget.commande.details) {
      _quantityControllers[detail.id] = TextEditingController(
        text: detail.quantiteRestante.toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'procurement_receive'.tr + ' ' + 'procurement_orders'.tr.toLowerCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const Divider(height: 32),

              // Informations de la commande
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'procurement_order'.tr}: ${widget.commande.numeroCommande}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('${'procurement_supplier'.tr}: ${widget.commande.fournisseur?.nom ?? 'N/A'}'),
                    Text('${'procurement_date'.tr}: ${_formatDate(widget.commande.dateCommande)}'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'procurement_products_to_receive'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              // Liste des produits
              Expanded(
                child: ListView.builder(
                  itemCount: widget.commande.details.length,
                  itemBuilder: (context, index) {
                    final detail = widget.commande.details[index];

                    // Ne pas afficher les produits déjà complètement reçus
                    if (detail.quantiteRestante <= 0) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom du produit
                            Text(
                              detail.produit?.nom ?? 'Produit inconnu',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Référence
                            if (detail.produit?.reference != null)
                              Text(
                                'Réf: ${detail.produit!.reference}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),

                            const SizedBox(height: 8),

                            // Informations de quantité
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Commandé: ${detail.quantiteCommandee}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Déjà reçu: ${detail.quantiteRecue}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Restant: ${detail.quantiteRestante}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Champ de saisie de quantité
                                SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    controller: _quantityControllers[detail.id],
                                    decoration: InputDecoration(
                                      labelText: 'procurement_qty_received'.tr,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requis';
                                      }
                                      final quantity = int.tryParse(value);
                                      if (quantity == null || quantity < 0) {
                                        return 'Nombre invalide';
                                      }
                                      if (quantity > detail.quantiteRestante) {
                                        return 'Max: ${detail.quantiteRestante}';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('common_cancel'.tr),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => ElevatedButton(
                        onPressed: widget.controller.isUpdating.value ? null : _handleReceive,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: widget.controller.isUpdating.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text('procurement_receive_action'.tr),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReceive() async {
    if (!_formKey.currentState!.validate()) return;

    // Préparer les détails de réception
    final details = <Map<String, dynamic>>[];

    for (final detail in widget.commande.details) {
      if (detail.quantiteRestante <= 0) continue;

      final controller = _quantityControllers[detail.id];
      if (controller == null) continue;

      final quantiteRecue = int.tryParse(controller.text) ?? 0;
      if (quantiteRecue > 0) {
        details.add({
          'detailId': detail.id,
          'quantiteRecue': quantiteRecue,
        });
      }
    }

    if (details.isEmpty) {
      Get.snackbar(
        'Attention',
        'Aucune quantité à réceptionner',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Confirmer la réception
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('procurement_confirm_reception'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('procurement_confirm_reception_message'.tr),
            const SizedBox(height: 8),
            Text(
              '${details.length} produit(s) seront réceptionnés.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette action mettra à jour automatiquement les stocks.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('common_confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.controller.recevoirCommande(
        widget.commande.id,
        details,
      );

      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
