import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/account_controller.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../services/account_api_service.dart';
import '../../../shared/constants/constants.dart';
import 'unpaid_sales_selector_dialog.dart';

/// Dialogue pour créer une nouvelle transaction
class TransactionFormDialog extends StatefulWidget {
  final bool isClient;
  final int accountId;
  final String? initialType;
  final VoidCallback? onTransactionCreated;

  const TransactionFormDialog({
    super.key,
    required this.isClient,
    required this.accountId,
    this.initialType,
    this.onTransactionCreated,
  });

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _typeTransaction = 'paiement';
  bool _isLoading = false;

  // Pour le paiement de vente spécifique
  UnpaidSale? _selectedSale;
  bool _isPayingSpecificSale = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _typeTransaction = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isClient ? 'accounts_new_client_transaction_title'.tr : 'accounts_new_supplier_transaction_title'.tr),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type de transaction
              Text(
                'accounts_transaction_type'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _typeTransaction,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _getTransactionTypes(),
                onChanged: (value) {
                  setState(() {
                    _typeTransaction = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'accounts_transaction_type_required'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Bouton pour payer une vente spécifique (uniquement pour les clients et type paiement)
              if (widget.isClient && _typeTransaction == 'paiement')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: _isPayingSpecificSale,
                      onChanged: (value) {
                        setState(() {
                          _isPayingSpecificSale = value ?? false;
                          if (!_isPayingSpecificSale) {
                            _selectedSale = null;
                            _montantController.clear();
                            _descriptionController.clear();
                          }
                        });
                      },
                      title: Text('accounts_pay_specific_sale'.tr),
                      subtitle: Text('accounts_select_unpaid_sale'.tr),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_isPayingSpecificSale) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showUnpaidSalesSelector,
                        icon: const Icon(Icons.receipt_long),
                        label: Text(_selectedSale == null ? 'customers_select_sale_button'.tr : 'accounts_sale_reference'.trParams({'reference': _selectedSale!.reference})),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      if (_selectedSale != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'accounts_sale_reference'.trParams({'reference': _selectedSale!.reference}),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('customers_sale_date'.trParams({'date': _selectedSale!.dateVenteFormatted})),
                              Text('customers_sale_total'.trParams({'amount': _selectedSale!.montantTotalFormatted})),
                              Text('customers_sale_paid'.trParams({'amount': _selectedSale!.montantPayeFormatted})),
                              Text(
                                'customers_sale_remaining'.trParams({'amount': _selectedSale!.montantRestantFormatted}),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                  ],
                ),

              // Montant
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'accounts_amount_label'.trParams({'currency': CurrencyConstants.defaultCurrency}),
                  hintText: 'accounts_amount_hint'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'accounts_amount_required'.tr;
                  }
                  final montant = double.tryParse(value);
                  if (montant == null || montant <= 0) {
                    return 'accounts_amount_invalid'.tr;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'customers_description_optional'.tr,
                  hintText: 'accounts_transaction_details_hint'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),

              const SizedBox(height: 16),

              // Explication de l'impact
              _buildTransactionImpactExplanation(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('common_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTransaction,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('suppliers_form_create'.tr),
        ),
      ],
    );
  }

  /// Retourne les types de transaction disponibles
  List<DropdownMenuItem<String>> _getTransactionTypes() {
    if (widget.isClient) {
      return [
        DropdownMenuItem(
          value: 'paiement',
          child: Text('accounts_type_payment'.tr),
        ),
        DropdownMenuItem(
          value: 'credit',
          child: Text('accounts_type_credit'.tr),
        ),
        DropdownMenuItem(
          value: 'debit',
          child: Text('accounts_type_debit'.tr),
        ),
      ];
    } else {
      return [
        DropdownMenuItem(
          value: 'paiement',
          child: Text('accounts_type_payment'.tr),
        ),
        DropdownMenuItem(
          value: 'credit',
          child: Text('accounts_type_credit'.tr),
        ),
        DropdownMenuItem(
          value: 'achat',
          child: Text('accounts_type_purchase'.tr),
        ),
        DropdownMenuItem(
          value: 'debit',
          child: Text('accounts_type_debit'.tr),
        ),
      ];
    }
  }

  /// Construit l'explication de l'impact de la transaction
  Widget _buildTransactionImpactExplanation() {
    String explanation;
    Color color;
    IconData icon;

    switch (_typeTransaction) {
      case 'paiement':
      case 'credit':
        explanation = widget.isClient ? 'accounts_impact_decrease_client'.tr : 'accounts_impact_decrease_supplier'.tr;
        color = Colors.green;
        icon = Icons.trending_down;
        break;
      case 'debit':
        explanation = widget.isClient ? 'accounts_impact_increase_client'.tr : 'accounts_impact_increase_supplier'.tr;
        color = Colors.orange;
        icon = Icons.trending_up;
        break;
      case 'achat':
        explanation = 'accounts_impact_increase_supplier'.tr;
        color = Colors.orange;
        icon = Icons.trending_up;
        break;
      default:
        explanation = '';
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              explanation,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Crée la transaction
  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation supplémentaire pour les ventes spécifiques
    if (_isPayingSpecificSale && _selectedSale == null) {
      Get.snackbar(
        'error'.tr,
        'accounts_select_sale_to_pay'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final montant = double.parse(_montantController.text);
      final description = _descriptionController.text.trim();

      // Si on paie une vente spécifique, utiliser la nouvelle méthode
      if (_isPayingSpecificSale && _selectedSale != null) {
        final service = Get.find<AccountService>();
        if (service is! AccountApiService) {
          throw Exception('Le service de comptes ne supporte pas cette fonctionnalité');
        }
        final apiService = service as AccountApiService;
        await apiService.createTransactionWithSale(
          clientId: widget.accountId,
          montant: montant,
          typeTransaction: 'paiement',
          typeTransactionDetail: 'paiement_dette',
          venteId: _selectedSale!.id,
          description: description.isEmpty ? 'accounts_debt_payment_description'.trParams({'reference': _selectedSale!.reference}) : description,
        );
      } else {
        // Transaction normale
        final transactionForm = TransactionForm(
          montant: montant,
          typeTransaction: _typeTransaction,
          description: description.isEmpty ? null : description,
        );

        final controller = Get.find<AccountController>();

        if (widget.isClient) {
          await controller.createTransactionClient(widget.accountId, transactionForm);
        } else {
          await controller.createTransactionFournisseur(widget.accountId, transactionForm);
        }
      }

      // Fermer le dialogue
      Navigator.of(context).pop();

      // Callback pour actualiser la vue
      widget.onTransactionCreated?.call();

      Get.snackbar(
        'success'.tr,
        'accounts_transaction_created'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'accounts_transaction_create_error'.trParams({'error': '$e'}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Affiche le sélecteur de ventes impayées
  Future<void> _showUnpaidSalesSelector() async {
    await showDialog(
      context: context,
      builder: (context) => UnpaidSalesSelectorDialog(
        clientId: widget.accountId,
        onSaleSelected: (sale, montant) {
          setState(() {
            _selectedSale = sale;
            _montantController.text = montant.toStringAsFixed(0);
            _descriptionController.text = 'accounts_debt_payment_description'.trParams({'reference': sale.reference});
          });
        },
      ),
    );
  }
}
