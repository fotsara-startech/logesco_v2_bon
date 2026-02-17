import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../models/license_data.dart';
import '../services/implementations/device_service.dart';
import 'license_activation_page.dart';
import 'subscription_status_page.dart';

/// Page affichée quand l'application est bloquée à cause d'un abonnement expiré
class SubscriptionBlockedPage extends StatefulWidget {
  const SubscriptionBlockedPage({super.key});

  @override
  State<SubscriptionBlockedPage> createState() => _SubscriptionBlockedPageState();
}

class _SubscriptionBlockedPageState extends State<SubscriptionBlockedPage> {
  final SubscriptionController _subscriptionController = Get.find<SubscriptionController>();
  final DeviceService _deviceService = DeviceService();

  String? _deviceFingerprintShort;
  bool _showFingerprint = false;
  bool _isLoadingFingerprint = false;

  @override
  void initState() {
    super.initState();
    _checkStatusPeriodically();
    _loadDeviceFingerprint();
  }

  /// Charge l'empreinte de l'appareil au format court
  Future<void> _loadDeviceFingerprint() async {
    setState(() {
      _isLoadingFingerprint = true;
    });

    try {
      // Générer l'empreinte au format court (XXXX-XXXX-XXXX-XXXX)
      final fingerprintShort = await _deviceService.generateDeviceFingerprint();

      if (mounted) {
        setState(() {
          _deviceFingerprintShort = fingerprintShort;
          _isLoadingFingerprint = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFingerprint = false;
        });
      }
    }
  }

  /// Copie l'empreinte dans le presse-papiers
  Future<void> _copyFingerprint() async {
    if (_deviceFingerprintShort == null) return;

    await Clipboard.setData(ClipboardData(text: _deviceFingerprintShort!));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Empreinte copiée dans le presse-papiers'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Vérifie périodiquement le statut pour débloquer automatiquement si une licence est activée
  void _checkStatusPeriodically() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _subscriptionController.refreshStatus().then((_) {
        if (_subscriptionController.isSubscriptionActive) {
          timer.cancel();
          // Rediriger vers le dashboard si l'abonnement est maintenant actif
          Get.offAllNamed('/dashboard');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Icône principale
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(60),
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
                  'Accès bloqué',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Message d'explication
                Obx(() {
                  final status = _subscriptionController.currentStatus;
                  String message = 'Votre abonnement a expiré.';

                  if (status?.isInGracePeriod == true) {
                    message = 'Votre période de grâce a expiré.';
                  } else if (status?.type == SubscriptionType.trial) {
                    message = 'Votre période d\'essai gratuite a expiré.';
                  }

                  return Text(
                    '$message\nActivez une licence pour continuer à utiliser l\'application.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  );
                }),

                const SizedBox(height: 40),

                // Empreinte de l'appareil (section pliable)
                _buildDeviceFingerprintSection(),

                const SizedBox(height: 24),

                // Informations sur les fonctionnalités disponibles
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Accès limité disponible',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Vous pouvez consulter vos données existantes en mode lecture seule, mais vous ne pouvez pas créer ou modifier d\'éléments.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Boutons d'action
                Column(
                  children: [
                    // Bouton principal d'activation
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(() => const LicenseActivationPage());
                        },
                        icon: const Icon(Icons.vpn_key),
                        label: const Text('Activer une licence'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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

                    // Bouton de statut d'abonnement
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.to(() => const SubscriptionStatusPage());
                        },
                        icon: const Icon(Icons.info),
                        label: const Text('Voir le statut d\'abonnement'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bouton d'accès en lecture seule
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          // Rediriger vers le dashboard en mode lecture seule
                          Get.offAllNamed('/dashboard');
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Accéder en lecture seule'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Informations de contact
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Besoin d\'aide ?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contactez notre équipe de support pour toute question concernant votre abonnement.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Implémenter l'ouverture de l'email de support
                            },
                            icon: const Icon(Icons.email, size: 16),
                            label: const Text('Support'),
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Implémenter l'ouverture du site web
                            },
                            icon: const Icon(Icons.web, size: 16),
                            label: const Text('Site web'),
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section pour afficher l'empreinte de l'appareil
  Widget _buildDeviceFingerprintSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          // En-tête cliquable
          InkWell(
            onTap: () {
              setState(() {
                _showFingerprint = !_showFingerprint;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Obtenir l\'empreinte de l\'appareil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                    ),
                  ),
                  Icon(
                    _showFingerprint ? Icons.expand_less : Icons.expand_more,
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
            ),
          ),

          // Contenu pliable
          if (_showFingerprint) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pour obtenir une licence, vous devez fournir l\'empreinte unique de cet appareil à votre fournisseur.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingFingerprint)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_deviceFingerprintShort != null) ...[
                    // Affichage de l'empreinte au format court
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Votre empreinte :',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _deviceFingerprintShort!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bouton copier
                    ElevatedButton.icon(
                      onPressed: _copyFingerprint,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copier l\'empreinte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Colors.orange.shade900,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Prochaines étapes :',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Copiez l\'empreinte ci-dessus\n'
                            '2. Envoyez-la à votre fournisseur de licence\n'
                            '3. Recevez votre clé d\'activation\n'
                            '4. Activez votre licence dans l\'application',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade900,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Impossible de charger l\'empreinte'),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _loadDeviceFingerprint,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
