/**
 * Dialog pour afficher les détails complets d'une commande d'approvisionnement
 */

import 'package:flutter/material.dart';
import '../models/procurement_models.dart';
import '../controllers/procurement_controller.dart';
import 'receive_commande_dialog.dart';
import 'cancel_commande_dialog.dart';

class CommandeDetailsDialog extends StatelessWidget {
  final CommandeApprovisionnement commande;
  final ProcurementController controller;

  const CommandeDetailsDialog({
    Key? key,
    required this.commande,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande ${commande.numeroCommande}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatutChip(commande.statut),
                    ],
                  ),
                ),

                // Boutons d'action
                if (commande.peutEtreReceptionnee) ...[
                  ElevatedButton.icon(
                    onPressed: () => _showReceptionDialog(context),
                    icon: const Icon(Icons.inventory),
                    label: const Text('Réceptionner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                if (commande.peutEtreModifiee) ...[
                  ElevatedButton.icon(
                    onPressed: () => _showCancelDialog(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const Divider(height: 32),

            // Contenu principal
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne de gauche - Informations générales
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoSection(context),
                          const SizedBox(height: 16),
                          if (commande.statistiques != null) _buildStatistiquesSection(context),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Colonne de droite - Détails des produits
                  Expanded(
                    flex: 2,
                    child: _buildProduitsSection(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutChip(CommandeStatut statut) {
    Color backgroundColor;
    Color textColor;

    switch (statut) {
      case CommandeStatut.enAttente:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange[800]!;
        break;
      case CommandeStatut.partielle:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue[800]!;
        break;
      case CommandeStatut.terminee:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green[800]!;
        break;
      case CommandeStatut.annulee:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statut.label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, 'Fournisseur', commande.fournisseur?.nom ?? 'N/A'),
            _buildInfoRow(Icons.calendar_today, 'Date commande', _formatDate(commande.dateCommande)),
            _buildInfoRow(Icons.local_shipping, 'Livraison prévue', commande.dateLivraisonPrevue != null ? _formatDate(commande.dateLivraisonPrevue!) : 'Non définie'),
            _buildInfoRow(Icons.payment, 'Mode de paiement', commande.modePaiement.label),
            _buildInfoRow(Icons.attach_money, 'Montant total', commande.montantTotal != null ? '${_formatCurrency(commande.montantTotal!)} FCFA' : 'N/A'),
            if (commande.notes != null && commande.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(commande.notes!),
                      ],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiquesSection(BuildContext context) {
    final stats = commande.statistiques!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques de réception',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildProgressInfo(
              'Réception globale',
              stats.pourcentageReception,
              '${stats.totalQuantiteRecue}/${stats.totalQuantiteCommandee} unités',
            ),
            const SizedBox(height: 12),
            _buildProgressInfo(
              'Produits complets',
              stats.nombreProduits > 0 ? (stats.produitsCompletsRecus * 100 / stats.nombreProduits).round() : 0,
              '${stats.produitsCompletsRecus}/${stats.nombreProduits} produits',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo(String label, int percentage, String details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage == 100 ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          details,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProduitsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails des produits (${commande.details.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: commande.details.length,
                itemBuilder: (context, index) {
                  final detail = commande.details[index];
                  return _buildProduitCard(detail);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitCard(DetailCommandeApprovisionnement detail) {
    final progressPercentage = detail.quantiteCommandee > 0 ? (detail.quantiteRecue * 100 / detail.quantiteCommandee).round() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du produit
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.produit?.nom ?? 'Produit inconnu',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (detail.produit?.reference != null)
                        Text(
                          'Réf: ${detail.produit!.reference}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Statut de réception
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: detail.estComplete ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    detail.estComplete ? 'Complet' : 'En cours',
                    style: TextStyle(
                      color: detail.estComplete ? Colors.green[800] : Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations de quantité
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Commandé: ${detail.quantiteCommandee}', style: const TextStyle(fontSize: 13)),
                      Text('Reçu: ${detail.quantiteRecue}', style: const TextStyle(fontSize: 13)),
                      Text('Restant: ${detail.quantiteRestante}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange[700])),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Coût unitaire: ${_formatCurrency(detail.coutUnitaire)} FCFA', style: const TextStyle(fontSize: 13)),
                      Text('Total: ${_formatCurrency(detail.coutTotal)} FCFA', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Barre de progression
            LinearProgressIndicator(
              value: progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                detail.estComplete ? Colors.green : Colors.blue,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '$progressPercentage% reçu',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReceiveCommandeDialog(
        commande: commande,
        controller: controller,
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CancelCommandeDialog(
        commande: commande,
        controller: controller,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = amount.toStringAsFixed(0);
    return result.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
  }
}
