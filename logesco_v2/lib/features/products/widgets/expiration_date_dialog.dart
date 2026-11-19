import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../controllers/expiration_date_controller.dart';
import '../models/expiration_date.dart';

/// Dialog pour ajouter/modifier une date de péremption
class ExpirationDateDialog extends StatefulWidget {
  final int produitId;
  final ExpirationDate? expirationDate;

  const ExpirationDateDialog({
    super.key,
    required this.produitId,
    this.expirationDate,
  });

  @override
  State<ExpirationDateDialog> createState() => _ExpirationDateDialogState();
}

class _ExpirationDateDialogState extends State<ExpirationDateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _numeroLotController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expirationDate != null) {
      _selectedDate = widget.expirationDate!.datePeremption;
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      _quantiteController.text = widget.expirationDate!.quantite.toString();
      _numeroLotController.text = widget.expirationDate!.numeroLot ?? '';
      _notesController.text = widget.expirationDate!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _quantiteController.dispose();
    _numeroLotController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('fr', 'FR'),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      SnackbarHelper.error('expiration_dialog_date_error'.tr);
      return;
    }

    setState(() => _isLoading = true);

    final controller = Get.find<ExpirationDateController>();
    bool success;

    if (widget.expirationDate == null) {
      success = await controller.createExpirationDate(
        produitId: widget.produitId,
        datePeremption: _selectedDate!,
        quantite: int.parse(_quantiteController.text),
        numeroLot: _numeroLotController.text.isEmpty ? null : _numeroLotController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    } else {
      success = await controller.updateExpirationDate(
        widget.expirationDate!.id,
        datePeremption: _selectedDate,
        quantite: int.parse(_quantiteController.text),
        numeroLot: _numeroLotController.text.isEmpty ? null : _numeroLotController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }

    setState(() => _isLoading = false);

    if (success) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.expirationDate == null ? 'products_add_expiration_date'.tr : 'expiration_dialog_edit_title'.tr,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Date de péremption
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'expiration_dialog_date_label'.tr,
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'expiration_dialog_date_required'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantité
              TextFormField(
                controller: _quantiteController,
                decoration: InputDecoration(
                  labelText: 'expiration_dialog_quantity_label'.tr,
                  prefixIcon: Icon(Icons.inventory_2),
                  suffixText: 'procurement_units'.tr,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'procurement_quantity_required'.tr;
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'expiration_dialog_quantity_invalid'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Numéro de lot
              TextFormField(
                controller: _numeroLotController,
                decoration: InputDecoration(
                  labelText: 'expiration_dialog_lot_label'.tr,
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                  helperText: 'Optionnel',
                ),
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  helperText: 'Optionnel',
                ),
                maxLines: 2,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
              ),
              const SizedBox(height: 24),

              // Boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    child: Text('suppliers_form_cancel'.tr),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.expirationDate == null ? 'Ajouter' : 'roles_modify'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
