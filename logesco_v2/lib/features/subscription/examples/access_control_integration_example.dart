import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/subscription_guard.dart';
import '../widgets/degraded_mode_wrapper.dart';
import '../widgets/subscription_status_widget.dart';
import '../controllers/subscription_controller.dart';

/// Exemple d'intégration des contrôles d'accès dans une page
class AccessControlIntegrationExample extends StatefulWidget {
  const AccessControlIntegrationExample({super.key});

  @override
  State<AccessControlIntegrationExample> createState() => _AccessControlIntegrationExampleState();
}

class _AccessControlIntegrationExampleState extends State<AccessControlIntegrationExample> with SubscriptionAwarePage {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple - Contrôles d\'accès'),
        actions: const [
          // Widget compact dans l'app bar
          SubscriptionAppBarWidget(),
        ],
      ),
      body: SubscriptionGuard(
        requireActiveSubscription: true,
        allowGracePeriod: false,
        child: Column(
          children: [
            // Bannière de notification
            const SubscriptionNotificationBanner(),

            // Statut d'abonnement
            const SubscriptionStatusWidget(),

            // Contenu principal protégé
            Expanded(
              child: DegradedModeWrapper(
                allowModifications: true,
                restrictionMessage: 'Fonctionnalités limitées en mode dégradé',
                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contenu principal',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 16),

          // Action protégée par abonnement
          SubscriptionProtectedAction(
            requireActiveSubscription: true,
            restrictionMessage: 'Cette action nécessite un abonnement actif',
            onPressed: () {
              if (canPerformAction()) {
                _performProtectedAction();
              } else {
                showRestrictionMessage();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Action Premium'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action en lecture seule
          SubscriptionProtectedAction(
            requireActiveSubscription: false, // Autorise la consultation
            onPressed: () {
              _performReadOnlyAction();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Action de consultation'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Exemple d'utilisation du mixin
          ElevatedButton(
            onPressed: () {
              if (canPerformAction(requireActiveSubscription: true)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Action autorisée!')),
                );
              } else {
                showRestrictionMessage(
                  customMessage: 'Cette fonctionnalité nécessite un abonnement premium',
                );
              }
            },
            child: const Text('Tester les permissions'),
          ),
        ],
      ),
    );
  }

  void _performProtectedAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action premium exécutée avec succès!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _performReadOnlyAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consultation autorisée'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Exemple d'intégration dans un widget existant
class ExistingWidgetWithAccessControl extends StatelessWidget {
  const ExistingWidgetWithAccessControl({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionController = Get.find<SubscriptionController>();

    return Obx(() {
      // Vérifier le statut d'abonnement
      final isActive = subscriptionController.isSubscriptionActive;

      if (!isActive) {
        // Afficher une version limitée
        return _buildLimitedVersion();
      }

      // Afficher la version complète
      return _buildFullVersion();
    });
  }

  Widget _buildLimitedVersion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock,
            size: 48,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            'Version limitée',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Activez votre abonnement pour accéder à toutes les fonctionnalités',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFullVersion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            'Version complète',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toutes les fonctionnalités sont disponibles',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }
}

/// Exemple d'utilisation dans un formulaire
class ProtectedFormExample extends StatefulWidget {
  const ProtectedFormExample({super.key});

  @override
  State<ProtectedFormExample> createState() => _ProtectedFormExampleState();
}

class _ProtectedFormExampleState extends State<ProtectedFormExample> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SubscriptionGuard(
      requireActiveSubscription: false, // Permet la consultation
      allowGracePeriod: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Formulaire protégé'),
        ),
        body: DegradedModeWrapper(
          allowModifications: false, // Bloque les modifications si pas d'abonnement
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Veuillez saisir un nom';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Bouton de sauvegarde protégé
                  Obx(() {
                    final subscriptionController = Get.find<SubscriptionController>();
                    final canSave = subscriptionController.isSubscriptionActive;

                    return ElevatedButton(
                      onPressed: canSave ? _saveForm : null,
                      child: Text(
                        canSave ? 'Sauvegarder' : 'Sauvegarde verrouillée',
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulaire sauvegardé!')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
