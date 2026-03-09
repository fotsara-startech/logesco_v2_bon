import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/product_form_controller.dart';
import '../../../shared/constants/constants.dart';
import '../../../core/routes/app_routes.dart';

/// Vue du formulaire de création/édition de produit
class ProductFormView extends StatelessWidget {
  const ProductFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductFormController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditing.value ? 'product_form_edit_title'.tr : 'product_form_new_title'.tr)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: controller.cancel,
            child: Text('product_form_cancel'.tr),
          ),
        ],
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informations de base
              _buildSectionTitle('product_form_basic_info'.tr),
              const SizedBox(height: 16),

              _buildReferenceField(controller),
              const SizedBox(height: 16),

              _buildNomField(controller),
              const SizedBox(height: 16),

              _buildDescriptionField(controller),
              const SizedBox(height: 20),

              // Informations commerciales
              _buildSectionTitle('product_form_commercial_info'.tr),
              const SizedBox(height: 16),

              _buildPrixField(controller),
              const SizedBox(height: 16),

              _buildPrixAchatField(controller),
              const SizedBox(height: 16),

              _buildRemiseMaxField(controller),
              const SizedBox(height: 16),

              _buildCodeBarreField(controller),
              const SizedBox(height: 16),

              _buildCategorieField(controller),
              const SizedBox(height: 20),

              // Gestion du stock
              _buildSectionTitle('product_form_stock_management'.tr),
              const SizedBox(height: 16),

              _buildSeuilStockField(controller),
              const SizedBox(height: 16),

              _buildServiceSwitch(controller),
              const SizedBox(height: 12),

              _buildPeremptionSwitch(controller),
              const SizedBox(height: 12),

              _buildStatusSwitch(controller),
              const SizedBox(height: 24),

              // Boutons d'action
              _buildActionButtons(controller),
            ],
          ),
        ),
      ),
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

  /// Champ référence
  Widget _buildReferenceField(ProductFormController controller) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch pour activer/désactiver la génération automatique (seulement en création)
            if (!controller.isEditing.value) ...[
              SwitchListTile(
                title: Text('product_form_reference_auto'.tr),
                subtitle: Text(
                  controller.isAutoReference.value ? 'product_form_reference_auto_enabled'.tr : 'product_form_reference_manual_enabled'.tr,
                ),
                value: controller.isAutoReference.value,
                onChanged: (_) => controller.toggleAutoReference(),
                secondary: Icon(
                  controller.isAutoReference.value ? Icons.auto_awesome : Icons.edit,
                  color: controller.isAutoReference.value ? Colors.blue : Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Message informatif en mode édition
            if (controller.isEditing.value) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'product_form_reference_not_editable'.tr,
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Champ de référence
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.referenceController,
                    enabled: !controller.isEditing.value && !controller.isAutoReference.value,
                    decoration: InputDecoration(
                      labelText: 'product_form_reference_label'.tr,
                      hintText: controller.isEditing.value
                          ? 'product_form_reference_hint_not_editable'.tr
                          : controller.isAutoReference.value
                              ? 'product_form_reference_hint_auto'.tr
                              : 'product_form_reference_hint_manual'.tr,
                      prefixIcon: const Icon(Icons.tag),
                      border: const OutlineInputBorder(),
                      errorText: controller.referenceError.value.isEmpty ? null : controller.referenceError.value,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-_]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                  ),
                ),

                // Bouton pour régénérer la référence (seulement en création et mode auto)
                if (!controller.isEditing.value && controller.isAutoReference.value) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: controller.isGeneratingReference.value ? null : controller.generateReference,
                    icon: controller.isGeneratingReference.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    tooltip: 'product_form_reference_regenerate'.tr,
                  ),
                ],
              ],
            ),
          ],
        ));
  }

  /// Champ nom
  Widget _buildNomField(ProductFormController controller) {
    return Obx(() => TextFormField(
          controller: controller.nomController,
          decoration: InputDecoration(
            labelText: 'product_form_name_label'.tr,
            hintText: 'product_form_name_hint'.tr,
            prefixIcon: const Icon(Icons.inventory_2),
            border: const OutlineInputBorder(),
            errorText: controller.nomError.value.isEmpty ? null : controller.nomError.value,
          ),
          textCapitalization: TextCapitalization.words,
          inputFormatters: [
            LengthLimitingTextInputFormatter(100),
          ],
        ));
  }

  /// Champ description
  Widget _buildDescriptionField(ProductFormController controller) {
    return TextFormField(
      controller: controller.descriptionController,
      decoration: InputDecoration(
        labelText: 'product_form_description_label'.tr,
        hintText: 'product_form_description_hint'.tr,
        prefixIcon: const Icon(Icons.description),
        border: const OutlineInputBorder(),
      ),
      maxLines: 3,
      inputFormatters: [
        LengthLimitingTextInputFormatter(500),
      ],
    );
  }

  /// Champ prix
  Widget _buildPrixField(ProductFormController controller) {
    return Obx(() => TextFormField(
          controller: controller.prixUnitaireController,
          decoration: InputDecoration(
            labelText: 'product_form_sale_price_label'.tr,
            hintText: '0',
            prefixIcon: const Icon(Icons.attach_money),
            suffixText: CurrencyConstants.defaultCurrency,
            border: const OutlineInputBorder(),
            errorText: controller.prixError.value.isEmpty ? null : controller.prixError.value,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        ));
  }

  /// Champ prix d'achat
  Widget _buildPrixAchatField(ProductFormController controller) {
    return Obx(() => TextFormField(
          controller: controller.prixAchatController,
          decoration: InputDecoration(
            labelText: 'product_form_purchase_price_label'.tr,
            hintText: '0',
            prefixIcon: const Icon(Icons.shopping_cart),
            suffixText: CurrencyConstants.defaultCurrency,
            border: const OutlineInputBorder(),
            errorText: controller.prixAchatError.value.isEmpty ? null : controller.prixAchatError.value,
            helperText: 'product_form_purchase_price_helper'.tr,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        ));
  }

  /// Champ remise maximale autorisée
  Widget _buildRemiseMaxField(ProductFormController controller) {
    return Obx(() => TextFormField(
          controller: controller.remiseMaxController,
          decoration: InputDecoration(
            labelText: 'product_form_max_discount_label'.tr,
            hintText: '0',
            prefixIcon: const Icon(Icons.discount),
            suffixText: CurrencyConstants.defaultCurrency,
            border: const OutlineInputBorder(),
            errorText: controller.remiseMaxError.value.isEmpty ? null : controller.remiseMaxError.value,
            helperText: 'product_form_max_discount_helper'.tr,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        ));
  }

  /// Champ code-barre
  Widget _buildCodeBarreField(ProductFormController controller) {
    return TextFormField(
      controller: controller.codeBarreController,
      decoration: InputDecoration(
        labelText: 'product_form_barcode_label'.tr,
        hintText: 'product_form_barcode_hint'.tr,
        prefixIcon: const Icon(Icons.qr_code_scanner),
        border: const OutlineInputBorder(),
        helperText: 'product_form_barcode_helper'.tr,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        LengthLimitingTextInputFormatter(20),
      ],
    );
  }

  /// Champ catégorie
  Widget _buildCategorieField(ProductFormController controller) {
    return Obx(() {
      // Déterminer la valeur actuelle
      String? currentValue;
      if (controller.selectedCategory.value.isNotEmpty) {
        // Vérifier que la valeur existe dans la liste des catégories
        final categoryExists = controller.categories.any((cat) => cat.nom == controller.selectedCategory.value);
        if (categoryExists) {
          currentValue = controller.selectedCategory.value;
        } else {
          // Si la valeur n'existe pas, la garder mais signaler
          currentValue = controller.selectedCategory.value;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              labelText: 'product_form_category_label'.tr,
              prefixIcon: const Icon(Icons.category),
              border: const OutlineInputBorder(),
              helperText: controller.categories.isEmpty ? 'product_form_category_empty'.tr : 'product_form_category_count'.tr.replaceAll('@count', controller.categories.length.toString()),
            ),
            hint: Text('product_form_category_hint'.tr),
            items: [
              DropdownMenuItem<String>(
                value: '',
                child: Text('product_form_category_none'.tr),
              ),
              ...controller.categories.map((category) => DropdownMenuItem<String>(
                    value: category.nom,
                    child: Text(
                      category.description != null && category.description!.isNotEmpty ? '${category.nom} - ${category.description}' : category.nom,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: controller.updateSelectedCategory,
          ),
          if (controller.categories.isEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.categories),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'product_form_category_create'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  /// Champ seuil de stock
  Widget _buildSeuilStockField(ProductFormController controller) {
    return Obx(() => TextFormField(
          controller: controller.seuilStockController,
          decoration: InputDecoration(
            labelText: 'product_form_stock_threshold_label'.tr,
            hintText: '0',
            prefixIcon: const Icon(Icons.warning_amber),
            suffixText: 'product_detail_units'.tr,
            border: const OutlineInputBorder(),
            errorText: controller.seuilError.value.isEmpty ? null : controller.seuilError.value,
            helperText: 'product_form_stock_threshold_helper'.tr,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ));
  }

  /// Switch pour le type de service
  Widget _buildServiceSwitch(ProductFormController controller) {
    return Obx(() => SwitchListTile(
          title: Text('product_form_service_title'.tr),
          subtitle: Text(
            controller.estService.value ? 'product_form_service_enabled'.tr : 'product_form_service_disabled'.tr,
          ),
          value: controller.estService.value,
          onChanged: (_) => controller.toggleEstService(),
          secondary: Icon(
            controller.estService.value ? Icons.design_services : Icons.inventory,
            color: controller.estService.value ? Colors.blue : Colors.orange,
          ),
        ));
  }

  /// Switch pour la gestion de péremption
  Widget _buildPeremptionSwitch(ProductFormController controller) {
    return Obx(() => SwitchListTile(
          title: Text('product_form_expiration_title'.tr),
          subtitle: Text(
            controller.gestionPeremption.value ? 'product_form_expiration_enabled'.tr : 'product_form_expiration_disabled'.tr,
          ),
          value: controller.gestionPeremption.value,
          onChanged: controller.estService.value ? null : (_) => controller.toggleGestionPeremption(),
          secondary: Icon(
            controller.gestionPeremption.value ? Icons.event_available : Icons.event_busy,
            color: controller.gestionPeremption.value ? Colors.green : Colors.grey,
          ),
        ));
  }

  /// Switch pour l'état actif
  Widget _buildStatusSwitch(ProductFormController controller) {
    return Obx(() => SwitchListTile(
          title: Text('product_form_active_title'.tr),
          subtitle: Text(
            controller.estActif.value ? 'product_form_active_enabled'.tr : 'product_form_active_disabled'.tr,
          ),
          value: controller.estActif.value,
          onChanged: (_) => controller.toggleEstActif(),
          secondary: Icon(
            controller.estActif.value ? Icons.check_circle : Icons.cancel,
            color: controller.estActif.value ? Colors.green : Colors.red,
          ),
        ));
  }

  /// Boutons d'action
  Widget _buildActionButtons(ProductFormController controller) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: controller.isLoading.value ? null : controller.cancel,
                child: Text('product_form_cancel'.tr),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: controller.isLoading.value || !controller.isFormValid ? null : controller.saveProduct,
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(controller.isEditing.value ? 'product_form_update_button'.tr : 'product_form_create_button'.tr),
              ),
            ),
          ],
        ));
  }
}
