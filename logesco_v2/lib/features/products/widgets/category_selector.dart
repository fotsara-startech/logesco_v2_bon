import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';

/// Widget pour sélectionner une catégorie de produits
class CategorySelector extends GetView<ProductController> {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<String>(
          value: controller.selectedCategory.value.isEmpty ? 'Toutes' : controller.selectedCategory.value,
          decoration: const InputDecoration(
            labelText: 'Catégorie',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
          items: controller.categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == 'Toutes') {
              controller.updateSelectedCategory('');
            } else {
              controller.updateSelectedCategory(value ?? '');
            }
          },
        ),
      );
    });
  }
}

/// Widget compact pour le sélecteur de catégories (pour les barres d'outils)
class CompactCategorySelector extends GetView<ProductController> {
  const CompactCategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        constraints: const BoxConstraints(maxWidth: 200),
        child: DropdownButton<String>(
          value: controller.selectedCategory.value.isEmpty ? 'Toutes' : controller.selectedCategory.value,
          isExpanded: true,
          underline: Container(),
          items: controller.categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == 'Toutes') {
              controller.updateSelectedCategory('');
            } else {
              controller.updateSelectedCategory(value ?? '');
            }
          },
        ),
      );
    });
  }
}

/// Chip pour afficher la catégorie sélectionnée
class CategoryChip extends GetView<ProductController> {
  const CategoryChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedCategory.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(
            controller.selectedCategory.value,
            style: const TextStyle(fontSize: 12),
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => controller.updateSelectedCategory(''),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          side: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
      );
    });
  }
}
