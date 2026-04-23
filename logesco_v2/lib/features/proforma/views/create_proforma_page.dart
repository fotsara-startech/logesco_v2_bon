import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../customers/controllers/customer_controller.dart';
import '../../customers/models/customer.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../sales/widgets/product_selector.dart';
import '../../sales/widgets/cart_widget.dart';
import '../bindings/proforma_binding.dart';
import '../controllers/proforma_controller.dart';
import '../models/proforma_invoice.dart';

/// Page dédiée à la création / modification d'une facture proforma.
/// Interface identique à la page de vente mais sans paiement ni mouvement de stock.
class CreateProformaPage extends StatefulWidget {
  /// Si non null, on est en mode édition d'une proforma existante
  final ProformaInvoice? editingProforma;

  const CreateProformaPage({super.key, this.editingProforma});

  @override
  State<CreateProformaPage> createState() => _CreateProformaPageState();
}

class _CreateProformaPageState extends State<CreateProformaPage> {
  late SalesController _salesCtrl;
  late CustomerController _customersCtrl;
  TextEditingController? _autocompleteCtrl;

  bool get _isEditing => widget.editingProforma != null;

  @override
  void initState() {
    super.initState();
    // Enregistrer toutes les dépendances nécessaires
    ProformaBinding().dependencies();
    _salesCtrl = Get.find<SalesController>();
    _customersCtrl = Get.find<CustomerController>();

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProformaData());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _salesCtrl.clearCart());
    }
  }

  void _loadProformaData() {
    final p = widget.editingProforma!;
    _salesCtrl.clearCart();
    if (p.client != null) _salesCtrl.setSelectedCustomer(p.client);
    _salesCtrl.setPaymentMode(p.modePaiement);
    _salesCtrl.setDiscount(p.montantRemise);
    _salesCtrl.loadCartItems(p.items.map((i) => i.toCartItem()).toList());
    setState(() {});
  }

  void _clearCustomer() {
    _autocompleteCtrl?.clear();
    _salesCtrl.setSelectedCustomer(null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // ── GAUCHE : sélection produits ──────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildCustomerSearch(),
                  const Divider(height: 1),
                  Expanded(
                    child: ProductSelector(
                      onProductSelected: (product, qty) async {
                        await _salesCtrl.addToCart(product, quantity: qty);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── DROITE : panier + résumé ─────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(left: BorderSide(color: Colors.grey[200]!)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildClientBanner(),
                    _buildCartSection(),
                    _buildSummarySection(),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.orange[700],
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'proforma_edit_title'.tr : 'proforma_create_title'.tr,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
          ),
          Text(
            'proforma_invoice_label'.tr,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(DateTime.now()),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                DateFormat('dd/MM/yy').format(DateTime.now()),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Recherche client ──────────────────────────────────────────────────────

  Widget _buildCustomerSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Autocomplete<Customer>(
              optionsBuilder: (TextEditingValue value) {
                if (value.text.isEmpty) return const Iterable<Customer>.empty();
                return _customersCtrl.customers.where((c) => c.nom.toLowerCase().contains(value.text.toLowerCase()));
              },
              onSelected: (c) => _salesCtrl.setSelectedCustomer(c),
              fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                _autocompleteCtrl = ctrl;
                return TextField(
                  controller: ctrl,
                  focusNode: focus,
                  decoration: InputDecoration(
                    hintText: 'sales_search_customer'.tr,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.orange, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                    suffixIcon: ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                            onPressed: _clearCustomer,
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => setState(() {}),
                );
              },
              optionsViewBuilder: (ctx, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 320,
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (_, i) {
                          final c = options.elementAt(i);
                          final solde = c.solde ?? 0.0;
                          final aDette = solde < 0;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.orange[100],
                              child: Text(c.nom[0].toUpperCase(), style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            title: Text(c.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: c.telephone != null ? Text(c.telephone!, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
                            trailing: solde != 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: aDette ? Colors.red[50] : Colors.green[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${aDette ? "Dette" : "Crédit"}: ${(-solde).abs().toStringAsFixed(0)} F',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: aDette ? Colors.red[700] : Colors.green[700]),
                                    ),
                                  )
                                : null,
                            onTap: () => onSelected(c),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Bannière client sélectionné ───────────────────────────────────────────

  Widget _buildClientBanner() {
    return Obx(() {
      final customer = _salesCtrl.selectedCustomer;
      if (customer == null) return const SizedBox.shrink();
      final solde = customer.solde ?? 0.0;
      final aDette = solde < 0;
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.orange[600]!, Colors.orange[700]!]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(customer.nom[0].toUpperCase(), style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.nom, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  if (customer.telephone != null) Text(customer.telephone!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
                ],
              ),
            ),
            if (solde != 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: Column(
                  children: [
                    Text(aDette ? 'Dette' : 'Crédit', style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                    Text('${(-solde).abs().toStringAsFixed(0)} F', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: aDette ? Colors.red[700] : Colors.green[700])),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: _clearCustomer,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    });
  }

  // ── Section panier ────────────────────────────────────────────────────────

  Widget _buildCartSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              children: [
                Icon(Icons.shopping_cart_outlined, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                Text('sales_cart'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
                      child: Text('${_salesCtrl.cartItems.length}', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600, fontSize: 12)),
                    )),
              ],
            ),
          ),
          // Liste articles
          Obx(() {
            final count = _salesCtrl.cartItems.length;
            final height = count == 0 ? MediaQuery.of(context).size.height * 0.35 : count * 250.0;
            return SizedBox(
              height: height,
              child: CartWidget(
                onQuantityChanged: _salesCtrl.updateCartItemQuantity,
                onPriceChanged: _salesCtrl.updateCartItemPrice,
                onRemoveItem: _salesCtrl.removeFromCart,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Résumé & remise ───────────────────────────────────────────────────────

  Widget _buildSummarySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.orange[700], size: 18),
              const SizedBox(width: 8),
              Text('proforma_invoice_label'.tr, style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const Divider(height: 20),

          // Résumé des montants
          Obx(() {
            final subtotal = _salesCtrl.cartSubtotal;
            final discount = _salesCtrl.discount; // Calculé automatiquement
            final total = _salesCtrl.cartTotal;

            return Column(
              children: [
                // Sous-total (prix originaux)
                _summaryRow('proforma_subtotal'.tr, '${subtotal.toStringAsFixed(0)} FCFA'),

                // Remise totale (si applicable)
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.discount, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Remise appliquée sur les produits',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '-${discount.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),

          const Divider(height: 20),

          // Total final
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('proforma_total'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '${_salesCtrl.cartTotal.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              )),

          const SizedBox(height: 12),

          // Note informative sur les remises
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les remises sont appliquées directement sur le prix unitaire de chaque produit dans le panier.',
                    style: TextStyle(fontSize: 11, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Note informative sur la proforma
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'proforma_no_stock_movement'.tr,
                    style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }

  // ── Boutons d'action ──────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: GetBuilder<ProformaController>(
        builder: (proformaCtrl) => Column(
          children: [
            // Bouton principal : Enregistrer la proforma
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: proformaCtrl.isSaving || _salesCtrl.cartItems.isEmpty ? null : () => _saveProforma(proformaCtrl),
                icon: proformaCtrl.isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.description_outlined, size: 22),
                label: Text(
                  proformaCtrl.isSaving
                      ? 'proforma_saving'.tr
                      : _isEditing
                          ? 'proforma_update'.tr
                          : 'proforma_save_action'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Bouton secondaire : Annuler
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('cancel'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logique sauvegarde ────────────────────────────────────────────────────

  Future<void> _saveProforma(ProformaController proformaCtrl) async {
    if (_salesCtrl.cartItems.isEmpty) return;

    if (_isEditing) {
      final ok = await proformaCtrl.updateFromCart(widget.editingProforma!.id, _salesCtrl);
      if (ok) {
        _salesCtrl.clearCart();
        Get.back();
      }
    } else {
      final proforma = await proformaCtrl.createFromCart(_salesCtrl);
      if (proforma != null) {
        _salesCtrl.clearCart();
        Get.back();
      }
    }
  }
}
