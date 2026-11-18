import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../products/models/product.dart';
import '../controllers/sales_controller.dart';
import '../models/sale.dart';

/// Dialogue « annuler et remplacer » : choisit le produit de remplacement et la
/// quantité, affiche l'écart de prix estimé (même formule que le backend, voir
/// POST /sales/:id/replace-item) et le montant à encaisser si le nouveau
/// produit coûte plus cher.
class ReplaceItemDialog extends StatefulWidget {
  final Sale sale;
  final SaleDetail detail;

  const ReplaceItemDialog({super.key, required this.sale, required this.detail});

  @override
  State<ReplaceItemDialog> createState() => _ReplaceItemDialogState();
}

class _ReplaceItemDialogState extends State<ReplaceItemDialog> {
  final SalesController _controller = Get.find<SalesController>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();

  Product? _selected;
  String _query = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.detail.quantite.toString();
    if (_controller.productsForSale.isEmpty) {
      _controller.loadProductsForSale().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;
  double get _paid => double.tryParse(_paidController.text.trim().replaceAll(',', '.')) ?? 0;

  /// Écart TTC estimé : le total suit le sous-total (la remise et la TVA
  /// globales sont réparties au prorata, comme côté serveur).
  double get _ecart {
    final product = _selected;
    if (product == null || _quantity < 1) return 0;
    final oldSub = widget.sale.sousTotal;
    final newSub = (oldSub - widget.detail.montantLigne + _quantity * product.prixUnitaire).clamp(0.0, double.infinity);
    final ratio = oldSub > 0 ? newSub / oldSub : 1.0;
    return (widget.sale.montantTotal * ratio) - widget.sale.montantTotal;
  }

  double get _supplement => _ecart > 0.005 ? _ecart : 0;
  bool get _needsFullPayment => _supplement > 0 && widget.sale.client == null;

  bool get _canSubmit {
    if (_selected == null || _quantity < 1 || _submitting) return false;
    if (_paid > _supplement + 0.005) return false;
    if (_needsFullPayment && _paid < _supplement - 0.005) return false;
    return true;
  }

  Future<void> _submit() async {
    final product = _selected;
    if (product == null) return;
    setState(() => _submitting = true);
    final ok = await _controller.replaceSaleItem(
      widget.sale.id,
      detailId: widget.detail.id,
      produitId: product.id,
      quantite: _quantity,
      montantVerse: _paid,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
    }
  }

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = _controller.productsForSale.where((p) => p.estActif);
    if (q.isEmpty) return list.take(30).toList();
    return list
        .where((p) => p.nom.toLowerCase().contains(q) || p.reference.toLowerCase().contains(q) || (p.codeBarre ?? '').toLowerCase().contains(q))
        .take(30)
        .toList();
  }

  String _lineLabel(SaleDetail d) =>
      '${d.quantite} x ${d.produit?.nom ?? 'sales_product_fallback'.trParams({'id': '${d.produitId}'})}';

  Widget _orderCard({
    required String title,
    required List<Widget> lines,
    required double total,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          ...lines,
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('sales_replace_item_total'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${total.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderLine(String label, double amount, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text('${amount.toStringAsFixed(0)} FCFA', style: style),
        ],
      ),
    );
  }

  /// Ancienne commande (articles actifs + total) puis nouvelle commande
  /// (l'article remplacé est retiré, le nouveau ajouté, total recalculé).
  Widget _buildOrderSummary() {
    final product = _selected!;
    final actifs = widget.sale.details.where((d) => !d.annule).toList();
    final nouvelleLigne = _quantity * product.prixUnitaire;
    final nouveauTotal = widget.sale.montantTotal + _ecart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _orderCard(
          title: 'sales_replace_item_old_order'.tr,
          color: Colors.blueGrey,
          total: widget.sale.montantTotal,
          lines: [
            for (final d in actifs)
              _orderLine(
                _lineLabel(d),
                d.montantLigne,
                style: d.id == widget.detail.id ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red) : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        _orderCard(
          title: 'sales_replace_item_new_order'.tr,
          color: Colors.green.shade700,
          total: nouveauTotal,
          lines: [
            for (final d in actifs)
              if (d.id != widget.detail.id) _orderLine(_lineLabel(d), d.montantLigne),
            _orderLine('$_quantity x ${product.nom}', nouvelleLigne, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final oldName = widget.detail.produit?.nom ?? 'sales_product_fallback'.trParams({'id': '${widget.detail.produitId}'});
    final ecart = _ecart;

    return AlertDialog(
      title: Text('sales_replace_item_title'.tr),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'sales_replace_item_current'.trParams({
                  'product': oldName,
                  'quantity': widget.detail.quantite.toString(),
                  'amount': widget.detail.montantLigne.toStringAsFixed(0),
                }),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: 'sales_replace_item_search'.tr,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                child: ListView(
                  children: _filtered.map((p) {
                    final stock = p.estService ? null : _controller.getProductStock(p.id)?.quantiteDisponible;
                    return ListTile(
                      dense: true,
                      selected: _selected?.id == p.id,
                      title: Text(p.nom),
                      subtitle: Text(stock == null ? p.reference : '${p.reference} • ${'sales_available_stock_count'.trParams({'count': '$stock'})}'),
                      trailing: Text('${p.prixUnitaire.toStringAsFixed(0)} FCFA'),
                      onTap: () => setState(() => _selected = p),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'sales_replace_item_quantity'.tr, border: const OutlineInputBorder(), isDense: true),
                onChanged: (_) => setState(() {}),
              ),
              if (_selected != null && _quantity >= 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ecart > 0.005 ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ecart > 0.005 ? Colors.orange.shade200 : Colors.green.shade200),
                  ),
                  child: Text(
                    ecart > 0.005
                        ? 'sales_replace_item_extra_due'.trParams({'amount': ecart.toStringAsFixed(0)})
                        : ecart < -0.005
                            ? 'sales_replace_item_released'.trParams({'amount': (-ecart).toStringAsFixed(0)})
                            : 'sales_replace_item_same_price'.tr,
                  ),
                ),
              ],
              if (_selected != null && _quantity >= 1) ...[
                const SizedBox(height: 12),
                _buildOrderSummary(),
              ],
              if (_supplement > 0) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _paidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'sales_replace_item_paid_now'.tr,
                    helperText: _needsFullPayment ? 'sales_replace_item_full_payment_required'.tr : 'sales_replace_item_rest_on_credit'.tr,
                    helperMaxLines: 2,
                    suffixText: 'FCFA',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text('no'.tr),
        ),
        ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text('sales_replace_item_confirm'.tr),
        ),
      ],
    );
  }
}
