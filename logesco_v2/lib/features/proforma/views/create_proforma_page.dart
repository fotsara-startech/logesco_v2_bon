import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../../customers/controllers/customer_controller.dart';
import '../../customers/models/customer.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../sales/widgets/product_selector.dart';
import '../../sales/widgets/cart_widget.dart';
import '../../sales/widgets/quick_billing_view.dart';
import '../bindings/proforma_binding.dart';
import '../controllers/proforma_controller.dart';
import '../models/proforma_invoice.dart';

/// Page dédiée à la création / modification d'une facture proforma.
/// Reprend délibérément la même structure que CreateSalePage (mise en page
/// responsive, raccourcis clavier, disposition des sections) pour que
/// l'expérience soit identique entre les deux écrans — seule la couleur
/// d'accent (orange) distingue visuellement le mode "commande" du mode
/// "vente" (bleu).
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
  int _autocompleteKey = 0; // Clé pour forcer la reconstruction de l'Autocomplete
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _primaryActionFocusNode = FocusNode();
  static const _quickViewStorageKey = 'proforma_quick_view_enabled';
  bool _showQuickView = false;

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

    try {
      _showQuickView = !_isEditing && (GetStorage().read<bool>(_quickViewStorageKey) ?? false);
    } catch (_) {}
  }

  void _setQuickView(bool value) {
    setState(() => _showQuickView = value);
    try {
      GetStorage().write(_quickViewStorageKey, value);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _primaryActionFocusNode.dispose();
    super.dispose();
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

  void _clearCustomerSearch() {
    _autocompleteCtrl?.clear();
    _salesCtrl.setSelectedCustomer(null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_showQuickView) {
      return QuickBillingView(
        title: 'proforma_invoice_label'.tr,
        accentColor: Colors.orange[700]!,
        includePayment: false,
        primaryLabel: 'proforma_save_action'.tr,
        primaryIcon: Icons.description_outlined,
        onSwitchToClassic: () => _setQuickView(false),
        onFinalize: _handleQuickFinalize,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Focus(
        autofocus: true,
        // Raccourcis clavier — mêmes touches que la page de vente :
        // F2 / Ctrl+F : focus sur la recherche produit ; F9 : enregistrer.
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.f2): () => _searchFocusNode.requestFocus(),
            const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => _searchFocusNode.requestFocus(),
            const SingleActivator(LogicalKeyboardKey.f9): () {
              final proformaCtrl = Get.find<ProformaController>();
              if (_canSave(proformaCtrl)) _saveProforma(proformaCtrl);
            },
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              if (isMobile) return _buildMobileLayout();
              return _buildDesktopLayout();
            },
          ),
        ),
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
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
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.white),
            tooltip: 'quick_billing_quick_view'.tr,
            onPressed: () => _setQuickView(true),
          ),
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
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Layouts ───────────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildCustomerSearch(),
          const Divider(height: 1),
          Obx(() {
            final itemCount = _salesCtrl.cartItems.length;
            return TabBar(
              labelColor: Colors.orange[700],
              indicatorColor: Colors.orange[700],
              tabs: [
                const Tab(icon: Icon(Icons.inventory_2), text: 'Produits'),
                Tab(
                  icon: Badge(isLabelVisible: itemCount > 0, label: Text('$itemCount'), child: const Icon(Icons.shopping_cart)),
                  text: 'proforma_order_tab'.tr,
                ),
              ],
            );
          }),
          Expanded(
            child: TabBarView(
              children: [
                ProductSelector(
                  searchFocusNode: _searchFocusNode,
                  primaryActionFocusNode: _primaryActionFocusNode,
                  onProductSelected: (product, qty) async => await _salesCtrl.addToCart(product, quantity: qty),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildClientBanner(),
                      _buildCartSection(),
                      _buildBottomAction(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
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
                    searchFocusNode: _searchFocusNode,
                    primaryActionFocusNode: _primaryActionFocusNode,
                    onProductSelected: (product, qty) async => await _salesCtrl.addToCart(product, quantity: qty),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── DROITE : panier + validation ──────────────────────────────────
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
                  _buildBottomAction(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Recherche client ──────────────────────────────────────────────────────

  Widget _buildCustomerSearch() {
    final createSentinel = Customer(id: -1, nom: '__CREATE__', dateCreation: DateTime(0), dateModification: DateTime(0));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Autocomplete<Customer>(
              key: ValueKey(_autocompleteKey), // Clé pour forcer la reconstruction
              displayStringForOption: (c) => c.id == -1 ? '' : c.nom,
              optionsBuilder: (TextEditingValue tv) {
                if (tv.text.isEmpty) return const Iterable<Customer>.empty();
                final query = tv.text.toLowerCase().trim();
                final matches = _customersCtrl.customers.where((c) => c.nom.toLowerCase().contains(query)).toList();
                final hasExact = matches.any((c) => c.nom.toLowerCase() == query);
                if (!hasExact) matches.add(createSentinel);
                return matches;
              },
              onSelected: (c) {
                if (c.id == -1) {
                  final query = _autocompleteCtrl?.text ?? '';
                  if (query.isNotEmpty) _createAndSelectCustomer(query);
                } else {
                  _salesCtrl.setSelectedCustomer(c);
                  // Client choisi : passer directement au clavier à la
                  // recherche produit, sans toucher la souris.
                  _searchFocusNode.requestFocus();
                }
              },
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
                    suffixIcon: ctrl.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]), onPressed: _clearCustomerSearch) : null,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => setState(() {}),
                  // Entrée : sélectionne le client surligné dans les
                  // suggestions (comportement natif d'Autocomplete).
                  onSubmitted: (_) => onSubmit(),
                );
              },
              optionsViewBuilder: (ctx, onSelected, options) {
                final query = _autocompleteCtrl?.text ?? '';
                final realOptions = options.where((c) => c.id != -1).toList();
                final showCreate = options.any((c) => c.id == -1);
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 320,
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (realOptions.isNotEmpty)
                            Flexible(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shrinkWrap: true,
                                itemCount: realOptions.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                                itemBuilder: (context, i) {
                                  final c = realOptions[i];
                                  final solde = c.solde;
                                  final aDette = solde < 0;
                                  // Suivi natif d'Autocomplete pour la navigation
                                  // au clavier (flèches haut/bas) dans la liste.
                                  final isHighlighted = AutocompleteHighlightedOption.of(context) == i;
                                  return Container(
                                    color: isHighlighted ? Colors.orange[50] : null,
                                    child: ListTile(
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
                                              decoration: BoxDecoration(color: aDette ? Colors.red[50] : Colors.green[50], borderRadius: BorderRadius.circular(4)),
                                              child: Text(
                                                '${aDette ? "sales_customer_debt".tr : "sales_customer_credit".tr}: ${solde.abs().toStringAsFixed(0)}',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: aDette ? Colors.red[700] : Colors.green[700]),
                                              ),
                                            )
                                          : null,
                                      onTap: () => onSelected(c),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (showCreate) ...[
                            if (realOptions.isNotEmpty) Divider(height: 1, color: Colors.grey[200]),
                            Builder(builder: (context) {
                              final isHighlighted = AutocompleteHighlightedOption.of(context) == realOptions.length;
                              return Container(
                                color: isHighlighted ? Colors.orange[50] : null,
                                child: InkWell(
                                  onTap: () => _createAndSelectCustomer(query),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_add, size: 18, color: Colors.orange[700]),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text('Créer "$query"', style: TextStyle(fontSize: 14, color: Colors.orange[700], fontWeight: FontWeight.w500))),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
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

  Future<void> _createAndSelectCustomer(String nom) async {
    FocusScope.of(context).unfocus();
    try {
      final newCustomer = await _customersCtrl.createCustomer(CustomerForm(nom: nom.trim()));
      if (newCustomer != null) {
        _salesCtrl.setSelectedCustomer(newCustomer);
        _autocompleteCtrl?.text = newCustomer.nom;
        // Incrémenter la clé pour forcer la reconstruction de l'Autocomplete
        setState(() {
          _autocompleteKey++;
        });
        _searchFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du client: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Bannière client sélectionné ───────────────────────────────────────────

  Widget _buildClientBanner() {
    return Obx(() {
      final customer = _salesCtrl.selectedCustomer;
      if (customer == null) return const SizedBox.shrink();
      final solde = customer.solde;
      final aDette = solde < 0;
      final labelSolde = aDette ? "sales_customer_debt".tr : "sales_customer_credit".tr;

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.orange[600]!, Colors.orange[700]!]),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
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
                    Text(labelSolde, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                    Text('${solde.abs().toStringAsFixed(0)} F', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: aDette ? Colors.red[700] : Colors.green[700])),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: _clearCustomerSearch,
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
          // CartWidget s'ajuste à son contenu et affiche déjà sous-total/
          // remise/total — inutile de les dupliquer ici (voir cart_widget.dart).
          CartWidget(
            onQuantityChanged: (productId, quantity) => _salesCtrl.updateCartItemQuantity(productId, quantity),
            onPriceChanged: (productId, price) => _salesCtrl.updateCartItemPrice(productId, price),
            onRemoveItem: (productId) => _salesCtrl.removeFromCart(productId),
          ),
        ],
      ),
    );
  }

  // ── Bas de page : total + action principale ────────────────────────────────

  bool _canSave(ProformaController proformaCtrl) {
    final hasItems = _salesCtrl.cartItems.isNotEmpty;
    final hasCustomer = _salesCtrl.selectedCustomer != null;
    return hasItems && hasCustomer && !proformaCtrl.isSaving && !_salesCtrl.hasCartValidationError;
  }

  Widget _buildBottomAction() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Résumé total — même bandeau que la page de vente
          Obx(() {
            final total = _salesCtrl.cartTotal;
            final itemCount = _salesCtrl.cartItems.length;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('total'.tr, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${total.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'sales_cart_items_count'.trParams({'count': itemCount.toString()}),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Bouton principal : Enregistrer / Mettre à jour la commande
          Padding(
            padding: const EdgeInsets.all(16),
            child: GetBuilder<ProformaController>(
              builder: (proformaCtrl) => Obx(() {
                final canSave = _canSave(proformaCtrl);
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    focusNode: _primaryActionFocusNode,
                    onPressed: canSave ? () => _saveProforma(proformaCtrl) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: proformaCtrl.isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.description_outlined, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                _salesCtrl.cartItems.isEmpty
                                    ? 'sales_cart_empty_action'.tr
                                    : (_isEditing ? 'proforma_update'.tr : 'proforma_save_action'.tr),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                );
              }),
            ),
          ),

          // Note + raccourcis clavier — même style que la page de vente
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Text(
                  'proforma_no_stock_movement'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  'proforma_keyboard_shortcuts'.tr,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logique sauvegarde ────────────────────────────────────────────────────

  /// Finalisation depuis la vue rapide : contrairement à _saveProforma, ne
  /// quitte pas la page après enregistrement — la vue rapide boucle sur
  /// Client pour saisir la commande suivante sans repasser par la liste.
  Future<bool> _handleQuickFinalize(double _) async {
    if (_salesCtrl.cartItems.isEmpty) return false;
    final proformaCtrl = Get.find<ProformaController>();
    final proforma = await proformaCtrl.createFromCart(_salesCtrl);
    if (proforma != null) {
      _salesCtrl.clearCart();
      return true;
    }
    return false;
  }

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
