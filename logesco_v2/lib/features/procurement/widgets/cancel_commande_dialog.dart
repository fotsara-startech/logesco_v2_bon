/**
 * Dialog pour l'annulation d'une commande d'approvisionnement
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../models/procurement_models.dart';
import '../controllers/procurement_controller.dart';

class CancelCommandeDialog extends StatelessWidget {
  final CommandeApprovisionnement commande;
  final ProcurementController controller;

  const CancelCommandeDialog({
    Key? key,
    required this.commande,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red[700]),
          const SizedBox(width: 8),
          Text('procurement_annuler_commande'.tr),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de la commande
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'procurement_commande'.trParams({'numeroCommande': '${commande.numeroCommande}'}),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('procurement_supplier_label'.trParams({'nom': commande.fournisseur?.nom ?? 'N/A'})),
                  Text('procurement_date_2'.trParams({'dateCommande': '${_formatDate(commande.dateCommande)}'})),
                  if (commande.montantTotal != null)
                    Text(
                      'procurement_montant_fcfa'.trParams({'toStringAsFixed': '${commande.montantTotal!.toStringAsFixed(0)}'}),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Message d'avertissement
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'procurement_attention_action_est_irreversible'.tr,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Conséquences de l'annulation
            Text(
              'procurement_consequences_annulation'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            _buildConsequenceItem(
              Icons.block,
              'procurement_commande_ne_pourra_plus_etre_modifiee'.tr,
              Colors.red,
            ),
            _buildConsequenceItem(
              Icons.inventory_2_outlined,
              'procurement_aucune_reception_ne_sera_possible'.tr,
              Colors.red,
            ),

            // Vérifier s'il y a déjà des réceptions
            if (_hasPartialReception()) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'procurement_commande_deja_receptions_partielles_stocks_deja'.tr,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            Text(
              'procurement_etestes_vous_sur_vouloir_annuler_commande'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('procurement_non_garder_commande'.tr),
        ),
        Obx(() => ElevatedButton(
              onPressed: controller.isUpdating.value ? null : _handleCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: controller.isUpdating.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('sales_yes_cancel'.tr),
            )),
      ],
    );
  }

  Widget _buildConsequenceItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasPartialReception() {
    return commande.details.any((detail) => detail.quantiteRecue > 0);
  }

  Future<void> _handleCancel() async {
    // Vérifier si la commande peut être annulée
    if (commande.statut == CommandeStatut.terminee) {
      SnackbarHelper.error('procurement_commande_terminee_ne_peut_pas_etre'.tr);
      return;
    }

    if (commande.statut == CommandeStatut.annulee) {
      SnackbarHelper.info('procurement_commande_est_deja_annulee'.tr, title: 'Information');
      return;
    }

    // Demander une confirmation finale
    final finalConfirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmation finale'),
        content: Text(
          'procurement_action_est_definitive_voulez_vous_vraiment'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('plain_no'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('procurement_oui_annuler_definitivement'.tr),
          ),
        ],
      ),
    );

    if (finalConfirm == true) {
      final success = await controller.annulerCommande(commande.id);

      if (success) {
        Get.back(); // Fermer le dialog d'annulation
        Get.back(); // Fermer le dialog principal si nécessaire
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
