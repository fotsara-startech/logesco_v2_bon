import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/boutique_controller.dart';

/// Widget d'indicateur de contexte boutique - affiche la boutique active
/// et permet de détecter rapidement les problèmes de contexte
class BoutiqueContextIndicator extends StatelessWidget {
  final bool showWarningIfNone;
  final bool compact;

  const BoutiqueContextIndicator({
    super.key,
    this.showWarningIfNone = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BoutiqueController>();

    return Obx(() {
      final boutique = controller.boutiquesActive.value;

      if (boutique == null) {
        if (!showWarningIfNone) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orange),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                'Aucune boutique active',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      if (compact) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                boutique.estPrincipale ? Icons.store : Icons.storefront,
                size: 14,
                color: Colors.white, //Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                boutique.nom,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white, //Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              boutique.estPrincipale ? Icons.store : Icons.storefront,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  boutique.nom,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (boutique.adresse != null)
                  Text(
                    boutique.adresse!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Widget de debug pour afficher l'ID de la boutique active
class BoutiqueDebugInfo extends StatelessWidget {
  const BoutiqueDebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BoutiqueController>();

    return Obx(() {
      final boutiqueId = controller.activeBoutiqueId;
      final boutique = controller.boutiquesActive.value;

      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DEBUG - Contexte Boutique',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${boutiqueId ?? "null"}',
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
            Text(
              'Nom: ${boutique?.nom ?? "null"}',
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
            Text(
              'Principale: ${boutique?.estPrincipale ?? false}',
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    });
  }
}
