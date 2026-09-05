import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';

import '../controllers/sales_controller.dart';
import '../../customers/controllers/customer_controller.dart';
import '../widgets/product_selector.dart';
import '../widgets/cart_widget.dart';
import '../widgets/finalize_sale_dialog.dart';
import '../../customers/models/customer.dart';
import '../../commercials/models/commercial.dart';

class CreateSalePage extends StatefulWidget {
  const CreateSalePage({super.key});

  @override
  State<CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends State<CreateSalePage> {
  late SalesController _salesController;
  late CustomerController _customersController;
  TextEditingController? _autocompleteController;
  int _autocompleteKey = 0; // Clé pour forcer la reconstruction de l'Autocomplete
  final Map<int, String?> _priceErrors = {}; // Erreur de prix par productId (panier inline)

  @override
  void initState() {
    super.initState();
    // Utiliser l'instance existante, ne pas en créer une nouvelle
    _salesController = Get.isRegistered<SalesController>() ? Get.find<SalesController>() : Get.put(SalesController());
    _customersController = Get.isRegistered<CustomerController>() ? Get.find<CustomerController>() : Get.put(CustomerController());
  }

  // Méthode pour nettoyer la recherche client
  void _clearCustomerSearch() {
    if (_autocompleteController != null) {
      _autocompleteController!.clear();
    }
    _salesController.setSelectedCustomer(null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: Text(
          'sales_billing'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          // Affichage date/heure compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'sales_settings'.tr,
            onPressed: () => Get.toNamed('/sales/preferences'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          if (isMobile) return _buildMobileLayout();
          return _buildDesktopLayout();
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildQuickCustomerSearch(),
          _buildCommercialSelector(),
          const Divider(height: 1),
          Obx(() {
            final itemCount = _salesController.cartItems.length;
            return TabBar(
              tabs: [
                const Tab(icon: Icon(Icons.inventory_2), text: 'Produits'),
                Tab(
                  icon: Badge(isLabelVisible: itemCount > 0, label: Text('$itemCount'), child: const Icon(Icons.shopping_cart)),
                  text: 'Panier',
                ),
              ],
            );
          }),
          Expanded(
            child: TabBarView(
              children: [
                ProductSelector(onProductSelected: (product, quantity) async => await _salesController.addToCart(product, quantity: quantity)),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSelectedCustomerBanner(),
                      _buildBackdateSection(),
                      _buildInlineCart(),
                      _buildPaymentSection(),
                      const SizedBox(height: 24),
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

  Widget _buildInlineCart() {
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
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                      child: Text('${_salesController.cartItems.length}', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 12)),
                    )),
              ],
            ),
          ),
          Obx(() {
            final controller = _salesController;
            if (controller.cartItems.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                    child: Column(children: [
                  Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('sales_cart_empty'.tr, style: TextStyle(fontSize: 16, color: Colors.grey[600]))
                ])),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...controller.cartItems.map((item) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              IconButton(
                                  onPressed: () => controller.removeFromCart(item.productId),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints())
                            ]),
                            Text('Réf: ${item.productReference}', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 8),
                            Row(children: [
                              IconButton(
                                  onPressed: item.quantity > 1 ? () => controller.updateCartItemQuantity(item.productId, item.quantity - 1) : null, icon: const Icon(Icons.remove), iconSize: 20),
                              SizedBox(width: 50, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                              IconButton(onPressed: () => controller.updateCartItemQuantity(item.productId, item.quantity + 1), icon: const Icon(Icons.add), iconSize: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: TextFormField(
                                      initialValue: item.unitPrice.toStringAsFixed(2),
                                      decoration: InputDecoration(
                                        labelText: 'sales_cart_unit_price'.tr,
                                        suffixText: 'FCFA',
                                        isDense: true,
                                        errorText: _priceErrors[item.productId],
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) {
                                        final p = double.tryParse(v);
                                        final minPrice = item.originalPrice - item.maxDiscountAllowed;
                                        setState(() {
                                          _priceErrors[item.productId] = (p != null && p < minPrice) ? 'sales_cart_price_below_min'.trParams({'min': minPrice.toStringAsFixed(0)}) : null;
                                        });
                                        // Prix pris en compte tel quel — le minimum n'est appliqué
                                        // qu'à la validation si l'utilisateur ignore l'erreur (voir
                                        // SalesController.clampCartPricesToMinimum).
                                        if (p != null && p >= 0) controller.updateCartItemPrice(item.productId, p);
                                      })),
                            ]),
                            const SizedBox(height: 4),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('sales_cart_line_total'.tr),
                              Text('${item.totalPrice.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
                            ]),
                          ],
                        ),
                      ),
                    )),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('sales_cart_subtotal'.tr), Text('${controller.cartSubtotal.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold))]),
                    if (controller.discount > 0)
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text('sales_cart_discount'.tr), Text('-${controller.discount.toStringAsFixed(0)} FCFA', style: const TextStyle(color: Colors.green))]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('sales_cart_total'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${controller.cartTotal.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue))
                    ]),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(title: Text('sales_cart_clear_confirm'.tr), content: Text('sales_cart_clear_message'.tr), actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
                                  ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        controller.clearCart();
                                      },
                                      child: Text('sales_cart_clear_button'.tr))
                                ])),
                        icon: const Icon(Icons.clear_all),
                        label: Text('sales_cart_clear'.tr),
                      )),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildQuickCustomerSearch(),
                _buildCommercialSelector(),
                const Divider(height: 1),
                Expanded(child: ProductSelector(onProductSelected: (product, quantity) async => await _salesController.addToCart(product, quantity: quantity))),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[50], border: Border(left: BorderSide(color: Colors.grey[200]!, width: 1))),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSelectedCustomerBanner(),
                  _buildBackdateSection(),
                  Container(
                    color: Colors.white,
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
                          child: Row(children: [
                            Icon(Icons.shopping_cart_outlined, color: Colors.grey[700], size: 20),
                            const SizedBox(width: 8),
                            Text('sales_cart'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Obx(() => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                                child: Text('${_salesController.cartItems.length}', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 12)))),
                          ]),
                        ),
                        // CartWidget s'ajuste à son contenu (pas de hauteur fixe/estimée
                        // à recalculer ici) — voir cart_widget.dart.
                        CartWidget(
                          onQuantityChanged: (productId, quantity) => _salesController.updateCartItemQuantity(productId, quantity),
                          onPriceChanged: (productId, price) => _salesController.updateCartItemPrice(productId, price),
                          onRemoveItem: (productId) => _salesController.removeFromCart(productId),
                        ),
                      ],
                    ),
                  ),
                  _buildPaymentSection(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Recherche client rapide et compacte
  Widget _buildQuickCustomerSearch() {
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
                final matches = _customersController.customers.where((c) => c.nom.toLowerCase().contains(query)).toList();
                // Afficher l'option de création uniquement quand AUCUN client ne correspond
                if (matches.isEmpty) matches.add(createSentinel);
                return matches;
              },
              onSelected: (Customer selection) {
                if (selection.id == -1) {
                  final query = _autocompleteController?.text ?? '';
                  if (query.isNotEmpty) _createAndSelectCustomer(query);
                } else {
                  _salesController.setSelectedCustomer(selection);
                }
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                _autocompleteController = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'sales_search_customer'.tr,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                    suffixIcon: controller.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]), onPressed: _clearCustomerSearch) : null,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => setState(() {}),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final query = _autocompleteController?.text ?? '';
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
                                itemBuilder: (_, i) {
                                  final option = realOptions[i];
                                  final solde = option.solde;
                                  final aDette = solde < 0;
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.blue[100],
                                      child: Text(option.nom[0].toUpperCase(), style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 12)),
                                    ),
                                    title: Text(option.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    subtitle: option.telephone != null ? Text(option.telephone!, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
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
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          if (showCreate) ...[
                            if (realOptions.isNotEmpty) Divider(height: 1, color: Colors.grey[200]),
                            InkWell(
                              onTap: () => _createAndSelectCustomer(query),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_add, size: 18, color: Colors.blue[700]),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text('Créer "$query"', style: TextStyle(fontSize: 14, color: Colors.blue[700], fontWeight: FontWeight.w500))),
                                  ],
                                ),
                              ),
                            ),
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

  // Sélecteur de commercial terrain — n'apparaît que si des commerciaux ont
  // été créés (fonctionnalité optionnelle, invisible chez les clients qui ne
  // l'utilisent pas). Une simple liste déroulante suffit : contrairement aux
  // clients, un commerce n'a que quelques dizaines de commerciaux au plus.
  Widget _buildCommercialSelector() {
    return Obx(() {
      final commerciaux = _salesController.commerciaux;
      if (commerciaux.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Icon(Icons.badge_outlined, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<Commercial?>(
                value: _salesController.selectedCommercial,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Commercial (optionnel)',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                items: [
                  const DropdownMenuItem<Commercial?>(value: null, child: Text('Aucun commercial')),
                  ...commerciaux.map(
                    (c) => DropdownMenuItem<Commercial?>(value: c, child: Text(c.libelleAvecZone, overflow: TextOverflow.ellipsis)),
                  ),
                ],
                onChanged: _salesController.setSelectedCommercial,
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _createAndSelectCustomer(String nom) async {
    FocusScope.of(context).unfocus();
    try {
      final newCustomer = await _customersController.createCustomer(CustomerForm(nom: nom.trim()));
      if (newCustomer != null) {
        _salesController.setSelectedCustomer(newCustomer);
        _autocompleteController?.text = newCustomer.nom;
        // Incrémenter la clé pour forcer la reconstruction de l'Autocomplete
        setState(() {
          _autocompleteKey++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du client: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Bannière client sélectionné
  Widget _buildSelectedCustomerBanner() {
    return Obx(() {
      final customer = _salesController.selectedCustomer;
      if (customer == null) return const SizedBox.shrink();

      final solde = customer.solde;
      final aDette = solde < 0;
      final montantAffiche = solde.abs();
      final labelSolde = aDette ? "sales_customer_debt".tr : "sales_customer_credit".tr;
      final couleurSolde = aDette ? Colors.red : Colors.green;

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[700]!],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text(
                (customer.nom ?? 'C')[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.nom ?? 'Client',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (customer.telephone != null)
                    Text(
                      customer.telephone!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (solde != 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      labelSolde,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${montantAffiche.toStringAsFixed(0)} F',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: couleurSolde[700],
                      ),
                    ),
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

  // Section antidatage - Compact et élégant
  Widget _buildBackdateSection() {
    return Obx(() {
      // Vérifier si l'utilisateur a le privilège d'antidater
      if (!_salesController.canBackdateSales) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'sales_sale_date'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                const Spacer(),
                if (_salesController.customSaleDate != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 16, color: Colors.orange[700]),
                    onPressed: () => _salesController.setCustomSaleDate(null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'sales_use_current_date'.tr,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: _salesController.customSaleDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  helpText: 'sales_select_sale_date'.tr,
                  cancelText: 'cancel'.tr,
                  confirmText: 'confirm'.tr,
                );

                if (selectedDate != null) {
                  _salesController.setCustomSaleDate(selectedDate);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _salesController.customSaleDate != null
                            ? '${_salesController.customSaleDate!.day.toString().padLeft(2, '0')}/${_salesController.customSaleDate!.month.toString().padLeft(2, '0')}/${_salesController.customSaleDate!.year}'
                            : 'sales_current_date'.trParams({'date': '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}'}),
                        style: TextStyle(
                          color: _salesController.customSaleDate != null ? Colors.orange[700] : Colors.grey[600],
                          fontWeight: _salesController.customSaleDate != null ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 20, color: Colors.orange[700]),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Section paiement moderne et efficace
  Widget _buildPaymentSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Résumé total
          Obx(() {
            final total = _salesController.cartTotal;
            final itemCount = _salesController.cartItems.length;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'total'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${total.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'sales_cart_items_count'.trParams({'count': itemCount.toString()}),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Bouton de confirmation
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => Column(
                  children: [
                    // Bouton principal : Procéder au paiement
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _salesController.isCreating || _salesController.cartItems.isEmpty ? null : _finalizeSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _salesController.isCreating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.payment, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    _salesController.cartItems.isEmpty ? 'sales_cart_empty_action'.tr : 'sales_proceed_payment'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                )),
          ),

          // Raccourcis clavier
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'sales_keyboard_shortcuts'.tr,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Suggestions de montants intelligentes
  List<int> _getAmountSuggestions(double total) {
    final roundedTotal = (total / 1000).ceil() * 1000;
    return [
      roundedTotal,
      if (roundedTotal + 1000 > total) roundedTotal + 1000,
      if (roundedTotal + 2000 > total) roundedTotal + 2000,
      if (roundedTotal + 5000 > total) roundedTotal + 5000,
    ];
  }

  Future<void> _finalizeSale() async {
    try {
      // Vérifier que le panier n'est pas vide
      if (_salesController.cartItems.isEmpty) {
        SnackbarHelper.warning('sales_add_products_to_continue'.tr, duration: const Duration(seconds: 2));
        return;
      }

      // Ramener tout prix sous le minimum autorisé au minimum AVANT
      // d'afficher le montant à payer — sinon le dialog de paiement (et le
      // montant encaissé) se basent sur un total calculé avec des prix
      // invalides, ce qui fausse la caisse même si createSale() corrige le
      // prix plus tard côté backend.
      _salesController.clampCartPricesToMinimum();
      setState(() => _priceErrors.clear());

      // Ouvrir le dialog de paiement simplifié
      await Get.dialog(
        const FinalizeSaleDialog(),
        barrierDismissible: false,
      );
    } catch (e) {
      SnackbarHelper.error('Erreur: $e');
    }
  }
}
