import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_getx_controller.dart';

/// Dialog pour filtrer par catégorie
class CategoryFilterDialog extends StatelessWidget {
  const CategoryFilterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryGetxController>();

    return AlertDialog(
      title: const Text('Filtrer par catégorie'),
      content: SizedBox(
        width: double.maxFinite,
        child: Obx(() => ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('Toutes les catégories'),
                  leading: Radio<String>(
                    value: '',
                    groupValue: controller.selectedCategory.value,
                    onChanged: (value) => controller.updateSelectedCategory(value ?? ''),
                  ),
                  onTap: () => controller.updateSelectedCategory(''),
                ),
                const Divider(),
                ...controller.categories.map((category) => ListTile(
                      title: Text(category),
                      leading: Radio<String>(
                        value: category,
                        groupValue: controller.selectedCategory.value,
                        onChanged: (value) => controller.updateSelectedCategory(value ?? ''),
                      ),
                      onTap: () => controller.updateSelectedCategory(category),
                    )),
              ],
            )),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}