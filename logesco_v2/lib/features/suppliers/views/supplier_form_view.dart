import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/supplier_form_controller.dart';
import '../../../shared/widgets/loading_widget.dart';

/// Vue de formulaire pour créer/modifier un fournisseur
class SupplierFormView extends StatelessWidget {
  const SupplierFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierFormController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditing.value ? 'suppliers_edit'.tr : 'suppliers_add'.tr)),
        elevation: 0,
        actions: [
          Obx(() => controller.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: controller.saveSupplier,
                  icon: const Icon(Icons.save),
                  tooltip: 'suppliers_form_save'.tr,
                )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.isEditing.value) {
          return LoadingWidget(message: 'suppliers_loading'.tr);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                _buildSectionTitle('suppliers_info_general'.tr),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.nomController,
                  label: 'suppliers_form_name'.tr,
                  hint: 'suppliers_form_name_hint'.tr,
                  icon: Icons.business,
                  validator: controller.validateNom,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.personneContactController,
                  label: 'suppliers_form_contact'.tr,
                  hint: 'suppliers_form_contact_hint'.tr,
                  icon: Icons.person,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 32),

                // Coordonnées
                _buildSectionTitle('suppliers_contact_info'.tr),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.telephoneController,
                  label: 'suppliers_phone'.tr,
                  hint: 'suppliers_form_phone_hint'.tr,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: controller.validateTelephone,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.emailController,
                  label: 'suppliers_email'.tr,
                  hint: 'suppliers_form_email_hint'.tr,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                ),

                const SizedBox(height: 32),

                // Adresse
                _buildSectionTitle('suppliers_address'.tr),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.adresseController,
                  label: 'suppliers_form_address'.tr,
                  hint: 'suppliers_form_address_hint'.tr,
                  icon: Icons.location_on,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 32),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.isLoading.value ? null : () => Get.back(),
                        child: Text('suppliers_form_cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.saveSupplier,
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(controller.isEditing.value ? 'suppliers_edit'.tr : 'suppliers_form_create'.tr),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Construit un titre de section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  /// Construit un champ de texte avec validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
    );
  }
}
