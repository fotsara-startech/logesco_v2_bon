import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import 'license_activation_page.dart';

/// Bannière affichée en mode dégradé pour indiquer les limitations
class DegradedModeBanner extends StatelessWidget {
  final bool isInGracePeriod;
  final int? remainingGraceDays;

  const DegradedModeBanner({
    super.key,
    this.isInGracePeriod = false,
    this.remainingGraceDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isInGracePeriod ? 'Mode consultation - Période de grâce' : 'Mode consultation uniquement',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
                if (isInGracePeriod && remainingGraceDays != null)
                  Text(
                    'Plus que $remainingGraceDays jour${(remainingGraceDays ?? 0) > 1 ? 's' : ''} restant${(remainingGraceDays ?? 0) > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LicenseActivationPage(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              'Activer',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui encapsule le contenu avec les restrictions du mode dégradé
class DegradedModeWrapper extends StatelessWidget {
  final Widget child;
  final bool allowModifications;
  final String? restrictionMessage;

  const DegradedModeWrapper({
    super.key,
    required this.child,
    this.allowModifications = false,
    this.restrictionMessage,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionController = Get.find<SubscriptionController>();

    return Obx(() {
      final status = subscriptionController.currentStatus;
      final shouldShowBanner = status != null && (!status.isActive || status.isInGracePeriod);

      return Column(
        children: [
          // Bannière de mode dégradé
          if (shouldShowBanner)
            DegradedModeBanner(
              isInGracePeriod: status.isInGracePeriod,
              remainingGraceDays: status.isInGracePeriod ? 3 : null, // TODO: Calculer les jours restants de grâce
            ),

          // Contenu principal
          Expanded(
            child: Stack(
              children: [
                child,

                // Overlay de restriction si nécessaire
                if (!allowModifications && shouldShowBanner) _buildRestrictionOverlay(context),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRestrictionOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fonctionnalité restreinte',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  restrictionMessage ?? 'Cette fonctionnalité n\'est pas disponible en mode consultation. Activez une licence pour débloquer toutes les fonctionnalités.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Fermer l'overlay (retour en mode consultation)
                      },
                      child: const Text('Fermer'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LicenseActivationPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Activer une licence'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mixin pour ajouter facilement les vérifications de mode dégradé
mixin DegradedModeCheck {
  /// Vérifie si une action est autorisée en mode dégradé
  bool canPerformAction(BuildContext context, {bool showDialog = true}) {
    final subscriptionController = Get.find<SubscriptionController>();
    final status = subscriptionController.currentStatus;

    // Si l'abonnement est actif et pas en période de grâce, autoriser
    if (status != null && status.isActive && !status.isInGracePeriod) {
      return true;
    }

    // Si en période de grâce, autoriser seulement la consultation
    if (status != null && status.isInGracePeriod) {
      if (showDialog) {
        _showGracePeriodDialog(context);
      }
      return false;
    }

    // Sinon, bloquer complètement
    if (showDialog) {
      _showBlockedDialog(context);
    }
    return false;
  }

  void _showGracePeriodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Période de grâce'),
          ],
        ),
        content: const Text(
          'Vous êtes en période de grâce. Seule la consultation est autorisée. Activez une licence pour retrouver toutes les fonctionnalités.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LicenseActivationPage(),
                ),
              );
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  void _showBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Accès bloqué'),
          ],
        ),
        content: const Text(
          'Votre abonnement a expiré. Activez une licence pour continuer à utiliser l\'application.',
        ),
        actions: [
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Activer une licence'),
          ),
        ],
      ),
    );
  }
}
