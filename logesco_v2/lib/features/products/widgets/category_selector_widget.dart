import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/category_management_service.dart';

/// Widget pour sélectionner ou créer une catégorie
class CategorySelectorWidget extends StatefulWidget {
  final String? initialValue;
  final Function(String?) onChanged;
  final List<Category> availableCategories;
  final bool enabled;

  const CategorySelectorWidget({
    super.key,
    this.initialValue,
    required this.onChanged,
    required this.availableCategories,
    this.enabled = true,
  });

  @override
  State<CategorySelectorWidget> createState() => _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<CategorySelectorWidget> {
  final TextEditingController _textController = TextEditingController();
  final CategoryManagementService _categoryService = Get.find<CategoryManagementService>();

  String? _selectedValue;
  bool _isCreatingCategory = false;
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _textController.text = widget.initialValue ?? '';
    _filteredCategories = widget.availableCategories;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _filterCategories(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = widget.availableCategories;
      } else {
        _filteredCategories = widget.availableCategories.where((cat) => cat.nom.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  Future<void> _createNewCategory(String categoryName) async {
    if (categoryName.trim().isEmpty) return;

    setState(() {
      _isCreatingCategory = true;
    });

    try {
      final newCategory = await _categoryService.createCategoryIfNotExists(
        categoryName.trim(),
        description: 'Créée automatiquement lors de la saisie produit',
      );

      // Ajouter la nouvelle catégorie à la liste
      widget.availableCategories.add(newCategory);
      _filteredCategories = widget.availableCategories;

      // Sélectionner la nouvelle catégorie
      _selectedValue = newCategory.nom;
      _textController.text = newCategory.nom;
      widget.onChanged(newCategory.nom);

      Get.snackbar(
        'Succès',
        'Catégorie "${newCategory.nom}" créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer la catégorie: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() {
        _isCreatingCategory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ de saisie avec autocomplétion
        Autocomplete<Category>(
          initialValue: TextEditingValue(text: widget.initialValue ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return widget.availableCategories;
            }
            return widget.availableCategories.where((Category category) {
              return category.nom.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          displayStringForOption: (Category category) => category.nom,
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            // Synchroniser avec notre contrôleur
            if (textEditingController.text != _textController.text) {
              _textController.text = textEditingController.text;
            }

            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              enabled: widget.enabled,
              decoration: InputDecoration(
                labelText: 'Catégorie',
                prefixIcon: const Icon(Icons.category),
                border: const OutlineInputBorder(),
                helperText: widget.availableCategories.isEmpty ? 'Aucune catégorie disponible' : '${widget.availableCategories.length} catégorie(s) disponible(s)',
                suffixIcon: _isCreatingCategory
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) {
                _filterCategories(value);
                widget.onChanged(value.isEmpty ? null : value);
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length + 1, // +1 pour l'option "Créer nouvelle catégorie"
                    itemBuilder: (context, index) {
                      if (index == options.length) {
                        // Option pour créer une nouvelle catégorie
                        final currentText = _textController.text.trim();
                        if (currentText.isEmpty) return const SizedBox.shrink();

                        final categoryExists = options.any((cat) => cat.nom.toLowerCase() == currentText.toLowerCase());

                        if (categoryExists) return const SizedBox.shrink();

                        return ListTile(
                          leading: const Icon(Icons.add, color: Colors.green),
                          title: Text('Créer "$currentText"'),
                          subtitle: const Text('Nouvelle catégorie'),
                          onTap: () {
                            _createNewCategory(currentText);
                          },
                        );
                      }

                      final Category category = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.category),
                        title: Text(category.nom),
                        subtitle: category.description != null ? Text(category.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                        onTap: () {
                          onSelected(category);
                          widget.onChanged(category.nom);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (Category category) {
            _selectedValue = category.nom;
            _textController.text = category.nom;
            widget.onChanged(category.nom);
          },
        ),

        // Boutons d'action rapide
        if (widget.availableCategories.isEmpty) ...[
          const SizedBox(height: 8),
          _buildQuickActions(),
        ],
      ],
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 8,
      children: [
        // Bouton pour créer une catégorie rapide
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: const Text('Créer catégorie'),
          onPressed: widget.enabled ? _showCreateCategoryDialog : null,
        ),

        // Bouton pour actualiser les catégories
        ActionChip(
          avatar: const Icon(Icons.refresh, size: 16),
          label: const Text('Actualiser'),
          onPressed: widget.enabled ? _refreshCategories : null,
        ),
      ],
    );
  }

  void _showCreateCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Créer une nouvelle catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la catégorie *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Get.back();
                await _createNewCategory(name);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCategories() async {
    try {
      final categories = await _categoryService.getCategories(forceRefresh: true);
      setState(() {
        widget.availableCategories.clear();
        widget.availableCategories.addAll(categories);
        _filteredCategories = categories;
      });

      Get.snackbar(
        'Succès',
        '${categories.length} catégories rechargées',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de recharger les catégories: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
