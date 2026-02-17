import 'package:flutter/material.dart';
import '../models/account.dart';
import '../../../shared/constants/constants.dart';

/// Widget de carte pour afficher un compte client
class CompteClientCard extends StatelessWidget {
  final CompteClient compte;
  final VoidCallback? onTap;

  const CompteClientCard({
    super.key,
    required this.compte,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom du client et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          compte.client.nomComplet,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (compte.client.telephone != null)
                          Text(
                            compte.client.telephone!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),

              const SizedBox(height: 12),

              // Informations financières
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialInfo(
                      label: 'Solde actuel',
                      value: CurrencyConstants.formatAmount(compte.soldeActuel),
                      color: compte.soldeActuel > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildFinancialInfo(
                      label: 'Limite crédit',
                      value: CurrencyConstants.formatAmount(compte.limiteCredit),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Crédit disponible
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialInfo(
                      label: 'Crédit disponible',
                      value: CurrencyConstants.formatAmount(compte.creditDisponible),
                      color: compte.creditDisponible > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildFinancialInfo(
                      label: 'Dernière MAJ',
                      value: _formatDate(compte.dateDerniereMaj),
                      color: Colors.grey[600]!,
                    ),
                  ),
                ],
              ),

              // Barre de progression du crédit
              if (compte.limiteCredit > 0) ...[
                const SizedBox(height: 12),
                _buildCreditProgressBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construit le chip de statut
  Widget _buildStatusChip() {
    if (compte.estEnDepassement) {
      return Chip(
        label: const Text(
          'DÉPASSEMENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    } else if (compte.soldeActuel > 0) {
      return Chip(
        label: const Text(
          'DETTE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    } else {
      return Chip(
        label: const Text(
          'OK',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
  }

  /// Construit une information financière
  Widget _buildFinancialInfo({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Construit la barre de progression du crédit
  Widget _buildCreditProgressBar() {
    final pourcentageUtilise = compte.limiteCredit > 0 ? (compte.soldeActuel / compte.limiteCredit).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (pourcentageUtilise >= 1.0) {
      barColor = Colors.red;
    } else if (pourcentageUtilise >= 0.8) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Utilisation du crédit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${(pourcentageUtilise * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pourcentageUtilise,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
        ),
      ],
    );
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
