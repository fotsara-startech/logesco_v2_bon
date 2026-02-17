import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/subscription_controller.dart';

import '../models/license_data.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import 'license_activation_page.dart';

/// Page d'affichage du statut d'abonnement
class SubscriptionStatusPage extends StatefulWidget {
  const SubscriptionStatusPage({super.key});

  @override
  State<SubscriptionStatusPage> createState() => _SubscriptionStatusPageState();
}

class _SubscriptionStatusPageState extends State<SubscriptionStatusPage> {
  final SubscriptionController _subscriptionController = Get.find<SubscriptionController>();

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    await _subscriptionController.refreshStatus();
  }

  void _navigateToActivation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LicenseActivationPage(),
      ),
    );
  }

  void _showRenewalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renouvellement'),
        content: const Text(
          'Pour renouveler votre abonnement, contactez notre équipe commerciale ou utilisez votre espace client en ligne.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'ouverture de l'espace client
            },
            child: const Text('Espace client'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statut d\'abonnement'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Obx(() {
        if (_subscriptionController.isLoading) {
          return const LoadingWidget(message: 'Chargement du statut...');
        }

        if (_subscriptionController.errorMessage.isNotEmpty) {
          return ErrorDisplayWidget(
            message: _subscriptionController.errorMessage,
            title: 'Erreur de chargement',
            onRetry: _refreshStatus,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshStatus,
          child: _buildStatusContent(),
        );
      }),
    );
  }

  Widget _buildStatusContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carte de statut principal
          _buildMainStatusCard(),

          const SizedBox(height: 16),

          // Détails de l'abonnement
          _buildSubscriptionDetails(),

          const SizedBox(height: 16),

          // Notifications et alertes
          if (_subscriptionController.shouldShowNotifications()) _buildNotificationsCard(),

          const SizedBox(height: 16),

          // Actions disponibles
          _buildActionsCard(),

          const SizedBox(height: 16),

          // Informations supplémentaires
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildMainStatusCard() {
    final status = _subscriptionController.currentStatus;
    final statusMessage = _subscriptionController.getStatusMessage();
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Icône de statut
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                statusIcon,
                size: 40,
                color: statusColor,
              ),
            ),

            const SizedBox(height: 16),

            // Message de statut
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Sous-titre avec type d'abonnement
            if (status != null)
              Text(
                _getSubscriptionTypeLabel(status.type),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                textAlign: TextAlign.center,
              ),

            // Indicateur de jours restants pour la période d'essai
            if (status?.type == SubscriptionType.trial && status?.remainingDays != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRemainingDaysColor(status!.remainingDays!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getRemainingDaysColor(status.remainingDays!),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${status.remainingDays} jour${status.remainingDays! > 1 ? 's' : ''} restant${status.remainingDays! > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getRemainingDaysColor(status.remainingDays!),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    final details = _subscriptionController.getSubscriptionDetails();
    final isActive = details['isActive'] as bool;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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

            // Type d'abonnement
            _buildDetailRow(
              'Type d\'abonnement',
              details['type'] as String,
              Icons.card_membership,
            ),

            // Statut
            _buildDetailRow(
              'Statut',
              details['status'] as String,
              Icons.info_outline,
              valueColor: isActive ? Colors.green : Colors.red,
            ),

            // Date d'expiration
            if (details['expirationDate'] != null)
              _buildDetailRow(
                'Date d\'expiration',
                DateFormat('dd/MM/yyyy').format(details['expirationDate'] as DateTime),
                Icons.calendar_today,
              ),

            // Jours restants
            if (details['remainingDays'] != null && details['remainingDays'] as int > 0)
              _buildDetailRow(
                'Jours restants',
                '${details['remainingDays']} jour${(details['remainingDays'] as int) > 1 ? 's' : ''}',
                Icons.timer,
                valueColor: _getRemainingDaysColor(details['remainingDays'] as int),
              ),

            // Période de grâce
            if (details['isInGracePeriod'] as bool)
              _buildDetailRow(
                'Période de grâce',
                'Active',
                Icons.warning,
                valueColor: Colors.orange,
              ),

            // Clé de licence (si abonnement actif)
            if (isActive) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildLicenseKeySection(),
            ],

            // Clé de l'appareil (toujours visible)
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDeviceKeySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseKeySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.vpn_key,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),
            Text(
              'Clé de licence',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: FutureBuilder<String?>(
                  future: _subscriptionController.getCurrentLicenseKey(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Chargement...');
                    }

                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return const Text(
                        'Clé non disponible',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      );
                    }

                    return Text(
                      snapshot.data!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () async {
                  final key = await _subscriptionController.getCurrentLicenseKey();
                  if (key != null && mounted) {
                    await _subscriptionController.copyLicenseKeyToClipboard(key);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clé copiée dans le presse-papiers'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                tooltip: 'Copier la clé',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Conservez cette clé en lieu sûr pour réinstaller l\'application',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    final notifications = _subscriptionController.notifications;
    final isCritical = _subscriptionController.shouldShowCriticalNotifications();

    return Card(
      color: isCritical ? Colors.red.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCritical ? Icons.error : Icons.warning,
                  color: isCritical ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isCritical ? 'Attention requise' : 'Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCritical ? Colors.red : Colors.orange,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...notifications.map((notification) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: isCritical ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notification,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    final status = _subscriptionController.currentStatus;
    final isActive = _subscriptionController.isSubscriptionActive;
    final canStartTrial = !isActive && status?.type != SubscriptionType.trial;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions disponibles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Bouton d'activation de licence
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToActivation,
                icon: const Icon(Icons.vpn_key),
                label: const Text('Activer une licence'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bouton de renouvellement (si abonnement actif)
            if (isActive) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showRenewalDialog,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Renouveler l\'abonnement'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Bouton de démarrage d'essai (si possible)
            if (canStartTrial) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await _subscriptionController.startTrial();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Période d\'essai démarrée avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer la période d\'essai'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Bouton de validation forcée
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await _subscriptionController.forceValidation();
                },
                icon: const Icon(Icons.sync),
                label: const Text('Vérifier la licence'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations supplémentaires',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.help_outline,
              'Besoin d\'aide ?',
              'Contactez notre support technique pour toute question concernant votre abonnement.',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.security,
              'Sécurité',
              'Votre licence est vérifiée automatiquement pour garantir la sécurité de l\'application.',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.update,
              'Mises à jour',
              'Les mises à jour sont disponibles automatiquement avec un abonnement actif.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Méthodes utilitaires
  Color _getStatusColor() {
    final status = _subscriptionController.currentStatus;
    if (status == null || !status.isActive) return Colors.red;

    final days = status.remainingDays ?? 0;
    if (days <= 1) return Colors.red;
    if (days <= 3) return Colors.orange;

    return Colors.green;
  }

  IconData _getStatusIcon() {
    final status = _subscriptionController.currentStatus;
    if (status == null || !status.isActive) return Icons.error;

    final days = status.remainingDays ?? 0;
    if (days <= 1) return Icons.warning;
    if (days <= 3) return Icons.info;

    return Icons.check_circle;
  }

  String _getSubscriptionTypeLabel(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return 'Période d\'essai';
      case SubscriptionType.monthly:
        return 'Abonnement mensuel';
      case SubscriptionType.annual:
        return 'Abonnement annuel';
      case SubscriptionType.lifetime:
        return 'Licence à vie';
    }
  }

  Color _getRemainingDaysColor(int days) {
    if (days <= 1) return Colors.red;
    if (days <= 3) return Colors.orange;
    if (days <= 7) return Colors.amber;
    return Colors.green;
  }

  Widget _buildDeviceKeySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.devices,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),
            Text(
              'Clé de l\'appareil',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: FutureBuilder<String?>(
                  future: _subscriptionController.getDeviceFingerprint(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Chargement...');
                    }

                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return const Text(
                        'Clé non disponible',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      );
                    }

                    return Text(
                      snapshot.data!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () async {
                  final key = await _subscriptionController.getDeviceFingerprint();
                  if (key != null && mounted) {
                    await _subscriptionController.copyLicenseKeyToClipboard(key);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clé de l\'appareil copiée'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                tooltip: 'Copier la clé',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cette clé identifie votre appareil de manière unique',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }
}
