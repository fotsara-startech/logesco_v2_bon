import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/sales_controller.dart';
import '../../customers/controllers/customer_controller.dart';
import '../widgets/product_selector.dart';
import '../widgets/cart_widget.dart';
import '../widgets/finalize_sale_dialog.dart';
import '../../customers/models/customer.dart';

class CreateSalePage extends StatefulWidget {
  const CreateSalePage({super.key});

  @override
  State<CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends State<CreateSalePage> {
  late SalesController _salesController;
  late CustomerController _customersController;
  TextEditingController? _autocompleteController;

  @override
  void initState() {
    super.initState();
    _salesController = Get.put(SalesController());
    _customersController = Get.find<CustomerController>();
  }

  @override
  void dispose() {
    super.dispose();
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
      body: Row(
        children: [
          // SECTION GAUCHE - Sélection produits (50%)
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Barre de recherche client - toujours visible en haut
                  _buildQuickCustomerSearch(),

                  const Divider(height: 1),

                  // Sélecteur de produits
                  Expanded(
                    child: ProductSelector(
                      onProductSelected: (product, quantity) async {
                        await _salesController.addToCart(product, quantity: quantity);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SECTION DROITE - Panier & Paiement (50%) - Entièrement scrollable
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  left: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Client sélectionné - Compact
                    _buildSelectedCustomerBanner(),

                    // Section antidatage (si autorisé)
                    _buildBackdateSection(),

                    // Panier
                    Container(
                      color: Colors.white,
                      margin: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header panier
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_cart_outlined, color: Colors.grey[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'sales_cart'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Obx(() => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_salesController.cartItems.length}',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),

                          // Liste panier - Hauteur dynamique
                          Obx(() {
                            final itemCount = _salesController.cartItems.length;
                            // Calculer la hauteur nécessaire pour afficher tous les items
                            // Chaque item fait environ 120px de hauteur
                            final estimatedHeight = itemCount * 250.0;
                            final mediaquery = MediaQuery.of(context).size.height * 0.5;

                            return SizedBox(
                              height: itemCount == 0 ? mediaquery : estimatedHeight,
                              child: CartWidget(
                                onQuantityChanged: (productId, quantity) {
                                  _salesController.updateCartItemQuantity(productId, quantity);
                                },
                                onPriceChanged: (productId, price) {
                                  _salesController.updateCartItemPrice(productId, price);
                                },
                                onRemoveItem: (productId) {
                                  _salesController.removeFromCart(productId);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Section paiement - Plus fixe, fait partie du scroll
                    _buildPaymentSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Recherche client rapide et compacte
  Widget _buildQuickCustomerSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Autocomplete<Customer>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Customer>.empty();
                }
                return _customersController.customers.where((Customer option) {
                  return (option.nom?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false);
                });
              },
              onSelected: (Customer selection) {
                _salesController.setSelectedCustomer(selection);
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                // Sauvegarder la référence au contrôleur pour pouvoir le nettoyer
                _autocompleteController = controller;

                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'sales_search_customer'.tr,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                            onPressed: _clearCustomerSearch,
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    setState(() {}); // Pour mettre à jour le suffixIcon
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 320,
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          // Calculer le solde (négatif = dette)
                          final solde = option.solde ?? 0.0;
                          final aDette = solde < 0;
                          final montantAffiche = aDette ? -solde : solde;

                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                (option.nom ?? 'C')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              option.nom,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: option.telephone != null
                                ? Text(
                                    option.telephone!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                            trailing: (solde != 0)
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: aDette ? Colors.red[50] : Colors.green[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${aDette ? "sales_customer_debt".tr : "sales_customer_credit".tr}: ${'sales_customer_balance'.trParams({'amount': montantAffiche.toStringAsFixed(0)})}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: aDette ? Colors.red[700] : Colors.green[700],
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () => onSelected(option),
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

  // Bannière client sélectionné - Ultra compact
  Widget _buildSelectedCustomerBanner() {
    return Obx(() {
      final customer = _salesController.selectedCustomer;
      if (customer == null) return const SizedBox.shrink();

      // Calculer le solde (négatif = dette, positif = crédit)
      final solde = customer.solde ?? 0.0;
      final aDette = solde < 0;
      final montantAffiche = aDette ? -solde : solde;
      final labelSolde = aDette ? 'Dette' : 'Crédit';
      final couleurSolde = aDette ? Colors.red : Colors.green;

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[700]!],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
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
            child: Obx(() => SizedBox(
                  width: double.infinity,
                  height: 56,
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
        Get.snackbar(
          'sales_cart_empty_action'.tr,
          'sales_add_products_to_continue'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      // Ouvrir le dialog de paiement simplifié
      await Get.dialog(
        const FinalizeSaleDialog(),
        barrierDismissible: false,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
