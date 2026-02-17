/**
 * Widget carte pour afficher une commande d'approvisionnement
 */

import 'package:flutter/material.dart';
import '../models/procurement_models.dart';

class CommandeCard extends StatelessWidget {
  final CommandeApprovisionnement commande;
  final VoidCallback? onTap;
  final VoidCallback? onReceive;
  final VoidCallback? onCancel;
  final VoidCallback? onExportPdf;

  const CommandeCard({
    Key? key,
    required this.commande,
    this.onTap,
    this.onReceive,
    this.onCancel,
    this.onExportPdf,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      commande.numeroCommande,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildStatutChip(commande.statut),
                ],
              ),

              const SizedBox(height: 8),

              // Informations fournisseur et date
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      commande.fournisseur?.nom ?? 'Fournisseur inconnu',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(commande.dateCommande),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Statistiques de réception
              if (commande.statistiques != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressInfo(
                        'Réception',
                        commande.statistiques!.pourcentageReception,
                        '${commande.statistiques!.totalQuantiteRecue}/${commande.statistiques!.totalQuantiteCommandee}',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProgressInfo(
                        'Produits',
                        commande.statistiques!.nombreProduits > 0 ? (commande.statistiques!.produitsCompletsRecus * 100 / commande.statistiques!.nombreProduits).round() : 0,
                        '${commande.statistiques!.produitsCompletsRecus}/${commande.statistiques!.nombreProduits}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Montant et actions
              Row(
                children: [
                  if (commande.montantTotal != null) ...[
                    Text(
                      '${_formatCurrency(commande.montantTotal!)} FCFA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                  ],

                  // Boutons d'action
                  if (onExportPdf != null) ...[
                    IconButton(
                      onPressed: onExportPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      tooltip: 'Exporter en PDF',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        foregroundColor: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  if (onReceive != null) ...[
                    IconButton(
                      onPressed: onReceive,
                      icon: const Icon(Icons.inventory),
                      tooltip: 'Réceptionner',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        foregroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  if (onCancel != null) ...[
                    IconButton(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel),
                      tooltip: 'Annuler',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statut.label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage == 100 ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          details,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
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
