import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/permission_service.dart';
import '../services/service_products_review_service.dart';
import '../views/service_products_review_page.dart';

/// Bannière « Produits à vérifier » : s'affiche seulement s'il existe des produits marqués
/// « service » qui ont pourtant reçu du stock. Invisible sinon (et pour les utilisateurs
/// qui n'ont pas le droit de modifier les produits).
class ServiceProductsAlert extends StatefulWidget {
  /// Marges autour de la bannière (selon l'écran qui l'accueille)
  final EdgeInsetsGeometry margin;

  /// Pour les tests : service de remplacement
  final ServiceProductsReviewService? service;

  const ServiceProductsAlert({super.key, this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 0), this.service});

  @override
  State<ServiceProductsAlert> createState() => _ServiceProductsAlertState();
}

class _ServiceProductsAlertState extends State<ServiceProductsAlert> {
  late final ServiceProductsReviewService _service = widget.service ?? ServiceProductsReviewService();
  List<ServiceProductToReview> _items = const [];

  bool get _autorise {
    // Sans le droit de modifier un produit, la bannière ne servirait à rien
    if (!Get.isRegistered<PermissionService>()) return true;
    return PermissionService.to.hasPermission('products', 'UPDATE');
  }

  @override
  void initState() {
    super.initState();
    if (_autorise) _load();
  }

  Future<void> _load() async {
    final items = await _service.fetch();
    if (mounted && items != null) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final unites = _items.fold<int>(0, (s, p) => s + p.quantiteVendue);

    return Padding(
      padding: widget.margin,
      child: Material(
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.orange.shade300)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            await Get.to(() => const ServiceProductsReviewPage());
            _load(); // la liste a pu changer
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_items.length} produit(s) marqué(s) « service » ont du stock — à vérifier',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (unites > 0)
                        Text(
                          '$unites unité(s) vendues n\'ont jamais diminué le stock',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
