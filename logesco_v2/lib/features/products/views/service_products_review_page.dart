import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../services/service_products_review_service.dart';

/// Produits marqués « service » qui ont pourtant reçu du stock.
///
/// Un service n'a pas de stock : une vente ne le diminue jamais. Un produit physique marqué
/// « service » par erreur voit donc son stock monter à chaque réception et ne jamais redescendre.
class ServiceProductsReviewPage extends StatefulWidget {
  /// Pour les tests : service de remplacement
  final ServiceProductsReviewService? service;

  const ServiceProductsReviewPage({super.key, this.service});

  @override
  State<ServiceProductsReviewPage> createState() => _ServiceProductsReviewPageState();
}

class _ServiceProductsReviewPageState extends State<ServiceProductsReviewPage> {
  late final ServiceProductsReviewService _service = widget.service ?? ServiceProductsReviewService();
  List<ServiceProductToReview>? _items;
  bool _loading = true;
  final Set<int> _working = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _service.fetch();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _markPhysical(ServiceProductToReview p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remettre en produit physique ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Ce produit sera de nouveau géré en stock : ses prochaines ventes diminueront son stock.'),
            const SizedBox(height: 8),
            Text(
              p.aDesVentesSansSortie
                  ? 'Cela ne corrige pas le stock affiché (${p.stockAffiche}) : les ${p.quantiteVendue} unité(s) déjà vendues n\'en sont pas sorties. '
                      'Ce rattrapage est à faire séparément.'
                  : 'Le stock affiché (${p.stockAffiche}) et l\'historique ne sont pas modifiés.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui, c\'est un produit physique')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _working.add(p.id));
    try {
      await _service.markPhysical(p.id);
      SnackbarHelper.success('« ${p.nom} » est de nouveau un produit physique');
      await _load();
    } catch (e) {
      SnackbarHelper.error(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _working.remove(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits à vérifier'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Actualiser')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('Impossible de charger la liste (serveur injoignable ou trop ancien).', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _items!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade400),
                          const SizedBox(height: 12),
                          const Text('Aucun produit à vérifier', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    )
                  : _buildList(_items!),
    );
  }

  Widget _buildList(List<ServiceProductToReview> items) {
    final unites = items.fold<int>(0, (s, p) => s + p.quantiteVendue);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.orange.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${items.length} produit(s) marqué(s) « service » ont du stock',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Un service n\'a pas de stock : une vente ne le diminue jamais. Un produit physique marqué « service » '
                  'par erreur voit donc son stock monter à chaque réception et ne jamais redescendre.',
                  style: TextStyle(fontSize: 13),
                ),
                if (unites > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$unites unité(s) ont été vendues sans sortir du stock.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade800),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(_buildTile),
        const SizedBox(height: 8),
        Text(
          'Si un produit est bien un service, ne lui recevez pas de stock : le serveur refuse désormais ces réceptions.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTile(ServiceProductToReview p) {
    final busy = _working.contains(p.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (p.reference.isNotEmpty) Text('Réf. ${p.reference}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip('Reçu : ${p.quantiteRecue}', Colors.blue),
                _chip('Vendu : ${p.quantiteVendue}', Colors.purple),
                _chip('Stock affiché : ${p.stockAffiche}', Colors.teal),
              ],
            ),
            if (p.aDesVentesSansSortie) ...[
              const SizedBox(height: 8),
              Text(
                '${p.quantiteVendue} unité(s) vendue(s) sans sortie de stock : le stock affiché est probablement trop élevé de ${p.quantiteVendue}.',
                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _markPhysical(p),
                icon: busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('C\'est un produit physique'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, MaterialColor color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.shade200)),
        child: Text(text, style: TextStyle(fontSize: 12, color: color.shade800, fontWeight: FontWeight.w600)),
      );
}
