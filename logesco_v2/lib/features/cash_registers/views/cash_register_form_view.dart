import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/cash_register_controller.dart';
import '../models/cash_register_model.dart';

/// Vue du formulaire de caisse (création/modification)
class CashRegisterFormView extends StatefulWidget {
  const CashRegisterFormView({super.key});

  @override
  State<CashRegisterFormView> createState() => _CashRegisterFormViewState();
}

class _CashRegisterFormViewState extends State<CashRegisterFormView> {
  final CashRegisterController controller = Get.find<CashRegisterController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _initialBalanceController;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final cashRegister = controller.selectedCashRegister.value;

    _nameController = TextEditingController(text: cashRegister?.nom ?? '');
    _descriptionController = TextEditingController(text: cashRegister?.description ?? '');
    _initialBalanceController = TextEditingController(text: cashRegister?.soldeInitial.toString() ?? '0.00');

    _isActive = cashRegister?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.selectedCashRegister.value != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Caisse' : 'Nouvelle Caisse'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildFinancialSection(isEditing),
              const SizedBox(height: 24),
              _buildStatusSection(),
              const SizedBox(height: 32),
              _buildActionButtons(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.point_of_sale, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Informations de base',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la caisse *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
                hintText: 'Ex: Caisse Principale',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le nom de la caisse est requis';
                }
                if (value.length < 3) {
                  return 'Le nom doit contenir au moins 3 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Description optionnelle de la caisse',
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.length > 255) {
                  return 'La description ne peut pas dépasser 255 caractères';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSection(bool isEditing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Configuration financière',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _initialBalanceController,
              decoration: const InputDecoration(
                labelText: 'Solde initial *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'FCFA',
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le solde initial est requis';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Veuillez entrer un montant valide';
                }
                if (amount < 0) {
                  return 'Le solde initial ne peut pas être négatif';
                }
                return null;
              },
              enabled: !isEditing, // Ne pas permettre de modifier le solde initial lors de l'édition
            ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              Text(
                'Le solde initial ne peut pas être modifié après la création',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.toggle_on, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Statut de la caisse',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Caisse active'),
              subtitle: Text(
                _isActive ? 'La caisse peut être utilisée pour les transactions' : 'La caisse est désactivée et ne peut pas être utilisée',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(() {
            return ElevatedButton(
              onPressed: controller.isLoading.value ? null : _saveCashRegister,
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Mettre à jour' : 'Créer'),
            );
          }),
        ),
      ],
    );
  }

  void _saveCashRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final cashRegister = CashRegister(
      id: controller.selectedCashRegister.value?.id,
      nom: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? '' : _descriptionController.text.trim(),
      soldeInitial: double.parse(_initialBalanceController.text),
      soldeActuel: controller.selectedCashRegister.value?.soldeActuel ?? double.parse(_initialBalanceController.text),
      isActive: _isActive,
      dateCreation: controller.selectedCashRegister.value?.dateCreation,
      dateModification: controller.selectedCashRegister.value?.dateModification,
      dateOuverture: controller.selectedCashRegister.value?.dateOuverture,
      dateFermeture: controller.selectedCashRegister.value?.dateFermeture,
    );

    bool success;
    if (controller.selectedCashRegister.value != null) {
      success = await controller.updateCashRegister(cashRegister);
    } else {
      success = await controller.createCashRegister(cashRegister);
    }

    if (success) {
      Get.back();
    }
  }

  void _confirmDelete() {
    final cashRegister = controller.selectedCashRegister.value;
    if (cashRegister == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la caisse "${cashRegister.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteCashRegister(cashRegister.id!);
              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
