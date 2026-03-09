import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expense_category_controller.dart';
import '../models/expense_category.dart';

class CreateExpenseCategoryPage extends StatefulWidget {
  const CreateExpenseCategoryPage({super.key});

  @override
  State<CreateExpenseCategoryPage> createState() => _CreateExpenseCategoryPageState();
}

class _CreateExpenseCategoryPageState extends State<CreateExpenseCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedColor;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'expenses_color_blue'.tr, 'value': '#2196F3', 'color': Colors.blue},
    {'name': 'expenses_color_green'.tr, 'value': '#4CAF50', 'color': Colors.green},
    {'name': 'expenses_color_orange'.tr, 'value': '#FF9800', 'color': Colors.orange},
    {'name': 'expenses_color_red'.tr, 'value': '#F44336', 'color': Colors.red},
    {'name': 'expenses_color_purple'.tr, 'value': '#9C27B0', 'color': Colors.purple},
    {'name': 'expenses_color_teal'.tr, 'value': '#009688', 'color': Colors.teal},
    {'name': 'expenses_color_indigo'.tr, 'value': '#3F51B5', 'color': Colors.indigo},
    {'name': 'expenses_color_pink'.tr, 'value': '#E91E63', 'color': Colors.pink},
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseCategoryController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('expenses_category_create_title'.tr),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de la page
              Text(
                'expenses_category_create_subtitle'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'expenses_category_create_description'.tr,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Nom de la catégorie
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: '${'expenses_category_name'.tr} *',
                  hintText: 'expenses_category_name_hint'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'expenses_category_name_required'.tr;
                  }
                  if (value.trim().length < 2) {
                    return 'expenses_category_name_min_length'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description (optionnelle)

              // Sélection de couleur
              Text(
                'expenses_category_color'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((colorData) {
                  final isSelected = _selectedColor == colorData['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorData['value'];
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorData['color'],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton.icon(
                          onPressed: controller.isCreating.value ? null : _createCategory,
                          icon: controller.isCreating.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            controller.isCreating.value ? 'expenses_category_creating'.tr : 'expenses_category_create_button'.tr,
                          ),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = Get.find<ExpenseCategoryController>();

    final request = CreateExpenseCategoryRequest(
      nom: _nomController.text.trim(),
      couleur: _selectedColor,
    );

    final success = await controller.createCategory(request);

    if (success) {
      Get.back(); // Retourner à la page précédente
    }
  }
}
