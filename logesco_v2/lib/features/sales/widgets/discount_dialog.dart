import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../shared/constants/constants.dart';
import '../models/sale.dart';
// import '../services/discount_validation_service.dart';

class DiscountDialog extends StatefulWidget {
  final CartItem cartItem;
  final Function(double discount, String? justification) onDiscountApplied;

  const DiscountDialog({
    super.key,
    required this.cartItem,
    required this.onDiscountApplied,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late final TextEditingController _discountController;
  late final TextEditingController _justificationController;

  final RxBool isValidating = false.obs;
  final RxBool isValid = true.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble currentDiscount = 0.0.obs;
  final RxDouble finalPrice = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(text: widget.cartItem.discountApplied > 0 ? widget.cartItem.discountApplied.toStringAsFixed(0) : '');
    _justificationController = TextEditingController(text: widget.cartItem.discountJustification ?? '');

    currentDiscount.value = widget.cartItem.discountApplied;
    finalPrice.value = widget.cartItem.originalPrice - widget.cartItem.discountApplied;

    _discountController.addListener(_onDiscountChanged);
  }

  @override
  void dispose() {
    _discountController.dispose();
    _justificationController.dispose();
    super.dispose();
  }

  void _onDiscountChanged() {
    final discountText = _discountController.text.trim();
    if (discountText.isEmpty) {
      currentDiscount.value = 0.0;
      finalPrice.value = widget.cartItem.originalPrice;
      isValid.value = true;
      errorMessage.value = '';
      return;
    }

    final discount = double.tryParse(discountText);
    if (discount == null) {
      isValid.value = false;
      errorMessage.value = 'Montant invalide';
      return;
    }

    if (discount < 0) {
      isValid.value = false;
      errorMessage.value = 'La remise ne peut pas être négative';
      return;
    }

    if (discount > widget.cartItem.originalPrice) {
      isValid.value = false;
      errorMessage.value = 'La remise ne peut pas dépasser le prix du produit';
      return;
    }

    if (discount > widget.cartItem.maxDiscountAllowed) {
      isValid.value = false;
      errorMessage.value = 'Remise non autorisée. Maximum: ${widget.cartItem.maxDiscountAllowed.toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}';
      return;
    }

    currentDiscount.value = discount;
    finalPrice.value = widget.cartItem.originalPrice - discount;
    isValid.value = true;
    errorMessage.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.discount, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text('sales_apply_discount'.tr),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du produit
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cartItem.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'sales_product_reference'.trParams({'ref': widget.cartItem.productReference}),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'sales_product_price'.trParams({'price': widget.cartItem.originalPrice.toStringAsFixed(0), 'currency': CurrencyConstants.defaultCurrency}),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        'sales_discount_max'.trParams({'max': widget.cartItem.maxDiscountAllowed.toStringAsFixed(0), 'currency': CurrencyConstants.defaultCurrency}),
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Champ de remise
            Obx(() => TextFormField(
                  controller: _discountController,
                  decoration: InputDecoration(
                    labelText: 'Montant de la remise',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.remove_circle_outline),
                    suffixText: CurrencyConstants.defaultCurrency,
                    border: const OutlineInputBorder(),
                    errorText: errorMessage.value.isEmpty ? null : errorMessage.value,
                    helperText: 'Maximum autorisé: ${widget.cartItem.maxDiscountAllowed.toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                )),
            const SizedBox(height: 16),

            // Champ de justification
            TextFormField(
              controller: _justificationController,
              decoration: const InputDecoration(
                labelText: 'Justification (optionnel)',
                hintText: 'Ex: Client fidèle, promotion, négociation...',
                prefixIcon: Icon(Icons.comment_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              inputFormatters: [
                LengthLimitingTextInputFormatter(500),
              ],
            ),
            const SizedBox(height: 16),

            // Résumé des calculs
            Obx(() => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('sales_discount_original_price'.tr),
                          const Spacer(),
                          Text(
                            '${widget.cartItem.originalPrice.toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (currentDiscount.value > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('sales_discount_applied'.tr),
                            const Spacer(),
                            Text(
                              '- ${currentDiscount.value.toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                      Row(
                        children: [
                          Text(
                            'Prix final:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${finalPrice.value.toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (currentDiscount.value > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('sales_discount_customer_savings'.tr),
                            const Spacer(),
                            Text(
                              '${(currentDiscount.value * widget.cartItem.quantity).toStringAsFixed(0)} ${CurrencyConstants.defaultCurrency}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr),
        ),
        Obx(() => ElevatedButton(
              onPressed: isValid.value ? _applyDiscount : null,
              child: Text('sales_discount_apply'.tr),
            )),
      ],
    );
  }

  void _applyDiscount() {
    final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final justification = _justificationController.text.trim();

    widget.onDiscountApplied(
      discount,
      justification.isEmpty ? null : justification,
    );

    Get.back();
  }
}

/// Service pour valider les remises (optionnel, pour validation côté serveur)
class DiscountValidationService extends GetxService {
  // Ce service pourrait être utilisé pour valider les remises côté serveur
  // avant de les appliquer, mais pour l'instant on fait la validation côté client
}
