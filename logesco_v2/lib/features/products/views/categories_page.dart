import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import '../../../core/widgets/permission_widget.dart';
import '../../../core/services/permission_service.dart';

/// Page de gestion des catégories avec base de données
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CategoryController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des catégories...'),
              ],
            ),
          );
        }

        if (controller.error.value.isNotEmpty && controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.error.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.loadCategories,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune catégorie',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par créer votre première catégorie',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddCategoryDialog(controller),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une catégorie'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final category = controller.categories[index];
              return _buildCategoryCard(context, category, controller);
            },
          ),
        );
      }),
      floatingActionButton: PermissionWidget(
        module: 'categories',
        privilege: 'CREATE',
        child: FloatingActionButton(
          onPressed: () => _showAddCategoryDialog(controller),
          tooltip: 'Ajouter une catégorie',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category, CategoryController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          radius: 24,
          child: Icon(
            Icons.category,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          category.nom,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description != null && category.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                category.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Créée le ${_formatDate(category.dateCreation)}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: _buildCategoryActionsMenu(category, controller),
        onTap: () => controller.selectCategory(category),
      ),
    );
  }

  /// Construit le menu d'actions avec permissions
  Widget _buildCategoryActionsMenu(Category category, CategoryController controller) {
    final permissionService = Get.find<PermissionService>();
    final canUpdate = permissionService.hasPermission('categories', 'UPDATE');
    final canDelete = permissionService.hasPermission('categories', 'DELETE');

    if (!canUpdate && !canDelete) {
      return const SizedBox.shrink();
    }

    final items = <PopupMenuEntry<String>>[];

    if (canUpdate) {
      items.add(
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, size: 20),
            title: Text('Modifier'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (canDelete) {
      items.add(
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red, size: 20),
            title: Text('Supprimer', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      onSelected: (action) => _handleCategoryAction(action, category, controller),
      itemBuilder: (context) => items,
    );
  }

  void _handleCategoryAction(String action, Category category, CategoryController controller) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category, controller);
        break;
      case 'delete':
        _showDeleteCategoryDialog(category, controller);
        break;
    }
  }

  void _showAddCategoryDialog(CategoryController controller) {
    _showCategoryDialog(controller);
  }

  void _showEditCategoryDialog(Category category, CategoryController controller) {
    _showCategoryDialog(controller, category: category);
  }

  void _showCategoryDialog(CategoryController controller, {Category? category}) {
    final nameController = TextEditingController(text: category?.nom ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();
    final nameFocusNode = FocusNode();
    final descriptionFocusNode = FocusNode();
    bool _disposed = false; // Flag pour éviter la double disposition

    // Fonction de nettoyage sécurisée
    void _cleanupResources() {
      if (!_disposed) {
        _disposed = true;
        nameController.dispose();
        descriptionController.dispose();
        nameFocusNode.dispose();
        descriptionFocusNode.dispose();
      }
    }

    // Focus automatique après un délai pour éviter les conflits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_disposed && nameFocusNode.canRequestFocus) {
          nameFocusNode.requestFocus();
        }
      });
    });

    Get.dialog(
      PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            // Nettoyer les ressources après fermeture
            _cleanupResources();
          }
        },
        child: AlertDialog(
          title: Text(category == null ? 'Nouvelle catégorie' : 'Modifier la catégorie'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  focusNode: nameFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la catégorie *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    // Passer au champ suivant de manière sécurisée
                    if (descriptionFocusNode.canRequestFocus) {
                      descriptionFocusNode.requestFocus();
                    }
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                    FilteringTextInputFormatter.deny(RegExp(r'[<>]')), // Éviter les caractères problématiques
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  focusNode: descriptionFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    // Retirer le focus seulement
                    descriptionFocusNode.unfocus();
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(200),
                    FilteringTextInputFormatter.deny(RegExp(r'[<>]')), // Éviter les caractères problématiques
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Fermer sans nettoyer (PopScope s'en charge)
                Get.back();
              },
              child: const Text('Annuler'),
            ),
            Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => _submitCategoryForm(formKey, nameController, descriptionController, category, controller),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(category == null ? 'Créer' : 'Modifier'),
                )),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _submitCategoryForm(
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController descriptionController,
    Category? category,
    CategoryController controller,
  ) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    bool success;
    if (category == null) {
      // Création
      success = await controller.addCategory(
        name,
        description: description.isEmpty ? null : description,
      );
    } else {
      // Modification
      success = await controller.updateCategory(
        category,
        name,
        newDescription: description.isEmpty ? null : description,
      );
    }

    if (success) {
      // Fermer le dialogue (PopScope nettoiera les ressources)
      Get.back();

      // Attendre un peu avant d'afficher le message pour éviter les conflits
      Future.delayed(const Duration(milliseconds: 300), () {
        _showSuccessMessage(category == null ? 'Catégorie créée avec succès' : 'Catégorie modifiée avec succès');
      });
    } else {
      // Afficher l'erreur si disponible
      if (controller.error.value.isNotEmpty) {
        _showErrorMessage(controller.error.value);
      }
    }
  }

  void _showDeleteCategoryDialog(Category category, CategoryController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir supprimer la catégorie :'),
            const SizedBox(height: 8),
            Text(
              '"${category.nom}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action est irréversible.',
              style: TextStyle(color: Colors.red[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        final success = await controller.deleteCategory(category);
                        if (success) {
                          Get.back();

                          // Attendre un peu avant d'afficher le message
                          Future.delayed(const Duration(milliseconds: 300), () {
                            _showSuccessMessage('Catégorie supprimée avec succès');
                          });
                        } else {
                          // Afficher l'erreur si disponible
                          if (controller.error.value.isNotEmpty) {
                            _showErrorMessage(controller.error.value);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Supprimer'),
              )),
        ],
      ),
      barrierDismissible: false,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Affiche un message de succès de manière sécurisée
  void _showSuccessMessage(String message) {
    try {
      // Utiliser ScaffoldMessenger pour éviter les conflits GetX
      final context = Get.context;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[800]),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green[100],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'affichage du message de succès: $e');
    }
  }

  /// Affiche un message d'erreur de manière sécurisée
  void _showErrorMessage(String message) {
    try {
      // Utiliser ScaffoldMessenger pour éviter les conflits GetX
      final context = Get.context;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red[800]),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red[100],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'affichage du message d\'erreur: $e');
    }
  }
}
