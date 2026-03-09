import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/inventory_model.dart';
import '../controllers/stock_inventory_controller.dart';

/// Vue du formulaire d'inventaire
class InventoryFormView extends StatefulWidget {
  const InventoryFormView({super.key});

  @override
  State<InventoryFormView> createState() => _InventoryFormViewState();
}

class _InventoryFormViewState extends State<InventoryFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  InventoryType _selectedType = InventoryType.TOTAL;
  int? _selectedCategoryId;
  bool _isLoading = false;

  // Contrôleur pour accéder aux catégories
  late final StockInventoryController _controller;

  @override
  void initState() {
    super.initState();

    // Initialiser le contrôleur
    _controller = Get.find<StockInventoryController>();

    // Récupérer les arguments passés lors de la navigation
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['type'] != null) {
      _selectedType = arguments['type'] as InventoryType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('inventory_form_title'.tr),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelectionSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              if (_selectedType == InventoryType.PARTIEL) _buildCategorySelectionSection(),
              const SizedBox(height: 24),
              _buildSummarySection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'inventory_form_type_section'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: InventoryType.values.map((type) {
                return RadioListTile<InventoryType>(
                  title: Text(type.displayName),
                  subtitle: Text(type.description),
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      if (_selectedType == InventoryType.TOTAL) {
                        _selectedCategoryId = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
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
                Icon(Icons.info, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'inventory_form_info_section'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'inventory_form_name'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                hintText: 'inventory_form_name_hint'.tr,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'inventory_form_name_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'inventory_form_description'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                hintText: 'inventory_form_description_hint'.tr,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                Text(
                  'inventory_form_category_section'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'inventory_form_category'.tr,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.folder),
                  ),
                  items: _controller.categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category['id'],
                      child: Text(category['nom']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (_selectedType == InventoryType.PARTIEL && value == null) {
                      return 'inventory_form_category_required'.tr;
                    }
                    return null;
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'inventory_form_summary_section'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('inventory_type'.tr, _selectedType.displayName),
            if (_selectedType == InventoryType.PARTIEL && _selectedCategoryId != null)
              _buildSummaryRow(
                'inventory_form_category'.tr,
                _controller.categories.firstWhere((c) => c['id'] == _selectedCategoryId)['nom'],
              ),
            _buildSummaryRow('inventory_form_initial_status'.tr, 'inventory_form_draft'.tr),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'inventory_form_info_message'.tr,
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            child: Text('common_cancel'.tr),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createInventory,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('inventory_form_create'.tr),
          ),
        ),
      ],
    );
  }

  void _createInventory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer l'inventaire via le contrôleur
      final inventory = StockInventory(
        nom: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        categorieId: _selectedCategoryId,
        nomCategorie: _selectedCategoryId != null ? _controller.categories.firstWhere((c) => c['id'] == _selectedCategoryId)['nom'] : null,
        utilisateurId: 1, // TODO: Récupérer l'utilisateur actuel
        nomUtilisateur: 'Admin', // TODO: Récupérer l'utilisateur actuel
        status: InventoryStatus.BROUILLON,
        dateCreation: DateTime.now(),
      );

      final success = await _controller.createInventory(inventory);

      if (success) {
        Get.back(); // Retourner à la liste des inventaires
        // Le message de succès est déjà affiché par le contrôleur
      }
      // Si échec, le message d'erreur est déjà affiché par le contrôleur
      // L'utilisateur peut toujours utiliser le bouton retour de l'AppBar
    } catch (e) {
      Get.snackbar(
        'common_error'.tr,
        'inventory_form_error'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
