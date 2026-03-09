import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/company_settings_controller.dart';
import '../../../core/widgets/language_selector.dart';

class CompanySettingsPage extends StatelessWidget {
  const CompanySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CompanySettingsController());

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final canPop = await controller.canPop();
          if (canPop) {
            Get.back();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('company_settings_title'.tr),
          actions: [
            IconButton(
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'refresh'.tr,
            ),
            Obx(() {
              if (!controller.canEdit) return const SizedBox.shrink();

              return IconButton(
                onPressed: controller.hasUnsavedChanges ? controller.resetForm : null,
                icon: const Icon(Icons.undo),
                tooltip: 'company_settings_undo'.tr,
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête avec statut
                  _buildStatusCard(controller),
                  const SizedBox(height: 24),

                  // Sélecteur de langue de l'application
                  const LanguageSelector(),
                  const SizedBox(height: 24),

                  // Formulaire
                  _buildFormSection(controller),
                  const SizedBox(height: 32),

                  // Boutons d'action
                  _buildActionButtons(controller),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusCard(CompanySettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  controller.hasProfile ? Icons.business : Icons.business_outlined,
                  color: controller.hasProfile ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.hasProfile ? 'Profil d\'entreprise configuré' : 'Profil d\'entreprise non configuré',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (!controller.hasProfile) ...[
              const SizedBox(height: 8),
              Text(
                'Configurez les informations de votre entreprise pour personnaliser vos documents.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
            if (controller.hasUnsavedChanges) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Modifications non sauvegardées',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(CompanySettingsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de l\'entreprise',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Nom de l'entreprise
            _buildTextField(
              controller: controller.nameController,
              label: 'Nom de l\'entreprise',
              icon: Icons.business,
              validator: (value) => controller.validateField('name', value ?? ''),
              fieldKey: 'name',
              settingsController: controller,
              enabled: controller.canEdit,
            ),
            const SizedBox(height: 16),

            // Adresse
            _buildTextField(
              controller: controller.addressController,
              label: 'Adresse',
              icon: Icons.location_on,
              validator: (value) => controller.validateField('address', value ?? ''),
              fieldKey: 'address',
              settingsController: controller,
              maxLines: 2,
              enabled: controller.canEdit,
            ),
            const SizedBox(height: 16),

            // Localisation
            _buildTextField(
              controller: controller.locationController,
              label: 'Localisation',
              icon: Icons.place,
              validator: (value) => controller.validateField('location', value ?? ''),
              fieldKey: 'location',
              settingsController: controller,
              enabled: controller.canEdit,
            ),
            const SizedBox(height: 16),

            // Téléphone
            _buildTextField(
              controller: controller.phoneController,
              label: 'Téléphone',
              icon: Icons.phone,
              validator: null, // Pas de validation - l'utilisateur peut entrer le numéro comme du texte
              fieldKey: 'phone',
              settingsController: controller,
              keyboardType: TextInputType.text, // Texte au lieu de phone
              enabled: controller.canEdit,
            ),
            const SizedBox(height: 16),

            // Email (optionnel)
            _buildTextField(
              controller: controller.emailController,
              label: 'Email (optionnel)',
              icon: Icons.email,
              validator: (value) => controller.validateField('email', value ?? ''),
              fieldKey: 'email',
              settingsController: controller,
              keyboardType: TextInputType.emailAddress,
              enabled: controller.canEdit,
            ),
            const SizedBox(height: 16),

            // NUI RCCM
            _buildTextField(
              controller: controller.nuiRccmController,
              label: 'NUI RCCM',
              icon: Icons.assignment,
              validator: (value) => controller.validateField('nuiRccm', value ?? ''),
              fieldKey: 'nuiRccm',
              settingsController: controller,
              enabled: controller.canEdit,
            ),
            const SizedBox(height: 16),

            // Slogan (optionnel)
            _buildTextField(
              controller: controller.sloganController,
              label: 'Slogan (optionnel)',
              icon: Icons.format_quote,
              validator: null,
              fieldKey: 'slogan',
              settingsController: controller,
              enabled: controller.canEdit,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Langue des factures
            _buildLanguageDropdown(controller),
            const SizedBox(height: 16),

            // Logo (optionnel)
            _buildLogoSection(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(CompanySettingsController controller) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, size: 20),
              const SizedBox(width: 8),
              Text(
                'Logo (optionnel)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.logoPath != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Logo sélectionné',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  if (controller.canEdit)
                    IconButton(
                      onPressed: controller.removeLogo,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer le logo',
                    ),
                ],
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: controller.canEdit ? controller.selectLogo : null,
              icon: const Icon(Icons.upload_file),
              label: const Text('Sélectionner un logo'),
            ),
            const SizedBox(height: 4),
            Text(
              'Le logo sera affiché sur les factures A4/A5',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildLanguageDropdown(CompanySettingsController controller) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, size: 20),
              const SizedBox(width: 8),
              Text(
                'Langue des factures',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: controller.selectedLanguage,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              enabled: controller.canEdit,
              hintText: 'Sélectionner la langue',
            ),
            items: const [
              DropdownMenuItem(
                value: 'fr',
                child: Row(
                  children: [
                    Text('🇫🇷'),
                    SizedBox(width: 8),
                    Text('Français'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Text('🇬🇧'),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'es',
                child: Row(
                  children: [
                    Text('🇪🇸'),
                    SizedBox(width: 8),
                    Text('Español'),
                  ],
                ),
              ),
            ],
            onChanged: controller.canEdit
                ? (value) {
                    if (value != null) {
                      controller.setLanguage(value);
                    }
                  }
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            'La langue sélectionnée sera utilisée pour toutes les factures',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator, // Rendre nullable avec ?
    required String fieldKey,
    required CompanySettingsController settingsController,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Obx(() {
      final fieldError = settingsController.getFieldError(fieldKey);

      return TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          errorText: fieldError,
          enabled: enabled,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: (value) {
          // Effacer l'erreur quand l'utilisateur tape
          if (fieldError != null) {
            settingsController.clearFieldError(fieldKey);
          }
        },
      );
    });
  }

  Widget _buildActionButtons(CompanySettingsController controller) {
    return Obx(() {
      if (!controller.canEdit) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous n\'avez pas les permissions pour modifier ces informations.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          // Bouton principal de sauvegarde
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isSaving ? null : controller.saveCompanyProfile,
              icon: controller.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(controller.hasProfile ? Icons.save : Icons.add_business),
              label: Text(
                controller.isSaving
                    ? 'Sauvegarde...'
                    : controller.hasProfile
                        ? 'Sauvegarder les modifications'
                        : 'Créer le profil d\'entreprise',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Bouton de suppression (admin seulement)
          if (controller.hasProfile && controller.isAdmin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.deleteCompanyProfile,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Supprimer le profil',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}
