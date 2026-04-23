import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/boutique_controller.dart';
import '../models/boutique_model.dart';

/// Widget de sélection de boutique active — à placer dans le drawer ou l'AppBar
class BoutiqueSelectorWidget extends StatelessWidget {
  const BoutiqueSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BoutiqueController>();

    return Obx(() {
      if (!controller.isMultiBoutique) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.store, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Boutique>(
                  value: controller.boutiquesActive.value,
                  isExpanded: true,
                  isDense: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  items: controller.boutiques
                      .where((b) => b.isActive)
                      .map((b) => DropdownMenuItem(
                            value: b,
                            child: Row(
                              children: [
                                if (b.estPrincipale)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                  ),
                                Expanded(child: Text(b.nom, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (boutique) {
                    if (boutique != null) controller.switchBoutique(boutique);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Badge compact pour l'AppBar indiquant la boutique active
class BoutiqueActiveBadge extends StatelessWidget {
  const BoutiqueActiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BoutiqueController>();

    return Obx(() {
      final boutique = controller.boutiquesActive.value;
      if (boutique == null || !controller.isMultiBoutique) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => _showBoutiqueSelector(context, controller),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.store, size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                boutique.nom,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      );
    });
  }

  void _showBoutiqueSelector(BuildContext context, BoutiqueController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Changer de boutique', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ...controller.boutiques.where((b) => b.isActive).map((b) => ListTile(
                    leading: Icon(
                      b.estPrincipale ? Icons.store : Icons.storefront,
                      color: controller.boutiquesActive.value?.id == b.id ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(b.nom),
                    subtitle: b.adresse != null ? Text(b.adresse!, style: const TextStyle(fontSize: 12)) : null,
                    trailing: controller.boutiquesActive.value?.id == b.id ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                    onTap: () {
                      controller.switchBoutique(b);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          )),
    );
  }
}
