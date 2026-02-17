import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/role_controller.dart';
import '../models/role_model.dart';

/// Page de formulaire pour créer/modifier un rôle
class RoleFormPage extends GetView<RoleController> {
  final UserRole? role;

  const RoleFormPage({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role == null ? 'Nouveau rôle' : 'Modifier le rôle'),
        elevation: 0,
      ),
      body: const RoleFormView(),
    );
  }
}

/// Widget du formulaire de rôle
class RoleFormView extends StatefulWidget {
  const RoleFormView({super.key});

  @override
  State<RoleFormView> createState() => _RoleFormViewState();
}

class _RoleFormViewState extends State<RoleFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isAdmin = false;
  Map<String, List<String>> _selectedPrivileges = {};

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final controller = Get.find<RoleController>();
    final role = controller.selectedRole.value;

    if (role != null) {
      _nomController.text = role.nom;
      _displayNameController.text = role.displayName;
      _isAdmin = role.isAdmin;
      _selectedPrivileges = Map<String, List<String>>.from(role.privileges);
    } else {
      // Initialiser avec des privilèges vides pour chaque module
      for (String module in ModulePrivileges.availablePrivileges.keys) {
        _selectedPrivileges[module] = [];
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildAdminSection(),
                  const SizedBox(height: 24),
                  if (!_isAdmin) _buildPrivilegesSection(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
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
            Text(
              'Informations de base',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du rôle *',
                hintText: 'Ex: MANAGER, EMPLOYEE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom du rôle est obligatoire';
                }
                if (value.trim().length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'affichage *',
                hintText: 'Ex: Gestionnaire, Employé',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom d\'affichage est obligatoire';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type de rôle',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Administrateur'),
              subtitle: const Text('Accès complet à toutes les fonctionnalités'),
              value: _isAdmin,
              onChanged: (value) {
                setState(() {
                  _isAdmin = value;
                  if (value) {
                    // Si admin, vider les privilèges spécifiques
                    _selectedPrivileges.clear();
                  } else {
                    // Si pas admin, initialiser les privilèges vides
                    for (String module in ModulePrivileges.availablePrivileges.keys) {
                      _selectedPrivileges[module] = [];
                    }
                  }
                });
              },
              secondary: Icon(
                _isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: _isAdmin ? Colors.red : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Privilèges par module',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _selectAllPrivileges,
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('Tout sélectionner'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clearAllPrivileges,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Tout désélectionner'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...ModulePrivileges.availablePrivileges.entries.map(
              (entry) => _buildModulePrivileges(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulePrivileges(String module, List<String> availablePrivileges) {
    final moduleDisplayName = ModulePrivileges.moduleDisplayNames[module] ?? module;
    final selectedForModule = _selectedPrivileges[module] ?? [];

    return ExpansionTile(
      title: Text(moduleDisplayName),
      subtitle: Text('${selectedForModule.length}/${availablePrivileges.length} privilèges'),
      leading: Icon(
        _getModuleIcon(module),
        color: selectedForModule.isNotEmpty ? Colors.green : Colors.grey,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Boutons pour sélectionner/désélectionner tous les privilèges du module
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _selectAllModulePrivileges(module),
                    icon: const Icon(Icons.check_box, size: 16),
                    label: const Text('Tout'),
                  ),
                  TextButton.icon(
                    onPressed: () => _clearModulePrivileges(module),
                    icon: const Icon(Icons.check_box_outline_blank, size: 16),
                    label: const Text('Aucun'),
                  ),
                ],
              ),
              // Liste des privilèges
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: availablePrivileges.map((privilege) {
                  final isSelected = selectedForModule.contains(privilege);
                  final displayName = ModulePrivileges.privilegeDisplayNames[privilege] ?? privilege;

                  return FilterChip(
                    label: Text(displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        // S'assurer que le module existe dans _selectedPrivileges
                        if (!_selectedPrivileges.containsKey(module)) {
                          _selectedPrivileges[module] = [];
                        }

                        if (selected) {
                          _selectedPrivileges[module]!.add(privilege);
                        } else {
                          _selectedPrivileges[module]!.remove(privilege);
                        }
                      });
                    },
                    selectedColor: Colors.blue.withOpacity(0.2),
                    checkmarkColor: Colors.blue,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Obx(() {
              final controller = Get.find<RoleController>();
              return ElevatedButton(
                onPressed: controller.isLoading.value ? null : _saveRole,
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(controller.selectedRole.value == null ? 'Créer' : 'Modifier'),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getModuleIcon(String module) {
    switch (module) {
      case 'dashboard':
        return Icons.dashboard;
      case 'products':
        return Icons.inventory_2;
      case 'categories':
        return Icons.category;
      case 'inventory':
        return Icons.warehouse;
      case 'suppliers':
        return Icons.business;
      case 'customers':
        return Icons.people;
      case 'sales':
        return Icons.point_of_sale;
      case 'procurement':
        return Icons.shopping_cart;
      case 'accounts':
        return Icons.account_balance;
      case 'financial_movements':
        return Icons.account_balance_wallet;
      case 'cash_registers':
        return Icons.point_of_sale;
      case 'stock_inventory':
        return Icons.inventory;
      case 'users':
        return Icons.group;
      case 'company_settings':
        return Icons.business_center;
      case 'printing':
        return Icons.print;
      case 'reports':
        return Icons.analytics;
      default:
        return Icons.extension;
    }
  }

  void _selectAllPrivileges() {
    setState(() {
      for (String module in ModulePrivileges.availablePrivileges.keys) {
        _selectedPrivileges[module] = List<String>.from(ModulePrivileges.availablePrivileges[module]!);
      }
    });
  }

  void _clearAllPrivileges() {
    setState(() {
      for (String module in ModulePrivileges.availablePrivileges.keys) {
        _selectedPrivileges[module] = [];
      }
    });
  }

  void _selectAllModulePrivileges(String module) {
    setState(() {
      _selectedPrivileges[module] = List<String>.from(ModulePrivileges.availablePrivileges[module]!);
    });
  }

  void _clearModulePrivileges(String module) {
    setState(() {
      _selectedPrivileges[module] = [];
    });
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = Get.find<RoleController>();
    final existingRole = controller.selectedRole.value;

    // Vérifier la disponibilité du nom
    final isNameAvailable = await controller.isRoleNameAvailable(
      _nomController.text.trim().toUpperCase(),
      excludeId: existingRole?.id,
    );

    if (!isNameAvailable) {
      Get.snackbar(
        'Erreur',
        'Un rôle avec ce nom existe déjà',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
      return;
    }

    final role = UserRole(
      id: existingRole?.id,
      nom: _nomController.text.trim().toUpperCase(),
      displayName: _displayNameController.text.trim(),
      isAdmin: _isAdmin,
      privileges: _isAdmin ? {} : Map<String, List<String>>.from(_selectedPrivileges),
    );

    bool success;
    if (existingRole == null) {
      success = await controller.createRole(role);
    } else {
      success = await controller.updateRole(role);
    }

    if (success) {
      Get.back();
      Get.snackbar(
        'Succès',
        existingRole == null ? 'Rôle créé avec succès' : 'Rôle modifié avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
    } else {
      Get.snackbar(
        'Erreur',
        controller.error.value.isNotEmpty ? controller.error.value : 'Une erreur est survenue',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }
}
