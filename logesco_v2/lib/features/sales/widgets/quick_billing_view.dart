import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../../customers/controllers/customer_controller.dart';
import '../../customers/models/customer.dart';
import '../../products/controllers/product_controller.dart';
import '../../products/models/product.dart';
import '../controllers/sales_controller.dart';
import '../models/sale.dart';
import 'product_selector.dart' show showAddToCartQuantityDialog;

/// Vue de facturation 100% clavier : Client → Produit → Montant → Payer,
/// en boucle, sans toucher la souris. Alternative compacte à l'écran
/// classique (panier + paiement), activable via un bouton "Vue rapide".
///
/// Portée de cette première version : la boucle principale du tableau
/// ci-dessous. L'édition d'une ligne au clavier (F3, sélectionner une ligne
/// existante et changer sa quantité sans repasser par le champ Produit)
/// n'est pas encore implémentée — seule la suppression à la souris (icône
/// sur la ligne) est disponible pour corriger une erreur de saisie.
///
/// Moment            Comportement
/// Ouverture         Focus dans Client
/// Frappe            Liste déroulante sous le champ, ↑↓, Entrée valide
/// Client choisi     Focus directement dans Produit
/// Entrée sur produit  Dialogue Qté (pré-rempli à 1, déjà sélectionné), Entrée valide
/// Après ajout       Ligne dans le tableau, focus revient sur Produit → boucle
/// Espace sur Produit  Focus sur Montant versé (ou directement sur le bouton
///                     principal si `includePayment` est false)
/// Entrée sur Montant  Focus sur le bouton principal (bordure verte + halo)
/// Entrée sur le bouton  Exécute `onFinalize`
class QuickBillingView extends StatefulWidget {
  final String title;
  final Color accentColor;
  /// true pour une vente normale (montant/paiement inline) ; false pour une
  /// simple saisie de commande/proforma (pas de paiement, juste enregistrer).
  final bool includePayment;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onSwitchToClassic;

  /// Appelé quand l'utilisateur valide le bouton principal. Reçoit le
  /// montant versé saisi (0 si `includePayment` est false). Doit renvoyer
  /// true en cas de succès (la vue réinitialise alors le formulaire pour la
  /// facture suivante) — l'appelant gère createSale/createPendingOrder et
  /// l'impression.
  final Future<bool> Function(double montantVerse) onFinalize;

  const QuickBillingView({
    super.key,
    required this.title,
    required this.accentColor,
    required this.includePayment,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onSwitchToClassic,
    required this.onFinalize,
  });

  @override
  State<QuickBillingView> createState() => _QuickBillingViewState();
}

class _QuickBillingViewState extends State<QuickBillingView> {
  late final SalesController _salesController = Get.find<SalesController>();
  late final CustomerController _customersController = Get.find<CustomerController>();
  late final ProductController _productController = Get.find<ProductController>();

  // Le FocusNode réel de chaque champ Autocomplete est créé et possédé par
  // RawAutocomplete lui-même (fourni via fieldViewBuilder) — on se contente
  // de le capturer ici pour pouvoir lui donner le focus depuis l'extérieur
  // (après sélection du client, après ajout au panier, etc.) et lire son
  // état. Ne pas le créer ni le disposer nous-mêmes : ce n'est pas le nôtre.
  FocusNode? _clientFocusNode;
  FocusNode? _productFocusNode;
  final FocusNode _montantFocusNode = FocusNode();
  final FocusNode _primaryFocusNode = FocusNode();

  TextEditingController? _clientController;
  TextEditingController? _productTextController;
  final TextEditingController _montantController = TextEditingController(text: '0');

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
    // Le fil d'ariane doit se mettre à jour dès qu'un des 4 champs change de
    // focus. Pour Client/Produit, l'écoute est branchée dans fieldViewBuilder
    // (leur FocusNode n'existe qu'après le premier build).
    _montantFocusNode.addListener(_onFocusChanged);
    _primaryFocusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _clientFocusNode?.requestFocus());
    _montantController.addListener(() => setState(() {}));
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Attache le FocusNode réel d'un champ Autocomplete (fourni par
  /// fieldViewBuilder) une seule fois — RawAutocomplete conserve le même
  /// FocusNode tant que le widget garde sa clé, donc pas besoin de
  /// réattacher à chaque build.
  void _captureFocusNode(FocusNode node, void Function(FocusNode) assign, FocusNode? current) {
    if (!identical(current, node)) {
      assign(node);
      node.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _clientFocusNode?.removeListener(_onFocusChanged);
    _productFocusNode?.removeListener(_onFocusChanged);
    _montantFocusNode.dispose();
    _primaryFocusNode.dispose();
    _montantController.dispose();
    super.dispose();
  }

  /// Espace sur le champ Produit : passe au montant versé (ou directement au
  /// bouton principal si cette vue n'inclut pas de paiement). Échap : retour
  /// à la vue classique, depuis n'importe quel champ de cette vue.
  bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onSwitchToClassic();
      return true;
    }

    if (event.logicalKey != LogicalKeyboardKey.space) return false;
    if (_productFocusNode?.hasFocus != true) return false;

    if (widget.includePayment) {
      _montantFocusNode.requestFocus();
    } else {
      _primaryFocusNode.requestFocus();
    }
    return true;
  }

  double get _montantVerse => double.tryParse(_montantController.text.replaceAll(',', '.')) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSelectedCustomerBanner(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildCartTable()),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'quick_billing_hint'.tr,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ),
                        Obx(() {
                          if (_salesController.cartItems.isEmpty) return const SizedBox.shrink();
                          return TextButton.icon(
                            onPressed: () => _confirmClearCart(context),
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: Text('sales_cart_clear'.tr, style: const TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 28),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFooter(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildShortcutBar(),
          ],
        ),
      ),
    );
  }

  // ── En-tête : Client + Produit + fil d'ariane ──────────────────────────

  Widget _buildHeader() {
    // Pas besoin d'AnimatedBuilder ici : chaque FocusNode (Client, Produit,
    // Montant, bouton principal) déclenche déjà setState via _onFocusChanged
    // quand son focus change, donc ce widget se reconstruit tout seul avec
    // des valeurs .hasFocus à jour.
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: widget.accentColor),
            tooltip: 'back'.tr,
            onPressed: () => Get.back(),
          ),
          Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.accentColor)),
          const SizedBox(width: 24),
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('quick_billing_client'.tr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 2),
                _buildClientField(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('quick_billing_product'.tr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 2),
                _buildProductField(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildBreadcrumb(),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: widget.onSwitchToClassic,
            icon: const Icon(Icons.view_agenda_outlined, size: 18),
            label: Text('quick_billing_classic_view'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final steps = [
      ('quick_billing_step_client'.tr, _clientFocusNode?.hasFocus ?? false),
      ('quick_billing_step_product'.tr, _productFocusNode?.hasFocus ?? false),
      if (widget.includePayment) ('quick_billing_step_amount'.tr, _montantFocusNode.hasFocus),
      ('quick_billing_step_pay'.tr, _primaryFocusNode.hasFocus),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0) Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: steps[i].$2 ? widget.accentColor.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              steps[i].$1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: steps[i].$2 ? FontWeight.bold : FontWeight.normal,
                color: steps[i].$2 ? widget.accentColor : Colors.grey[500],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Champ Client ────────────────────────────────────────────────────────

  Widget _buildClientField() {
    final createSentinel = Customer(id: -1, nom: '__CREATE__', dateCreation: DateTime(0), dateModification: DateTime(0));
    return Autocomplete<Customer>(
      displayStringForOption: (c) => c.id == -1 ? '' : c.nom,
      optionsBuilder: (TextEditingValue tv) {
        if (tv.text.isEmpty) return const Iterable<Customer>.empty();
        final query = tv.text.toLowerCase().trim();
        final matches = _customersController.customers.where((c) => c.nom.toLowerCase().contains(query)).toList();
        final hasExact = matches.any((c) => c.nom.toLowerCase() == query);
        if (!hasExact) matches.add(createSentinel);
        return matches;
      },
      onSelected: (c) {
        if (c.id == -1) {
          final query = _clientController?.text ?? '';
          if (query.isNotEmpty) _createAndSelectCustomer(query);
        } else {
          _salesController.setSelectedCustomer(c);
          _productFocusNode?.requestFocus();
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        _clientController = controller;
        _captureFocusNode(focusNode, (n) => _clientFocusNode = n, _clientFocusNode);
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _fieldDecoration(hint: 'sales_search_customer'.tr, color: widget.accentColor),
          onSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final realOptions = options.where((c) => c.id != -1).toList();
        final showCreate = options.any((c) => c.id == -1);
        final query = _clientController?.text ?? '';
        return _buildOptionsOverlay(
          itemCount: realOptions.length,
          showCreate: showCreate,
          createLabel: 'Créer "$query"',
          onCreateTap: () => _createAndSelectCustomer(query),
          itemBuilder: (context, i) {
            final c = realOptions[i];
            final isHighlighted = AutocompleteHighlightedOption.of(context) == i;
            return _optionTile(
              isHighlighted: isHighlighted,
              leading: c.nom.isNotEmpty ? c.nom[0].toUpperCase() : '?',
              title: c.nom,
              subtitle: c.telephone,
              onTap: () => onSelected(c),
            );
          },
          createHighlighted: (context) => AutocompleteHighlightedOption.of(context) == realOptions.length,
        );
      },
    );
  }

  Future<void> _createAndSelectCustomer(String nom) async {
    try {
      final newCustomer = await _customersController.createCustomer(CustomerForm(nom: nom.trim()));
      if (newCustomer != null) {
        _salesController.setSelectedCustomer(newCustomer);
        _clientController?.text = newCustomer.nom;
        setState(() {});
        _productFocusNode?.requestFocus();
      }
    } catch (e) {
      SnackbarHelper.error('Erreur lors de la création du client: $e');
    }
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('sales_cart_clear_confirm'.tr),
        content: Text('sales_cart_clear_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _salesController.clearCart();
            },
            child: Text('sales_cart_clear_button'.tr),
          ),
        ],
      ),
    );
  }

  // ── Champ Produit ───────────────────────────────────────────────────────

  Widget _buildProductField() {
    return Autocomplete<Product>(
      displayStringForOption: (p) => '',
      optionsBuilder: (TextEditingValue tv) {
        if (tv.text.isEmpty) return const Iterable<Product>.empty();
        final query = tv.text.toLowerCase().trim();
        return _productController.products.where((p) {
          return p.nom.toLowerCase().contains(query) || p.reference.toLowerCase().contains(query) || (p.codeBarre?.toLowerCase().contains(query) ?? false);
        }).take(30);
      },
      onSelected: (product) => _onProductChosen(product),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        _productTextController = controller;
        _captureFocusNode(focusNode, (n) => _productFocusNode = n, _productFocusNode);
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _fieldDecoration(hint: 'sales_search_product_hint'.tr, color: widget.accentColor),
          onSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final list = options.toList();
        return _buildOptionsOverlay(
          itemCount: list.length,
          showCreate: false,
          itemBuilder: (context, i) {
            final p = list[i];
            final isHighlighted = AutocompleteHighlightedOption.of(context) == i;
            final available = _salesController.getAvailableQuantity(p.id);
            final subtitle = '${p.reference} · ${p.prixUnitaire.toStringAsFixed(0)} FCFA'
                '${p.estService ? '' : ' · Stock: ${_salesController.getRawStockQuantity(p.id)}'}';
            return _optionTile(
              isHighlighted: isHighlighted,
              leading: null,
              title: p.nom,
              subtitle: subtitle,
              disabled: !p.estActif || (!p.estService && available <= 0),
              onTap: () => onSelected(p),
            );
          },
        );
      },
    );
  }

  void _onProductChosen(Product product) {
    final canAdd = product.estActif && (product.estService || _salesController.getAvailableQuantity(product.id) > 0);
    if (!canAdd) {
      SnackbarHelper.warning('Stock épuisé pour ${product.nom}', duration: const Duration(seconds: 2));
      return;
    }

    showAddToCartQuantityDialog(context, product, (p, qty) async {
      await _salesController.addToCart(p, quantity: qty);
      _productTextController?.clear();
      setState(() {});
      // Boucle : le focus revient sur Produit pour l'article suivant.
      WidgetsBinding.instance.addPostFrameCallback((_) => _productFocusNode?.requestFocus());
    });
  }

  // ── Aides communes pour les deux champs Autocomplete ──────────────────

  InputDecoration _fieldDecoration({required String hint, required Color color}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: color, width: 2)),
    );
  }

  Widget _buildOptionsOverlay({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    bool showCreate = false,
    String createLabel = '',
    VoidCallback? onCreateTap,
    bool Function(BuildContext)? createHighlighted,
  }) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 340,
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (itemCount > 0)
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: itemBuilder,
                  ),
                ),
              if (showCreate) ...[
                if (itemCount > 0) Divider(height: 1, color: Colors.grey[200]),
                Builder(builder: (context) {
                  final isHighlighted = createHighlighted?.call(context) ?? false;
                  return Container(
                    color: isHighlighted ? widget.accentColor.withOpacity(0.08) : null,
                    child: InkWell(
                      onTap: onCreateTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.person_add, size: 18, color: widget.accentColor),
                            const SizedBox(width: 10),
                            Expanded(child: Text(createLabel, style: TextStyle(fontSize: 14, color: widget.accentColor, fontWeight: FontWeight.w500))),
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
  }

  Widget _optionTile({
    required bool isHighlighted,
    String? leading,
    required String title,
    String? subtitle,
    bool disabled = false,
    required VoidCallback onTap,
  }) {
    return Container(
      color: isHighlighted ? widget.accentColor.withOpacity(0.08) : null,
      child: ListTile(
        dense: true,
        enabled: !disabled,
        leading: leading != null
            ? CircleAvatar(
                radius: 14,
                backgroundColor: widget.accentColor.withOpacity(0.15),
                child: Text(leading, style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w600, fontSize: 11)),
              )
            : null,
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 11, color: disabled ? Colors.red[400] : Colors.grey[600])) : null,
        onTap: disabled ? null : onTap,
      ),
    );
  }

  // ── Bannière client sélectionné ─────────────────────────────────────────

  Widget _buildSelectedCustomerBanner() {
    return Obx(() {
      final customer = _salesController.selectedCustomer;
      if (customer == null) return const SizedBox.shrink();
      final solde = customer.solde;
      final aDette = solde < 0;
      final montantAffiche = solde.abs();
      final labelSolde = aDette ? 'sales_customer_debt'.tr : 'sales_customer_credit'.tr;
      final couleurSolde = aDette ? Colors.red : Colors.green;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.accentColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.accentColor.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Text('${'quick_billing_client'.tr} : ', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(customer.nom),
            if (customer.telephone != null) ...[
              const SizedBox(width: 12),
              Text(customer.telephone!, style: TextStyle(color: Colors.grey[600])),
            ],
            if (solde != 0) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: couleurSolde.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: couleurSolde.withOpacity(0.4)),
                ),
                child: Text(
                  '$labelSolde : ${montantAffiche.toStringAsFixed(0)} FCFA',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: couleurSolde),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── Tableau du panier ───────────────────────────────────────────────────

  Widget _buildCartTable() {
    return Obx(() {
      final items = _salesController.cartItems;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: widget.accentColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text('quick_billing_col_designation'.tr, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('quick_billing_col_pu'.tr, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('quick_billing_col_qty'.tr, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('quick_billing_col_total'.tr, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text('quick_billing_empty_cart'.tr, style: TextStyle(color: Colors.grey[500])),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return _EditableCartRow(
                          key: ValueKey(item.productId),
                          item: item,
                          onQuantityChanged: (qty) => _salesController.updateCartItemQuantity(item.productId, qty),
                          onPriceChanged: (price) => _salesController.updateCartItemPrice(item.productId, price),
                          onRemove: () => _salesController.removeFromCart(item.productId),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text('total'.tr, style: const TextStyle(fontWeight: FontWeight.bold))),
                  const Expanded(flex: 2, child: SizedBox.shrink()),
                  Expanded(flex: 1, child: Text('${items.fold<int>(0, (s, i) => s + i.quantity)}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text(_salesController.cartTotal.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Bas de page : totaux + montant/payer ────────────────────────────────

  Widget _buildFooter() {
    return Obx(() {
      final total = _salesController.cartTotal;
      final discount = _salesController.discount;
      final netAPayer = total;
      final monnaie = widget.includePayment ? (_montantVerse - netAPayer) : null;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _totalRow('quick_billing_total_due'.tr, '${total.toStringAsFixed(0)} FCFA'),
                _totalRow('quick_billing_discount'.tr, '${discount.toStringAsFixed(0)} FCFA'),
                const SizedBox(height: 4),
                _totalRow('quick_billing_net_due'.tr, '${netAPayer.toStringAsFixed(0)} FCFA', bold: true, big: true),
              ],
            ),
          ),
          if (widget.includePayment) ...[
            const SizedBox(width: 24),
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('quick_billing_amount_paid'.tr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _montantController,
                    focusNode: _montantFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: _fieldDecoration(hint: '0', color: widget.accentColor),
                    onSubmitted: (_) => _primaryFocusNode.requestFocus(),
                    onTap: () => _montantController.selection = TextSelection(baseOffset: 0, extentOffset: _montantController.text.length),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monnaie != null && monnaie >= 0 ? '${'quick_billing_change'.tr}: ${monnaie.toStringAsFixed(0)} FCFA' : '${'quick_billing_remaining'.tr}: ${(-(monnaie ?? 0)).toStringAsFixed(0)} FCFA',
                    style: TextStyle(fontSize: 12, color: (monnaie ?? 0) >= 0 ? Colors.grey[600] : Colors.orange[700], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 24),
          SizedBox(
            width: 200,
            height: 64,
            child: AnimatedBuilder(
              animation: _primaryFocusNode,
              builder: (context, _) {
                final armed = _primaryFocusNode.hasFocus;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: armed ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)] : null,
                  ),
                  child: ElevatedButton.icon(
                    focusNode: _primaryFocusNode,
                    onPressed: _salesController.cartItems.isEmpty || _isSubmitting || _salesController.hasCartValidationError ? null : _handlePrimaryAction,
                    icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(widget.primaryIcon),
                    label: Text(widget.primaryLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: armed ? Colors.green[800] : widget.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: armed ? const BorderSide(color: Color(0xFF1B5E20), width: 2) : BorderSide.none,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _totalRow(String label, String value, {bool bold = false, bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: big ? 14 : 12, color: Colors.grey[700], fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
          Text(value, style: TextStyle(fontSize: big ? 20 : 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: big ? widget.accentColor : Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (_salesController.cartItems.isEmpty) return;
    // Filet de sécurité : si un prix a été laissé en dessous du minimum
    // autorisé dans le tableau (voir _EditableCartRow), on le corrige avant
    // d'enregistrer — même garde-fou que la vue classique.
    _salesController.clampCartPricesToMinimum();
    setState(() => _isSubmitting = true);
    try {
      final success = await widget.onFinalize(_montantVerse);
      if (success) {
        _resetForNextSale();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForNextSale() {
    _clientController?.clear();
    _productTextController?.clear();
    _montantController.text = '0';
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _clientFocusNode?.requestFocus());
  }

  // ── Barre de raccourcis ──────────────────────────────────────────────────

  Widget _buildShortcutBar() {
    final shortcuts = <(String, String)>[
      ('↑ ↓', 'quick_billing_shortcut_navigate'.tr),
      ('Entrée', 'quick_billing_shortcut_validate'.tr),
      ('Espace', widget.includePayment ? 'quick_billing_shortcut_space_amount'.tr : 'quick_billing_shortcut_space_pay'.tr),
      ('Échap', 'quick_billing_shortcut_back'.tr),
    ];
    return Container(
      width: double.infinity,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 20,
        runSpacing: 4,
        children: [
          for (final s in shortcuts)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                  child: Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Text(s.$2, style: TextStyle(color: Colors.grey[300], fontSize: 11)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Ligne de tableau éditable (quantité et prix unitaire). Contrôleurs de
/// texte locaux, resynchronisés depuis le modèle uniquement quand
/// l'utilisateur n'est pas en train de taper — même principe que
/// `_CartItem` dans cart_widget.dart, pour éviter que le focus/curseur
/// ne saute à chaque frappe pendant qu'`Obx` reconstruit la liste.
class _EditableCartRow extends StatefulWidget {
  final CartItem item;
  final void Function(int quantity) onQuantityChanged;
  final void Function(double price) onPriceChanged;
  final VoidCallback onRemove;

  const _EditableCartRow({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  State<_EditableCartRow> createState() => _EditableCartRowState();
}

class _EditableCartRowState extends State<_EditableCartRow> {
  late final SalesController _salesController = Get.find<SalesController>();
  late final TextEditingController _qtyController = TextEditingController(text: widget.item.quantity.toString());
  late final TextEditingController _priceController = TextEditingController(text: widget.item.unitPrice.toStringAsFixed(0));
  bool _isTypingQty = false;
  bool _isTypingPrice = false;
  String? _priceError;
  String? _qtyError;

  double get _minPrice => widget.item.originalPrice - widget.item.maxDiscountAllowed;

  /// Quantité maximale pour CET article : le stock disponible ne tient déjà
  /// plus compte de ce qui est dans le panier, donc on rajoute sa propre
  /// quantité actuelle pour connaître la vraie marge de manœuvre.
  int get _maxQuantity => _salesController.getAvailableQuantity(widget.item.productId) + widget.item.quantity;

  /// Fait remonter au contrôleur si cette ligne a une erreur (prix ou
  /// quantité) — utilisé pour désactiver le bouton principal tant qu'une
  /// ligne du panier n'est pas valide.
  void _reportLineError() {
    _salesController.setCartLineError(widget.item.productId, _priceError != null || _qtyError != null);
  }

  @override
  void dispose() {
    _salesController.setCartLineError(widget.item.productId, false);
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _EditableCartRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    if (!_isTypingQty) {
      final text = widget.item.quantity.toString();
      if (_qtyController.text != text) _qtyController.text = text;
    }
    if (!_isTypingPrice) {
      final text = widget.item.unitPrice.toStringAsFixed(0);
      if (_priceController.text != text) _priceController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncControllers();
    final item = widget.item;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(item.productName, overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _priceController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: _cellDecoration(errorText: _priceError, helperText: widget.item.maxDiscountAllowed > 0 ? 'quick_billing_min_price'.trParams({'min': _minPrice.toStringAsFixed(0)}) : null),
              onTap: () => _isTypingPrice = true,
              onChanged: (value) {
                _isTypingPrice = true;
                final price = double.tryParse(value.replaceAll(',', '.'));
                setState(() {
                  _priceError = (price != null && price < _minPrice) ? 'sales_cart_price_below_min'.trParams({'min': _minPrice.toStringAsFixed(0)}) : null;
                });
                _reportLineError();
                // Pris en compte tel quel, comme la vue classique : l'erreur
                // ci-dessus prévient l'utilisateur, et clampCartPricesToMinimum
                // corrige silencieusement si jamais il valide sans corriger.
                if (price != null && price >= 0) widget.onPriceChanged(price);
              },
              onSubmitted: (_) => setState(() => _isTypingPrice = false),
              onEditingComplete: () => _isTypingPrice = false,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _qtyController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: _cellDecoration(errorText: _qtyError),
              onTap: () => _isTypingQty = true,
              onChanged: (value) {
                _isTypingQty = true;
                final qty = int.tryParse(value);
                setState(() {
                  if (qty == null || qty <= 0) {
                    _qtyError = 'sales_invalid_quantity'.tr;
                  } else if (qty > _maxQuantity) {
                    _qtyError = 'sales_stock_insufficient_detail'.trParams({'requested': qty.toString(), 'available': _maxQuantity.toString()});
                  } else {
                    _qtyError = null;
                  }
                });
                _reportLineError();
                // Le contrôleur refuse lui-même toute quantité dépassant le
                // stock disponible (voir SalesController.updateCartItemQuantity) :
                // l'erreur ci-dessus se contente de l'expliquer sans attendre
                // le message ponctuel qu'il affiche.
                if (qty != null && qty > 0) widget.onQuantityChanged(qty);
              },
              onSubmitted: (_) {
                setState(() {
                  _isTypingQty = false;
                  _qtyError = null;
                });
                _reportLineError();
              },
              onEditingComplete: () => _isTypingQty = false,
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(item.totalPrice.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(
            width: 36,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: Colors.red[300],
              onPressed: widget.onRemove,
              tooltip: 'sales_cart_remove'.tr,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _cellDecoration({String? errorText, String? helperText}) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: const OutlineInputBorder(),
      errorText: errorText,
      errorStyle: const TextStyle(fontSize: 10),
      helperText: errorText == null ? helperText : null,
      helperStyle: const TextStyle(fontSize: 10),
      helperMaxLines: 2,
      errorMaxLines: 2,
    );
  }
}
