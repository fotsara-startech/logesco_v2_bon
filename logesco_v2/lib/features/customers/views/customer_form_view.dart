import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/customer_form_controller.dart';
import '../../../shared/widgets/loading_widget.dart';

/// Vue de formulaire pour créer/modifier un client
class CustomerFormView extends StatelessWidget {
  const CustomerFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerFormController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditing.value ? 'customers_edit_title'.tr : 'customers_new'.tr)),
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
                  onPressed: controller.saveCustomer,
                  icon: const Icon(Icons.save),
                  tooltip: 'save'.tr,
                )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.isEditing.value) {
          return LoadingWidget(message: 'customers_loading'.tr);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                _buildSectionTitle('customers_general_info'.tr),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.nomController,
                  label: '${'customers_last_name'.tr} *',
                  hint: 'customers_last_name_hint'.tr,
                  icon: Icons.person,
                  validator: controller.validateNom,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.prenomController,
                  label: 'customers_first_name'.tr,
                  hint: 'customers_first_name_hint'.tr,
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 32),

                // Coordonnées
                _buildSectionTitle('customers_contact_info'.tr),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.telephoneController,
                  label: 'customers_phone'.tr,
                  hint: 'customers_phone_hint'.tr,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: controller.validateTelephone,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.emailController,
                  label: 'customers_email'.tr,
                  hint: 'customers_email_hint'.tr,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                ),

                const SizedBox(height: 32),

                // Adresse
                _buildSectionTitle('customers_address_info'.tr),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: controller.adresseController,
                  label: 'customers_address_full'.tr,
                  hint: 'customers_address_hint'.tr,
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
                        child: Text('cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.saveCustomer,
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(controller.isEditing.value ? 'edit'.tr : 'customers_create'.tr),
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
