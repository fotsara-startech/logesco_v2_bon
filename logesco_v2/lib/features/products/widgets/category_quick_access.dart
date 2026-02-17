import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

/// Widget d'accès rapide aux catégories
class CategoryQuickAccess extends StatelessWidget {
  const CategoryQuickAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Get.toNamed(AppRoutes.categories),
      icon: const Icon(Icons.category),
      label: const Text('Catégories'),
      backgroundColor: Colors.purple,
      tooltip: 'Gérer les catégories de produits',
    );
  }
}

/// Bouton compact pour les catégories
class CategoryQuickButton extends StatelessWidget {
  const CategoryQuickButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Get.toNamed(AppRoutes.categories),
      icon: const Icon(Icons.category, size: 18),
      label: const Text('Catégories'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

/// Chip cliquable pour les catégories
class CategoryAccessChip extends StatelessWidget {
  const CategoryAccessChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.category, size: 16),
      label: const Text('Gérer les catégories'),
      onPressed: () => Get.toNamed(AppRoutes.categories),
      backgroundColor: Colors.purple.withOpacity(0.1),
      side: BorderSide(color: Colors.purple.withOpacity(0.3)),
    );
  }
}
