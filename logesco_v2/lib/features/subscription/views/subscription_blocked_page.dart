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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('subscription_fingerprint_copied'.tr),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
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
                  'subscription_blocked_title'.tr,
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
                  String message = 'subscription_expired_message'.tr;

                  if (status?.isInGracePeriod == true) {
                    message = 'subscription_grace_expired_message'.tr;
                  } else if (status?.type == SubscriptionType.trial) {
                    message = 'subscription_trial_expired_message'.tr;
                  }

                  return Text(
                    '$message\n${'subscription_activate_to_continue'.tr}',
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
                            'subscription_limited_access_available'.tr,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'subscription_read_only_access'.tr,
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
                        label: Text('subscription_activate_license'.tr),
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
                        label: Text('subscription_view_status'.tr),
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
                        label: Text('subscription_access_read_only'.tr),
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
                        'subscription_need_help'.tr,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'subscription_contact_support'.tr,
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
                            label: Text('subscription_support'.tr),
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
                            label: Text('subscription_website'.tr),
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
                      'subscription_get_device_fingerprint'.tr,
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
                    'subscription_device_fingerprint_info'.tr,
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
                            'subscription_your_fingerprint'.tr,
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
                      label: Text('subscription_copy_fingerprint'.tr),
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
                                'subscription_next_steps'.tr,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. ${'subscription_next_step_1'.tr}\n'
                            '2. ${'subscription_next_step_2'.tr}\n'
                            '3. ${'subscription_next_step_3'.tr}\n'
                            '4. ${'subscription_next_step_4'.tr}',
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
                            Text('error'.tr),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _loadDeviceFingerprint,
                              icon: const Icon(Icons.refresh),
                              label: Text('subscription_retry'.tr),
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
