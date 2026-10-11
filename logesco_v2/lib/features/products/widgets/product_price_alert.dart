import 'package:flutter/material.dart';

/// Bandeau d'alerte de la liste des produits : des produits sont vendus moins cher que leur prix d'achat.
///
/// Invisible s'il n'y en a pas. Le bouton filtre la liste sur ces seuls produits, pour les repérer et les
/// corriger rapidement (chaque carte concernée propose un accès direct à la modification).
class ProductPriceAlert extends StatelessWidget {
  /// Nombre de produits dont le prix de vente est inférieur au prix d'achat
  final int count;

  /// La liste est déjà filtrée sur ces produits
  final bool filtering;

  /// Affiche (ou retire) le filtre
  final VoidCallback onToggle;

  final EdgeInsetsGeometry margin;

  const ProductPriceAlert({super.key, required this.count, required this.filtering, required this.onToggle, this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 0)});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.red.shade300)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.trending_down, color: Colors.red.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1 ? '1 produit vendu moins cher que son prix d\'achat' : '$count produits vendus moins cher que leur prix d\'achat',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      'Chaque vente fait perdre de l\'argent : vérifiez le prix de vente ou le prix d\'achat.',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onToggle, child: Text(filtering ? 'Tout afficher' : 'Voir ces produits')),
            ],
          ),
        ),
      ),
    );
  }
}
