import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import '../models/role_model.dart' as role_model;

/// Vue du formulaire utilisateur (création/modification)
class UserFormView extends StatefulWidget {
  const UserFormView({super.key});

  @override
  State<UserFormView> createState() => _UserFormViewState();
}

class _UserFormViewState extends State<UserFormView> {
  final UserController controller = Get.find<UserController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String? _selectedRoleNom;
  bool _isActive = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = controller.selectedUser.value;

    _usernameController = TextEditingController(text: user?.nomUtilisateur ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    if (user?.role != null) {
      _selectedRoleNom = user!.role.nom;
    } else if (controller.availableRoles.isNotEmpty) {
      _selectedRoleNom = controller.availableRoles.first.nom;
    } else {
      _selectedRoleNom = null;
    }
    _isActive = user?.isActive ?? true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = controller.selectedUser.value != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'users_edit'.tr : 'users_add'.tr),
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
              _buildPasswordSection(isEditing),
              const SizedBox(height: 24),
              _buildRoleSection(),
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
                Icon(Icons.person, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'users_basic_info'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'users_username'.tr + ' *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_circle),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'users_username_required'.tr;
                }
                if (value.length < 3) {
                  return 'users_username_min_length'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'users_email'.tr + ' *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'users_email_required'.tr;
                }
                if (!GetUtils.isEmail(value)) {
                  return 'users_email_invalid'.tr;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection(bool isEditing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'users_change_password'.tr : 'users_password_section'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              Text(
                'users_password_keep_current'.tr,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: isEditing ? 'users_new_password'.tr : 'users_password'.tr + ' *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              obscureText: !_showPassword,
              validator: (value) {
                if (!isEditing && (value == null || value.isEmpty)) {
                  return 'users_password_required'.tr;
                }
                if (value != null && value.isNotEmpty && value.length < 6) {
                  return 'users_password_min_length'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: isEditing ? 'users_confirm_new_password'.tr : 'users_confirm_password'.tr + ' *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                ),
              ),
              obscureText: !_showConfirmPassword,
              validator: (value) {
                if (_passwordController.text.isNotEmpty) {
                  if (value != _passwordController.text) {
                    return 'users_passwords_not_match'.tr;
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                Text(
                  'users_role_privileges'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              // S'assurer que les rôles sont chargés
              if (controller.availableRoles.isEmpty) {
                return const CircularProgressIndicator();
              }

              // S'assurer que la valeur sélectionnée existe dans la liste
              final validSelectedRole = controller.availableRoles.any((role) => role.nom == _selectedRoleNom) ? _selectedRoleNom : controller.availableRoles.first.nom;

              // Mettre à jour la sélection si nécessaire
              if (_selectedRoleNom != validSelectedRole) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _selectedRoleNom = validSelectedRole);
                });
              }

              return DropdownButtonFormField<String>(
                value: validSelectedRole,
                decoration: InputDecoration(
                  labelText: 'users_role'.tr + ' *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.security),
                ),
                items: controller.availableRoles.map((role) {
                  return DropdownMenuItem(
                    value: role.nom,
                    child: Row(
                      children: [
                        Icon(
                          role.isAdmin ? Icons.admin_panel_settings : Icons.person,
                          size: 20,
                          color: role.isAdmin ? Colors.amber.shade700 : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(role.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (roleNom) => setState(() => _selectedRoleNom = roleNom),
                validator: (value) {
                  if (value == null) {
                    return 'users_role_required'.tr;
                  }
                  return null;
                },
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.availableRoles.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text('Chargement des rôles...'),
                );
              }

              final selectedRole = controller.availableRoles.firstWhereOrNull(
                (role) => role.nom == _selectedRoleNom,
              );

              if (selectedRole == null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Text('Aucun rôle sélectionné'),
                );
              }

              return _buildPrivilegesPreview(selectedRole);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegesPreview(role_model.UserRole role) {
    if (role.isAdmin) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Text(
              'users_admin_access'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
      );
    }

    // Construire la liste des privilèges par module
    final List<Widget> moduleWidgets = [];

    role.privileges.forEach((module, privileges) {
      if (privileges.isNotEmpty) {
        final moduleDisplayName = role_model.ModulePrivileges.moduleDisplayNames[module] ?? module;
        final privilegeNames = privileges.map((p) => role_model.ModulePrivileges.privilegeDisplayNames[p] ?? p).join(', ');

        moduleWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  privilegeNames,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'users_privileges_granted'.tr,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (moduleWidgets.isEmpty)
            Text(
              'users_no_special_privileges'.tr,
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: moduleWidgets,
            ),
        ],
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
                Icon(Icons.toggle_on, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'users_account_status'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('users_account_active'.tr),
              subtitle: Text(
                _isActive ? 'users_can_login'.tr : 'users_cannot_login'.tr,
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
            onPressed: () {
              print('🔙 [UserFormView] Bouton Annuler pressé');
              Get.back();
              print('🔙 [UserFormView] Navigation arrière Annuler terminée');
            },
            child: Text('common_cancel'.tr),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(() {
            return ElevatedButton(
              onPressed: controller.isLoading.value ? null : _saveUser,
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'users_update'.tr : 'users_create'.tr),
            );
          }),
        ),
      ],
    );
  }

  void _saveUser() async {
    print('💾 [UserFormView] Début _saveUser()');

    if (!_formKey.currentState!.validate()) {
      print('❌ [UserFormView] Validation du formulaire échouée');
      return;
    }

    if (_selectedRoleNom == null || controller.availableRoles.isEmpty) {
      print('❌ [UserFormView] Aucun rôle sélectionné ou disponible');
      return;
    }

    // Trouver le rôle sélectionné dans la liste des rôles disponibles
    final selectedRole = controller.availableRoles.firstWhere(
      (role) => role.nom == _selectedRoleNom,
      orElse: () => controller.availableRoles.first,
    );

    print('👤 [UserFormView] Rôle sélectionné: ${selectedRole.displayName}');

    final user = User(
      id: controller.selectedUser.value?.id,
      nomUtilisateur: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      role: selectedRole,
      isActive: _isActive,
    );

    final password = _passwordController.text.isNotEmpty ? _passwordController.text : null;
    final isEditing = controller.selectedUser.value != null;

    print('💾 [UserFormView] ${isEditing ? 'Modification' : 'Création'} utilisateur: ${user.nomUtilisateur}');

    bool success;
    if (isEditing) {
      success = await controller.updateUser(user, motDePasse: password);
    } else {
      success = await controller.createUser(user, motDePasse: password);
    }

    print('📊 [UserFormView] Résultat de sauvegarde: $success');

    if (success) {
      print('✅ [UserFormView] Navigation arrière...');
      Get.back();
      print('✅ [UserFormView] Navigation arrière terminée');
    } else {
      print('❌ [UserFormView] Échec de sauvegarde, pas de navigation');
    }
  }

  void _confirmDelete() {
    final user = controller.selectedUser.value;
    if (user == null) return;

    Get.dialog(
      AlertDialog(
        title: Text('users_delete_confirm_title'.tr),
        content: Text('users_delete_confirm_message'.trParams({'username': user.nomUtilisateur})),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('common_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteUser(user.id!);
              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('users_delete'.tr),
          ),
        ],
      ),
    );
  }
}
