import 'package:flutter/material.dart';

import '../models/movement_category.dart';

/// Widget de sélection de catégorie pour les mouvements financiers
class CategorySelector extends StatelessWidget {
  final List<MovementCategory> categories;
  final int? selectedCategoryId;
  final void Function(int?) onCategorySelected;
  final bool isRequired;
  final String? errorText;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.isRequired = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie${isRequired ? ' *' : ''}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final isSelected = selectedCategoryId == category.id;
              return FilterChip(
                label: Text(category.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  onCategorySelected(selected ? category.id : null);
                },
                avatar: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    shape: BoxShape.circle,
                  ),
                ),
                selectedColor: _getCategoryColor(category).withOpacity(0.2),
                checkmarkColor: _getCategoryColor(category),
              );
            }).toList(),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Color _getCategoryColor(MovementCategory category) {
    try {
      return Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Widget de sélection de catégorie en dropdown
class CategoryDropdown extends StatelessWidget {
  final List<MovementCategory> categories;
  final int? selectedCategoryId;
  final void Function(int?) onCategorySelected;
  final bool isRequired;
  final String? labelText;
  final String? hintText;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.isRequired = false,
    this.labelText,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: selectedCategoryId,
      decoration: InputDecoration(
        labelText: labelText != null ? '$labelText${isRequired ? ' *' : ''}' : null,
        hintText: hintText ?? 'Sélectionnez une catégorie',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: categories.map((category) {
        return DropdownMenuItem<int>(
          value: category.id,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onCategorySelected,
      validator: isRequired
          ? (value) {
              if (value == null) {
                return 'Veuillez sélectionner une catégorie';
              }
              return null;
            }
          : null,
    );
  }

  Color _getCategoryColor(MovementCategory category) {
    try {
      return Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Widget de badge de catégorie
class CategoryBadge extends StatelessWidget {
  final MovementCategory category;
  final double size;
  final bool showIcon;

  const CategoryBadge({
    super.key,
    required this.category,
    this.size = 24,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor().withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getCategoryIcon(),
              size: size * 0.7,
              color: _getCategoryColor(),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            category.displayName,
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w500,
              color: _getCategoryColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    try {
      return Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (category.icon) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'people':
        return Icons.people;
      case 'build':
        return Icons.build;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.receipt;
    }
  }
}
