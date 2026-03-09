import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/license_errors.dart';

/// Page d'activation de licence
class LicenseActivationPage extends StatefulWidget {
  const LicenseActivationPage({super.key});

  @override
  State<LicenseActivationPage> createState() => _LicenseActivationPageState();
}

class _LicenseActivationPageState extends State<LicenseActivationPage> {
  final _formKey = GlobalKey<FormState>();
  final _licenseKeyController = TextEditingController();
  final SubscriptionController _subscriptionController = Get.find<SubscriptionController>();

  String? _validationError;
  bool _isValidating = false;

  @override
  void dispose() {
    _licenseKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleActivation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isValidating = true;
        _validationError = null;
      });

      try {
        final success = await _subscriptionController.activateLicense(
          _licenseKeyController.text.trim(),
        );

        if (success) {
          _showSuccessDialog();
        } else {
          setState(() {
            _validationError = 'subscription_activation_failed'.tr;
          });
        }
      } catch (e) {
        setState(() {
          if (e is LicenseException) {
            _validationError = e.localizedMessage;
          } else {
            _validationError = '${'error'.tr}: ${e.toString()}';
          }
        });
      } finally {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: Text('subscription_activation_success'.tr),
        content: Text('subscription_activation_success_message'.tr),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retour à l'écran précédent
            },
            child: Text('subscription_continue'.tr),
          ),
        ],
      ),
    );
  }

  void _validateKeyFormat(String value) {
    if (value.isEmpty) {
      setState(() {
        _validationError = null;
      });
      return;
    }

    // Validation basique du format de clé
    // Format court: XXXX-XXXX-XXXX-XXXX (19 caractères)
    // Format long: LOGESCO_V1_... (>20 caractères)
    if (value.length < 19) {
      setState(() {
        _validationError = 'subscription_license_key_min_length'.tr;
      });
    } else if (!RegExp(r'^[A-Za-z0-9+/=\-_]+$').hasMatch(value)) {
      setState(() {
        _validationError = 'subscription_license_key_invalid_format'.tr;
      });
    } else {
      setState(() {
        _validationError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('subscription_activation_title'.tr),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _isValidating,
          loadingMessage: 'subscription_validating'.tr,
          child: _buildActivationForm(context),
        ),
      ),
    );
  }

  Widget _buildActivationForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête avec icône
            _buildHeader(),

            const SizedBox(height: 32),

            // Instructions
            _buildInstructions(),

            const SizedBox(height: 24),

            // Champ de saisie de clé
            _buildLicenseKeyField(),

            const SizedBox(height: 16),

            // Message d'erreur de validation
            if (_validationError != null) _buildValidationError(),

            const SizedBox(height: 24),

            // Bouton d'activation
            _buildActivationButton(),

            const SizedBox(height: 32),

            // Aide et support
            _buildHelpSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.vpn_key,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'subscription_activation_title'.tr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'subscription_enter_license_key'.tr,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'subscription_instructions_title'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• ${'subscription_instructions_1'.tr}\n'
              '• ${'subscription_instructions_2'.tr}\n'
              '• ${'subscription_instructions_3'.tr}\n'
              '• ${'subscription_instructions_4'.tr}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseKeyField() {
    return TextFormField(
      controller: _licenseKeyController,
      decoration: InputDecoration(
        labelText: 'subscription_license_key_label'.tr,
        hintText: 'subscription_license_key_hint'.tr,
        prefixIcon: const Icon(Icons.vpn_key),
        suffixIcon: _licenseKeyController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _licenseKeyController.clear();
                  setState(() {
                    _validationError = null;
                  });
                },
              )
            : null,
        helperText: 'subscription_license_key_format'.tr,
      ),
      maxLines: 3,
      textInputAction: TextInputAction.done,
      onChanged: _validateKeyFormat,
      onFieldSubmitted: (_) => _handleActivation(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'subscription_license_key_required'.tr;
        }
        if (value.trim().length < 19) {
          return 'subscription_license_key_min_length'.tr;
        }
        return null;
      },
    );
  }

  Widget _buildValidationError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivationButton() {
    final isFormValid = _licenseKeyController.text.trim().length >= 19 && _validationError == null;

    return ElevatedButton.icon(
      onPressed: isFormValid && !_isValidating ? _handleActivation : null,
      icon: _isValidating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_circle),
      label: Text(
        _isValidating ? 'subscription_validating'.tr : 'subscription_activate_license'.tr,
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Column(
      children: [
        // Section clé de l'appareil
        _buildDeviceKeySection(),

        const SizedBox(height: 16),

        // Section aide
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'subscription_need_help'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('subscription_no_license_key'.tr),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implémenter l'ouverture du support
                      },
                      icon: const Icon(Icons.email),
                      label: Text('subscription_contact_support_button'.tr),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implémenter l'ouverture de la FAQ
                      },
                      icon: const Icon(Icons.help),
                      label: Text('subscription_faq'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceKeySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Clé de l\'appareil',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Cette clé unique identifie votre appareil. Vous en aurez besoin pour obtenir votre licence d\'activation.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDeviceKey,
                    icon: const Icon(Icons.visibility),
                    label: Text('subscription_show_device_key'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche la clé de l'appareil dans une boîte de dialogue
  Future<void> _showDeviceKey() async {
    if (!mounted) return;

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Récupérer la clé de l'appareil
      final deviceKey = await _subscriptionController.getDeviceFingerprint();

      // Fermer l'indicateur de chargement
      if (mounted) {
        Navigator.of(context).pop();

        if (deviceKey != null && deviceKey.isNotEmpty) {
          _showDeviceKeyDialog(deviceKey);
        } else {
          _showErrorDialog('Impossible de récupérer la clé de l\'appareil');
        }
      }
    } catch (e) {
      // Fermer l'indicateur de chargement si encore ouvert
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        _showErrorDialog('Erreur lors de la récupération de la clé: ${e.toString()}');
      }
    }
  }

  /// Affiche la boîte de dialogue avec la clé de l'appareil
  void _showDeviceKeyDialog(String deviceKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.fingerprint,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text('subscription_device_fingerprint'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('subscription_device_fingerprint_info'.tr + ':'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: SelectableText(
                deviceKey,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Appuyez longuement pour sélectionner et copier',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: deviceKey));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('subscription_license_key_copied'.tr),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${'error'.tr}: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.copy),
            label: Text('subscription_copy_key'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  /// Affiche une boîte de dialogue d'erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text('error'.tr),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ok'.tr),
          ),
        ],
      ),
    );
  }
}
