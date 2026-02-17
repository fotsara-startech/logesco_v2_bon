import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../services/notification_service.dart';
import '../views/expiration_notification_dialog.dart';
import '../views/blocked_page.dart';
import '../views/degraded_mode_banner.dart';
import '../widgets/subscription_guard.dart';

/// Exemple d'utilisation des écrans de notification et blocage
/// Implémente la tâche 7.3 : Créer les écrans de notification et blocage
class NotificationUsageExample extends StatefulWidget {
  const NotificationUsageExample({super.key});

  @override
  State<NotificationUsageExample> createState() => _NotificationUsageExampleState();
}

class _NotificationUsageExampleState extends State<NotificationUsageExample> with SubscriptionAwarePage {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple Notifications'),
      ),
      body: SubscriptionGuard(
        requireActiveSubscription: false,
        allowGracePeriod: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExampleSection(
                'Notifications d\'expiration',
                'Affichage automatique des pop-ups selon les requirements 6.1, 6.2, 6.3',
                [
                  _buildExampleButton(
                    'Notification 3 jours avant',
                    'Simule une notification d\'avertissement',
                    () => _showWarningNotification(),
                  ),
                  _buildExampleButton(
                    'Notification urgente (1 jour)',
                    'Simule une notification urgente',
                    () => _showUrgentNotification(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildExampleSection(
                'Écrans de blocage',
                'Affichage selon requirement 1.3 - blocage après expiration',
                [
                  _buildExampleButton(
                    'Écran blocage complet',
                    'Abonnement expiré sans période de grâce',
                    () => _showBlockedScreen(false),
                  ),
                  _buildExampleButton(
                    'Écran période de grâce',
                    'Abonnement expiré avec période de grâce',
                    () => _showBlockedScreen(true),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildExampleSection(
                'Mode dégradé',
                'Interface avec accès limité selon requirements 6.4',
                [
                  _buildProtectedAction(
                    'Action protégée (strict)',
                    'Nécessite un abonnement actif',
                    requireActive: true,
                  ),
                  _buildProtectedAction(
                    'Action consultation',
                    'Autorisée en période de grâce',
                    requireActive: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStatusInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleSection(String title, String description, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildExampleButton(String title, String subtitle, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectedAction(String title, String subtitle, {required bool requireActive}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SubscriptionProtectedAction(
        requireActiveSubscription: requireActive,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action "$title" exécutée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    final controller = Get.find<SubscriptionController>();

    return Obx(() {
      final status = controller.currentStatus;

      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statut actuel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (status != null) ...[
                _buildInfoRow('Actif', status.isActive ? 'Oui' : 'Non'),
                _buildInfoRow('Type', _getTypeLabel(status.type)),
                _buildInfoRow('Période de grâce', status.isInGracePeriod ? 'Oui' : 'Non'),
                if (status.remainingDays != null) _buildInfoRow('Jours restants', '${status.remainingDays}'),
                _buildInfoRow('Mode dégradé', controller.isInDegradedMode() ? 'Oui' : 'Non'),
              ] else
                const Text('Aucun statut disponible'),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Méthodes de démonstration
  void _showWarningNotification() {
    final controller = Get.find<SubscriptionController>();
    final status = controller.currentStatus;

    if (status != null) {
      ExpirationNotificationDialog.show(
        context,
        status.copyWith(remainingDays: 3),
        isUrgent: false,
      );
    }
  }

  void _showUrgentNotification() {
    final controller = Get.find<SubscriptionController>();
    final status = controller.currentStatus;

    if (status != null) {
      ExpirationNotificationDialog.show(
        context,
        status.copyWith(remainingDays: 1),
        isUrgent: true,
      );
    }
  }

  void _showBlockedScreen(bool gracePeriod) {
    final controller = Get.find<SubscriptionController>();
    final status = controller.currentStatus;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionBlockedPage(
          status: status,
          isInGracePeriod: gracePeriod,
        ),
      ),
    );
  }

  String _getTypeLabel(dynamic type) {
    return type.toString().split('.').last;
  }
}

// Extension pour créer des copies modifiées du statut (pour les tests)
extension SubscriptionStatusCopy on dynamic {
  copyWith({int? remainingDays}) {
    // Cette méthode devrait être implémentée dans SubscriptionStatus
    // Pour l'exemple, on retourne l'objet original
    return this;
  }
}
