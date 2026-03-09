import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expense_category_controller.dart';
import '../models/expense_category.dart';
import 'create_expense_category_page.dart';
import '../../../shared/widgets/empty_states.dart';

class ExpenseCategoriesPage extends StatelessWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExpenseCategoryController());

    return Scaffold(
      appBar: AppBar(
        title: Text('expenses_categories_title'.tr),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.loadCategories,
            icon: const Icon(Icons.refresh),
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.categories.isEmpty) {
          return EmptyState(
            icon: Icons.category_outlined,
            title: 'expenses_categories_empty'.tr,
            subtitle: 'expenses_categories_empty_subtitle'.tr,
            actionText: 'expenses_category_create'.tr,
            onAction: () => Get.to(() => const CreateExpenseCategoryPage()),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadCategories,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final category = controller.categories[index];
              return _buildCategoryCard(category, controller);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreateExpenseCategoryPage()),
        icon: const Icon(Icons.add),
        label: Text('expenses_category_new'.tr),
      ),
    );
  }

  Widget _buildCategoryCard(ExpenseCategory category, ExpenseCategoryController controller) {
    Color categoryColor = Colors.blue;
    try {
      categoryColor = Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      categoryColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: categoryColor.withOpacity(0.3)),
          ),
          child: Icon(
            Icons.category,
            color: categoryColor,
            size: 24,
          ),
        ),
        title: Text(
          category.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'expenses_category_system_name'.trParams({'name': category.nom}),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditDialog(category, controller);
                break;
              case 'delete':
                _showDeleteDialog(category, controller);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: Text('edit'.tr),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ExpenseCategory category, ExpenseCategoryController controller) {
    final nomController = TextEditingController(text: category.displayName);
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: Text('expenses_category_edit'.tr),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'expenses_category_display_name'.tr,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'expenses_category_name_required'.tr;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final request = UpdateExpenseCategoryRequest(
                  nom: nomController.text.trim(),
                  couleur: category.color,
                  estActif: category.isActive,
                );

                final success = await controller.updateCategory(category.id, request);
                if (success) {
                  Get.back();
                }
              }
            },
            child: Text('edit'.tr),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ExpenseCategory category, ExpenseCategoryController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('expenses_category_delete'.tr),
        content: Text('expenses_category_delete_confirm'.trParams({'name': category.displayName})),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.deleteCategory(category.id);
              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}
