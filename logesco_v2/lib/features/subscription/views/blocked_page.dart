import 'package:flutter/material.dart';
import '../models/subscription_status.dart';
import '../models/license_data.dart';
import 'license_activation_page.dart';

/// Page affichée quand l'abonnement est expiré et l'application bloquée
class SubscriptionBlockedPage extends StatelessWidget {
  final SubscriptionStatus? status;
  final bool isInGracePeriod;

  const SubscriptionBlockedPage({
    super.key,
    this.status,
    this.isInGracePeriod = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône d'erreur
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  size: 60,
                  color: Colors.red.shade600,
                ),
              ),

              const SizedBox(height: 32),

              // Titre principal
              Text(
                isInGracePeriod ? 'Période de grâce active' : 'Abonnement expiré',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Message principal
              Text(
                _getMainMessage(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.red.shade600,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Détails de l'abonnement
              if (status != null) _buildStatusCard(context),

              const SizedBox(height: 32),

              // Actions
              _buildActionButtons(context),

              const SizedBox(height: 24),

              // Message d'aide
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Besoin d\'aide ? Contactez notre support technique pour toute question concernant votre abonnement.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de l\'abonnement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Type',
            _getSubscriptionTypeLabel(status!.type),
            Icons.card_membership,
          ),
          const SizedBox(height: 12),
          if (status!.expirationDate != null)
            _buildDetailRow(
              'Date d\'expiration',
              _formatDate(status!.expirationDate!),
              Icons.calendar_today,
            ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Statut',
            isInGracePeriod ? 'Période de grâce' : 'Expiré',
            Icons.info_outline,
            valueColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton principal d'activation
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LicenseActivationPage(),
                ),
              );
            },
            icon: const Icon(Icons.vpn_key),
            label: const Text('Activer une licence'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bouton secondaire (seulement en période de grâce)
        if (isInGracePeriod)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Retourner à l'application en mode dégradé
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Continuer en mode consultation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade600),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  String _getMainMessage() {
    if (isInGracePeriod) {
      return 'Votre abonnement a expiré mais vous bénéficiez d\'une période de grâce de 3 jours. Vous pouvez continuer à consulter vos données mais les modifications sont limitées.';
    } else {
      return 'Votre abonnement a expiré. Pour continuer à utiliser l\'application, veuillez activer une nouvelle licence.';
    }
  }

  String _getSubscriptionTypeLabel(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return 'Période d\'essai';
      case SubscriptionType.monthly:
        return 'Mensuel';
      case SubscriptionType.annual:
        return 'Annuel';
      case SubscriptionType.lifetime:
        return 'Vie entière';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
