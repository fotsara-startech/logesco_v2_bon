import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/subscription_status.dart';
import '../models/license_data.dart';
import 'license_activation_page.dart';

/// Dialog de notification d'expiration d'abonnement
class ExpirationNotificationDialog extends StatelessWidget {
  final SubscriptionStatus status;
  final bool isUrgent;

  const ExpirationNotificationDialog({
    super.key,
    required this.status,
    this.isUrgent = false,
  });

  /// Affiche le dialog de notification d'expiration
  static Future<void> show(BuildContext context, SubscriptionStatus status, {bool isUrgent = false}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isUrgent, // Ne peut pas être fermé si urgent
      builder: (context) => ExpirationNotificationDialog(
        status: status,
        isUrgent: isUrgent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingDays = status.remainingDays ?? 0;
    final isExpiringSoon = remainingDays <= 1;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            isExpiringSoon ? Icons.warning : Icons.info,
            color: isExpiringSoon ? Colors.red : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpiringSoon ? 'Expiration imminente' : 'Renouvellement recommandé',
              style: TextStyle(
                color: isExpiringSoon ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message principal
          Text(
            _getMainMessage(),
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 16),

          // Détails de l'abonnement
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', _getSubscriptionTypeLabel()),
                const SizedBox(height: 8),
                if (status.expirationDate != null) _buildDetailRow('subscription_expires_on'.tr, _formatDate(status.expirationDate!)),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Jours restants',
                  '$remainingDays jour${remainingDays > 1 ? 's' : ''}',
                  textColor: _getRemainingDaysColor(remainingDays),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Message d'action
          Text(
            _getActionMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
      actions: [
        // Bouton "Plus tard" (seulement si pas urgent)
        if (!isUrgent)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('subscription_later'.tr),
          ),

        // Bouton "Activer une licence"
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LicenseActivationPage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isExpiringSoon ? Colors.red : Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text('subscription_activate_license'.tr),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String _getMainMessage() {
    final remainingDays = status.remainingDays ?? 0;

    if (remainingDays == 0) {
      return status.type == SubscriptionType.trial ? 'subscription_trial_expires_today'.tr : 'subscription_expires_today'.tr;
    } else if (remainingDays == 1) {
      return status.type == SubscriptionType.trial ? 'subscription_trial_expires_tomorrow'.tr : 'subscription_expires_tomorrow'.tr;
    } else {
      final key = status.type == SubscriptionType.trial ? 'subscription_trial_expires_in_days' : 'subscription_expires_in_days';
      return key.trParams({'days': remainingDays.toString()});
    }
  }

  String _getActionMessage() {
    final remainingDays = status.remainingDays ?? 0;

    if (remainingDays <= 1) {
      return 'subscription_activate_now'.tr;
    } else {
      return 'subscription_renew_recommended'.tr;
    }
  }

  String _getSubscriptionTypeLabel() {
    switch (status.type) {
      case SubscriptionType.trial:
        return 'subscription_type_trial'.tr;
      case SubscriptionType.monthly:
        return 'subscription_type_monthly'.tr;
      case SubscriptionType.annual:
        return 'subscription_type_annual'.tr;
      case SubscriptionType.lifetime:
        return 'subscription_type_lifetime'.tr;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getRemainingDaysColor(int days) {
    if (days <= 1) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.green;
  }
}
