import 'package:get/get.dart';
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
          enEdition ? 'Type' : 'products_1_quel_type_produit'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          choisi
              ? (enEdition ? 'products_changing_type_has_stock_consequences'.tr : 'products_vous_pouvez_encore_changer_avant_continuer'.tr)
              : 'products_choisissez_abord_choix_determine_champs_remplir'.tr,
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
            titre: 'quick_billing_product'.tr,
            description: 'products_article_stock_stock_est_suivi_avec'.tr,
          );
          final carteService = _carte(
            context,
            key: const ValueKey('type-service'),
            service: true,
            icone: Icons.design_services,
            couleur: Colors.blue,
            titre: 'Service',
            description: 'products_prestation_sans_stock_livraison_installation_main'.tr,
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
      ? [
          'products_stock_n_est_plus_suivi_ventes'.tr,
          'products_stock_deja_enregistre_produit_n_est'.tr,
          'products_prix_achat_seuil_stock_minimum_gestion'.tr,
          'products_ventes_deja_faites_ne_changent_pas'.tr,
        ]
      : [
          'products_produit_sera_gere_stock_chaque_vente'.tr,
          'products_initial_stock_probably_zero'.tr,
          'products_vous_pourrez_renseigner_prix_achat_seuil'.tr,
          'products_ventes_deja_faites_ne_changent_pas'.tr,
        ];
  final avertissement = versService
      ? 'products_faire_seulement_vraie_prestation_livraison_installation'.tr
      : null;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(versService ? 'Passer ce produit en SERVICE ?' : 'products_passer_service_produit_stock_suivi'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('products_que_cela_change'.tr, style: TextStyle(fontWeight: FontWeight.w600)),
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
            Text('products_changement_ne_sera_enregistre_que_lorsque'.tr, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('suppliers_form_cancel'.tr)),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(versService ? 'Passer en service' : 'products_passer_produit'.tr)),
      ],
    ),
  );
}
