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
            _validationError = 'Échec de l\'activation. Vérifiez votre clé.';
          });
        }
      } catch (e) {
        setState(() {
          if (e is LicenseException) {
            _validationError = e.localizedMessage;
          } else {
            _validationError = 'Erreur inattendue: ${e.toString()}';
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
        title: const Text('Activation réussie'),
        content: const Text(
          'Votre licence a été activée avec succès. Vous pouvez maintenant utiliser toutes les fonctionnalités de l\'application.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retour à l'écran précédent
            },
            child: const Text('Continuer'),
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
        _validationError = 'La clé doit contenir au moins 19 caractères';
      });
    } else if (!RegExp(r'^[A-Za-z0-9+/=\-_]+$').hasMatch(value)) {
      setState(() {
        _validationError = 'Format de clé invalide';
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
        title: const Text('Activation de licence'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _isValidating,
          loadingMessage: 'Validation de la licence...',
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
          'Activation de licence',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez votre clé d\'activation pour débloquer l\'application',
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
                  'Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Copiez votre clé d\'activation depuis votre email de confirmation\n'
              '• La clé est sensible à la casse et ne doit contenir aucun espace\n'
              '• Une clé ne peut être utilisée que sur un seul appareil\n'
              '• Contactez le support si vous rencontrez des difficultés',
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
        labelText: 'Clé d\'activation',
        hintText: 'Collez votre clé d\'activation ici',
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
        helperText: 'Format: Chaîne de caractères alphanumériques',
      ),
      maxLines: 3,
      textInputAction: TextInputAction.done,
      onChanged: _validateKeyFormat,
      onFieldSubmitted: (_) => _handleActivation(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez saisir votre clé d\'activation';
        }
        if (value.trim().length < 19) {
          return 'La clé doit contenir au moins 19 caractères';
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
        _isValidating ? 'Validation...' : 'Activer la licence',
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
                      'Besoin d\'aide ?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Si vous n\'avez pas reçu votre clé d\'activation ou si vous rencontrez des problèmes, contactez notre équipe de support.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implémenter l'ouverture du support
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Contacter le support'),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implémenter l'ouverture de la FAQ
                      },
                      icon: const Icon(Icons.help),
                      label: const Text('FAQ'),
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
                    label: const Text('Afficher la clé de l\'appareil'),
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
            const Text('Clé de l\'appareil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voici la clé unique de votre appareil. Copiez-la et envoyez-la pour obtenir votre licence d\'activation :',
            ),
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
                    const SnackBar(
                      content: Text('Clé copiée dans le presse-papiers'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la copie: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
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
            const Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
