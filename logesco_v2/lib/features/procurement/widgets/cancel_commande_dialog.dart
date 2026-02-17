/**
 * Dialog pour l'annulation d'une commande d'approvisionnement
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          const Text('Annuler la commande'),
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
                    'Commande: ${commande.numeroCommande}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Fournisseur: ${commande.fournisseur?.nom ?? 'N/A'}'),
                  Text('Date: ${_formatDate(commande.dateCommande)}'),
                  if (commande.montantTotal != null)
                    Text(
                      'Montant: ${commande.montantTotal!.toStringAsFixed(0)} FCFA',
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
                  const Expanded(
                    child: Text(
                      'Attention: Cette action est irréversible',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Conséquences de l'annulation
            const Text(
              'Conséquences de l\'annulation:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            _buildConsequenceItem(
              Icons.block,
              'La commande ne pourra plus être modifiée',
              Colors.red,
            ),
            _buildConsequenceItem(
              Icons.inventory_2_outlined,
              'Aucune réception ne sera possible',
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
                    const Expanded(
                      child: Text(
                        'Cette commande a déjà des réceptions partielles. Les stocks déjà reçus ne seront pas affectés.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            const Text(
              'Êtes-vous sûr de vouloir annuler cette commande ?',
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
          child: const Text('Non, garder la commande'),
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
                  : const Text('Oui, annuler'),
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
      Get.snackbar(
        'Erreur',
        'Une commande terminée ne peut pas être annulée',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return;
    }

    if (commande.statut == CommandeStatut.annulee) {
      Get.snackbar(
        'Information',
        'Cette commande est déjà annulée',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Demander une confirmation finale
    final finalConfirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmation finale'),
        content: const Text(
          'Cette action est définitive. Voulez-vous vraiment annuler cette commande ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler définitivement'),
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
