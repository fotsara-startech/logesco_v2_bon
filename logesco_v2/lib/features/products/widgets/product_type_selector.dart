import 'package:flutter/material.dart';

/// Choix du type de produit : produit physique (stock suivi) ou service (aucun stock).
///
/// Placé tout en haut du formulaire : c'est le choix qui détermine les champs à remplir, et le confondre avec un
/// simple interrupteur en bas de page a conduit à des produits physiques enregistrés comme services.
///
///  - Création : aucun type n'est présélectionné ; tant qu'il n'est pas choisi, le reste du formulaire reste caché.
///  - Modification : le type actuel est sélectionné ; en choisir un autre ouvre une boîte de dialogue qui explique
///    clairement les répercussions, et ne change rien tant que la personne n'a pas confirmé.
class ProductTypeSelector extends StatelessWidget {
  /// null = pas encore choisi (création) ; true = service ; false = produit physique
  final bool? estService;

  /// Modification d'un produit existant : un changement de type demande confirmation
  final bool enEdition;

  /// Appelé quand le type est choisi (après confirmation, en modification)
  final void Function(bool service) onChoisi;

  const ProductTypeSelector({super.key, required this.estService, required this.enEdition, required this.onChoisi});

  Future<void> _choisir(BuildContext context, bool service) async {
    if (estService == service) return;
    if (enEdition && estService != null) {
      final confirme = await confirmerChangementDeType(context, versService: service);
      if (confirme != true) return;
    }
    onChoisi(service);
  }

  @override
  Widget build(BuildContext context) {
    final choisi = estService != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          enEdition ? 'Type' : '1. Quel type de produit ?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          choisi
              ? (enEdition ? 'Changer le type a des conséquences sur le stock : une explication vous sera présentée.' : 'Vous pouvez encore changer avant de continuer.')
              : 'Choisissez d\'abord : ce choix détermine les champs à remplir et la gestion du stock.',
          style: TextStyle(fontSize: 12, color: choisi ? Colors.grey.shade700 : Colors.orange.shade800),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final carteProduit = _carte(
            context,
            key: const ValueKey('type-produit'),
            service: false,
            icone: Icons.inventory_2,
            couleur: Colors.orange,
            titre: 'Produit',
            description: 'Article en stock : le stock est suivi, avec prix d\'achat, seuil minimum et péremption.',
          );
          final carteService = _carte(
            context,
            key: const ValueKey('type-service'),
            service: true,
            icone: Icons.design_services,
            couleur: Colors.blue,
            titre: 'Service',
            description: 'Prestation sans stock (livraison, installation, main-d\'œuvre…).',
          );
          // Côte à côte si la place le permet, sinon l'un sous l'autre (téléphone)
          if (c.maxWidth >= 520) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: carteProduit), const SizedBox(width: 12), Expanded(child: carteService)]);
          }
          return Column(children: [carteProduit, const SizedBox(height: 8), carteService]);
        }),
      ],
    );
  }

  Widget _carte(
    BuildContext context, {
    required Key key,
    required bool service,
    required IconData icone,
    required Color couleur,
    required String titre,
    required String description,
  }) {
    final selectionne = estService == service;
    return Material(
      key: key,
      color: selectionne ? couleur.withValues(alpha: 0.10) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selectionne ? couleur : Colors.grey.shade300, width: selectionne ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _choisir(context, service),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: couleur, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        if (selectionne) ...[const SizedBox(width: 6), Icon(Icons.check_circle, color: couleur, size: 18)],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explique clairement les répercussions d'un changement de type sur un produit existant.
/// Retourne true si la personne confirme. Le changement n'est enregistré qu'à la sauvegarde du formulaire.
Future<bool?> confirmerChangementDeType(BuildContext context, {required bool versService}) {
  final points = versService
      ? const [
          'Le stock n\'est plus suivi : les ventes ne diminuent plus aucune quantité, et les réceptions de commande, inventaires et ajustements ne pourront plus y ajouter de stock.',
          'Le stock déjà enregistré pour ce produit n\'est plus mis à jour ni utilisé.',
          'Le prix d\'achat, le seuil de stock minimum et la gestion de péremption ne s\'appliquent plus (ils seront vidés).',
          'Les ventes déjà faites ne changent pas.',
        ]
      : const [
          'Le produit sera géré en stock : chaque vente diminuera sa quantité, et il apparaîtra dans les réceptions, inventaires et alertes de stock.',
          'Son stock de départ est probablement à 0 : enregistrez une réception ou un inventaire avant de le vendre.',
          'Vous pourrez renseigner le prix d\'achat, le seuil de stock minimum et la péremption.',
          'Les ventes déjà faites ne changent pas.',
        ];
  final avertissement = versService
      ? 'À faire seulement pour une vraie prestation (livraison, installation, main-d\'œuvre…). Un article que vous stockez ne doit jamais être un service : ses ventes ne diminueraient plus le stock.'
      : null;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(versService ? 'Passer ce produit en SERVICE ?' : 'Passer ce service en PRODUIT (stock suivi) ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ce que cela change :', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...points.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const Text('•  '), Expanded(child: Text(p, style: const TextStyle(fontSize: 13)))],
                  ),
                )),
            if (avertissement != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.orange.shade300), borderRadius: BorderRadius.circular(8)),
                child: Text(avertissement, style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
              ),
            ],
            const SizedBox(height: 10),
            Text('Le changement ne sera enregistré que lorsque vous cliquerez sur « Modifier ».', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(versService ? 'Passer en service' : 'Passer en produit')),
      ],
    ),
  );
}
