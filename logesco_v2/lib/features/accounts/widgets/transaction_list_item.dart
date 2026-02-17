import 'package:flutter/material.dart';
import '../models/account.dart';
import '../../../shared/constants/constants.dart';

/// Widget pour afficher un élément de transaction dans une liste
class TransactionListItem extends StatelessWidget {
  final TransactionCompte transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône du type de transaction
            _buildTransactionIcon(),

            const SizedBox(width: 12),

            // Détails de la transaction
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type et montant
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          transaction.libelleFormate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyConstants.formatAmountWithSign(transaction.montant, transaction.augmenteSolde),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: transaction.augmenteSolde ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Description si disponible
                  if (transaction.description != null && transaction.description!.isNotEmpty)
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // Date et solde après transaction
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(transaction.dateTransaction),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Solde: ${CurrencyConstants.formatAmount(transaction.soldeApres)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Référence si disponible
                  if (transaction.referenceType != null && transaction.referenceId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Réf: ${transaction.referenceType} #${transaction.referenceId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'icône du type de transaction
  Widget _buildTransactionIcon() {
    IconData icon;
    Color backgroundColor;
    Color iconColor;

    // Icônes spécifiques pour les transactions liées à des ventes
    if (transaction.isLinkedToSale) {
      if (transaction.typeTransactionDetail == 'paiement_vente') {
        icon = Icons.receipt;
        backgroundColor = Colors.blue.withOpacity(0.1);
        iconColor = Colors.blue;
      } else if (transaction.typeTransactionDetail == 'paiement_dette') {
        icon = Icons.payment;
        backgroundColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
      } else if (transaction.typeTransactionDetail == 'vente_credit') {
        icon = Icons.shopping_cart;
        backgroundColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
      } else {
        icon = Icons.receipt_long;
        backgroundColor = Colors.purple.withOpacity(0.1);
        iconColor = Colors.purple;
      }
    } else {
      // Icônes par défaut pour les anciennes transactions
      switch (transaction.typeTransaction) {
        case 'paiement':
          icon = Icons.payment;
          backgroundColor = Colors.green.withOpacity(0.1);
          iconColor = Colors.green;
          break;
        case 'credit':
          icon = Icons.add_circle;
          backgroundColor = Colors.blue.withOpacity(0.1);
          iconColor = Colors.blue;
          break;
        case 'debit':
          icon = Icons.remove_circle;
          backgroundColor = Colors.orange.withOpacity(0.1);
          iconColor = Colors.orange;
          break;
        case 'achat':
          icon = Icons.shopping_cart;
          backgroundColor = Colors.purple.withOpacity(0.1);
          iconColor = Colors.purple;
          break;
        default:
          icon = Icons.swap_horiz;
          backgroundColor = Colors.grey.withOpacity(0.1);
          iconColor = Colors.grey;
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
    );
  }

  /// Formate la date et l'heure
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Aujourd'hui - afficher l'heure
      return 'Aujourd\'hui ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Hier
      return 'Hier ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // Cette semaine
      final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return '${weekdays[dateTime.weekday - 1]} ${dateTime.day}/${dateTime.month}';
    } else {
      // Plus ancien
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';
    }
  }
}
