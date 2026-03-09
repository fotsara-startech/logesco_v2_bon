import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/financial_movement_controller.dart';
import '../models/financial_movement.dart';
import '../../cash_registers/controllers/cash_session_controller.dart';

import '../widgets/amount_input.dart';
import '../widgets/category_selector.dart';
import '../widgets/field_validation_indicator.dart';

/// Page de formulaire pour créer ou modifier un mouvement financier
class MovementFormPage extends StatefulWidget {
  final FinancialMovement? movement; // null pour création, non-null pour édition

  const MovementFormPage({
    super.key,
    this.movement,
  });

  @override
  State<MovementFormPage> createState() => _MovementFormPageState();
}

class _MovementFormPageState extends State<MovementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final FinancialMovementController _controller = Get.find<FinancialMovementController>();

  // Contrôleurs de champs
  late TextEditingController _montantController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  // Variables d'état
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  double? _currentCashBalance; // Solde actuel de la caisse

  // Variables pour la validation en temps réel
  String? _montantError;
  String? _descriptionError;
  String? _categoryError;
  String? _dateError;
  bool _hasUserInteracted = false;
  bool _isFormValid = false;

  // Mode édition
  bool get _isEditing => widget.movement != null;

  // Mode duplication
  bool get _isDuplicating {
    final arguments = Get.arguments;
    return arguments is Map && arguments['duplicate'] == true;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Vérifier si c'est une duplication
    final arguments = Get.arguments;
    final isDuplicating = arguments is Map && arguments['duplicate'] == true;
    final duplicateMovement = isDuplicating ? arguments['movement'] as FinancialMovement? : null;

    if (_isEditing) {
      // Mode édition - pré-remplir avec les données existantes
      _montantController = TextEditingController(
        text: widget.movement!.montant.toString(),
      );
      _descriptionController = TextEditingController(
        text: widget.movement!.description,
      );
      _notesController = TextEditingController(
        text: widget.movement!.notes ?? '',
      );
      _selectedCategoryId = widget.movement!.categorieId;
      _selectedDate = widget.movement!.date;
    } else if (isDuplicating && duplicateMovement != null) {
      // Mode duplication - pré-remplir avec les données du mouvement à dupliquer
      _montantController = TextEditingController(
        text: duplicateMovement.montant.toString(),
      );
      _descriptionController = TextEditingController(
        text: 'Copie - ${duplicateMovement.description}',
      );
      _notesController = TextEditingController(
        text: duplicateMovement.notes ?? '',
      );
      _selectedCategoryId = duplicateMovement.categorieId;
      _selectedDate = DateTime.now(); // Nouvelle date pour la duplication
    } else {
      // Mode création - champs vides
      _montantController = TextEditingController();
      _descriptionController = TextEditingController();
      _notesController = TextEditingController();
    }

    // Ajouter les listeners pour la validation en temps réel
    _montantController.addListener(_validateAmount);
    _descriptionController.addListener(_validateDescription);

    // Validation initiale si on est en mode édition
    if (_isEditing || isDuplicating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateAllFields();
      });
    }
  }

  void _loadInitialData() {
    // S'assurer que les catégories sont chargées
    if (_controller.categories.isEmpty) {
      _controller.loadCategories();
    }

    // Charger le solde de caisse actuel
    _loadCashBalance();
  }

  /// Charge le solde actuel de la caisse
  Future<void> _loadCashBalance() async {
    try {
      // Importer le contrôleur de session de caisse
      final cashSessionController = Get.find<CashSessionController>();

      // Récupérer le solde attendu de la session active
      if (cashSessionController.hasActiveSession && cashSessionController.canViewBalance) {
        setState(() {
          _currentCashBalance = cashSessionController.currentCashBalance;
        });
        print('💰 Solde caisse chargé: ${_currentCashBalance?.toStringAsFixed(0)} FCFA');
      }
    } catch (e) {
      print('⚠️ Impossible de charger le solde de caisse: $e');
      // Ne pas bloquer si le contrôleur n'est pas disponible
    }
  }

  // Méthodes de validation en temps réel
  void _validateAmount() {
    if (!_hasUserInteracted) return;

    setState(() {
      final value = _montantController.text.trim();
      if (value.isEmpty) {
        _montantError = 'financial_movements_form_amount_required'.tr;
      } else {
        final amount = double.tryParse(value);
        if (amount == null) {
          _montantError = 'financial_movements_form_amount_invalid'.tr;
        } else if (amount <= 0) {
          _montantError = 'financial_movements_form_amount_positive'.tr;
        } else if (amount > 999999999) {
          _montantError = 'Le montant est trop élevé (max: 999,999,999)';
        } else {
          _montantError = null;
        }
      }
      _updateFormValidation();
    });
  }

  void _validateDescription() {
    if (!_hasUserInteracted) return;

    setState(() {
      final value = _descriptionController.text.trim();
      if (value.isEmpty) {
        _descriptionError = 'financial_movements_form_description_required'.tr;
      } else if (value.length < 3) {
        _descriptionError = 'financial_movements_form_description_min_length'.tr;
      } else if (value.length > 500) {
        _descriptionError = 'La description ne peut pas dépasser 500 caractères';
      } else {
        _descriptionError = null;
      }
      _updateFormValidation();
    });
  }

  void _validateCategory() {
    if (!_hasUserInteracted) return;

    setState(() {
      if (_selectedCategoryId == null) {
        _categoryError = 'financial_movements_form_category_required'.tr;
      } else {
        _categoryError = null;
      }
      _updateFormValidation();
    });
  }

  void _validateDate() {
    if (!_hasUserInteracted) return;

    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

      if (selectedDay.isAfter(today)) {
        _dateError = 'La date ne peut pas être dans le futur';
      } else {
        final oldestAllowed = DateTime(2020, 1, 1);
        if (_selectedDate.isBefore(oldestAllowed)) {
          _dateError = 'La date ne peut pas être antérieure à 2020';
        } else {
          _dateError = null;
        }
      }
      _updateFormValidation();
    });
  }

  void _validateAllFields() {
    _hasUserInteracted = true;
    _validateAmount();
    _validateDescription();
    _validateCategory();
    _validateDate();
  }

  void _updateFormValidation() {
    final isValid = _montantError == null &&
        _descriptionError == null &&
        _categoryError == null &&
        _dateError == null &&
        _montantController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedCategoryId != null;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _markUserInteraction() {
    if (!_hasUserInteracted) {
      setState(() {
        _hasUserInteracted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'financial_movements_form_title_edit'.tr
            : _isDuplicating
                ? 'financial_movements_form_title_duplicate'.tr
                : 'financial_movements_form_title_create'.tr),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete),
              tooltip: 'delete'.tr,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage du solde de caisse disponible
            if (_currentCashBalance != null && !_isEditing) _buildCashBalanceCard(),

            // Affichage du statut de validation
            if (_hasUserInteracted) _buildValidationStatusCard(),

            // Informations de base
            _buildBasicInfoSection(),

            const SizedBox(height: 24),

            // Sélection de catégorie
            _buildCategorySection(),

            const SizedBox(height: 24),

            // Sélection de date
            _buildDateSection(),

            const SizedBox(height: 24),

            // Notes optionnelles
            _buildNotesSection(),

            const SizedBox(height: 24),

            // Informations d'édition (si applicable)
            if (_isEditing) _buildEditInfoSection(),

            // Espace pour le bottom bar
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCashBalanceCard() {
    final balance = _currentCashBalance!;
    final isNegative = balance < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNegative ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNegative ? Colors.red.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isNegative ? Colors.red.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: isNegative ? Colors.red.shade700 : Colors.blue.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'financial_movements_form_cash_balance'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: isNegative ? Colors.red.shade700 : Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${balance.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isNegative ? Colors.red.shade700 : Colors.blue.shade700,
                  ),
                ),
                if (isNegative) ...[
                  const SizedBox(height: 4),
                  Text(
                    '⚠️ Solde négatif',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationStatusCard() {
    final errors = <String>[];
    if (_montantError != null) errors.add(_montantError!);
    if (_descriptionError != null) errors.add(_descriptionError!);
    if (_categoryError != null) errors.add(_categoryError!);
    if (_dateError != null) errors.add(_dateError!);

    final isValid = errors.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle_outline : Icons.error_outline,
                color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isValid ? 'Formulaire valide' : 'Erreurs de validation',
                style: TextStyle(
                  color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: 8),
            ...errors.map((error) => Padding(
                  padding: const EdgeInsets.only(left: 28, bottom: 4),
                  child: Text(
                    '• $error',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14,
                    ),
                  ),
                )),
          ] else ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                'Tous les champs sont correctement remplis',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de base',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Champ montant
            AmountInput(
              controller: _montantController,
              labelText: 'Montant',
              hintText: 'Entrez le montant',
              isRequired: true,
              validator: (_) => _montantError,
              onChanged: (value) {
                _markUserInteraction();
                _validateAmount();
              },
            ),

            const SizedBox(height: 16),

            // Champ description
            RealTimeValidatedTextField(
              controller: _descriptionController,
              labelText: 'Description',
              hintText: 'Décrivez la nature de cette dépense',
              prefixIcon: Icons.description,
              maxLines: 3,
              maxLength: 500,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est obligatoire';
                }
                if (value.trim().length < 3) {
                  return 'La description doit contenir au moins 3 caractères';
                }
                if (value.length > 500) {
                  return 'La description ne peut pas dépasser 500 caractères';
                }
                return null;
              },
              onChanged: (value) {
                _markUserInteraction();
                _validateDescription();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catégorie *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ValidationWrapper(
              hasInteracted: _hasUserInteracted,
              isValid: _selectedCategoryId != null && _categoryError == null,
              errorText: _categoryError,
              child: GetBuilder<FinancialMovementController>(
                builder: (controller) => CategorySelector(
                  categories: controller.categories,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (categoryId) {
                    _markUserInteraction();
                    setState(() {
                      _selectedCategoryId = categoryId;
                    });
                    _validateCategory();
                  },
                  isRequired: true,
                  errorText: null, // Géré par ValidationWrapper
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ValidationWrapper(
              hasInteracted: _hasUserInteracted,
              isValid: _dateError == null,
              errorText: _dateError,
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _dateError != null ? Colors.red : Colors.grey.shade300,
                      width: _dateError != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _dateError != null ? Colors.red : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date du mouvement',
                              style: TextStyle(
                                fontSize: 12,
                                color: _dateError != null ? Colors.red : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(_selectedDate),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _dateError != null ? Colors.red : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: _dateError != null ? Colors.red : Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes (optionnel)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ajoutez des notes ou commentaires supplémentaires...',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Référence',
              widget.movement!.reference,
              Icons.tag,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Créé le',
              _formatDateTime(widget.movement!.dateCreation),
              Icons.access_time,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Modifié le',
              _formatDateTime(widget.movement!.dateModification),
              Icons.update,
            ),
            if (widget.movement!.utilisateurNom != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'Créé par',
                widget.movement!.utilisateurNom!,
                Icons.person,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Get.back(),
              child: Text('cancel'.tr),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: (_isLoading || (!_isFormValid && _hasUserInteracted)) ? null : _saveMovement,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid || !_hasUserInteracted ? null : Colors.grey.shade400,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_hasUserInteracted && !_isFormValid) ...[
                          const Icon(Icons.error_outline, size: 16),
                          const SizedBox(width: 4),
                        ],
                        Text(_isEditing ? 'edit'.tr : 'save'.tr),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (date != null) {
      _markUserInteraction();
      setState(() {
        _selectedDate = date;
      });
      _validateDate();
    }
  }

  Future<void> _saveMovement() async {
    // Marquer l'interaction utilisateur et valider tous les champs
    _markUserInteraction();
    _validateAllFields();

    // Vérifier si le formulaire est valide
    if (!_isFormValid) {
      // Afficher un message d'erreur global
      Get.snackbar(
        'Formulaire invalide',
        'Veuillez corriger les erreurs avant de continuer',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Vérifier si la dépense dépasse le solde disponible
    if (!_isEditing && _currentCashBalance != null) {
      final montant = double.parse(_montantController.text.trim());
      if (montant > _currentCashBalance!) {
        final shouldContinue = await _showBalanceWarningDialog(montant, _currentCashBalance!);
        if (!shouldContinue) {
          return; // L'utilisateur a annulé
        }
      }
    }

    // Création de l'objet formulaire
    final form = FinancialMovementForm(
      montant: double.parse(_montantController.text.trim()),
      categorieId: _selectedCategoryId!,
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isEditing) {
        success = await _controller.updateMovement(widget.movement!.id, form);
      } else {
        success = await _controller.createMovement(form);
      }

      if (success) {
        // Actualiser le solde de caisse après création
        if (!_isEditing) {
          await _refreshCashBalance();
        }

        // Fermer le formulaire seulement si l'opération a réussi
        Get.back();
        Get.snackbar(
          'success'.tr,
          _isEditing ? 'financial_movements_form_success_update'.tr : 'financial_movements_form_success_create'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        // Afficher un message d'erreur mais garder le formulaire ouvert
        Get.snackbar(
          'error'.tr,
          'financial_movements_form_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'financial_movements_form_error'.tr,
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

  /// Affiche un dialog d'avertissement si la dépense dépasse le solde
  Future<bool> _showBalanceWarningDialog(double montant, double soldeActuel) async {
    final deficit = montant - soldeActuel;
    final nouveauSolde = soldeActuel - montant;

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Avertissement')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La dépense que vous souhaitez enregistrer dépasse le solde disponible en caisse.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  _buildWarningRow('Solde actuel', '${soldeActuel.toStringAsFixed(0)} FCFA', Colors.blue),
                  const SizedBox(height: 8),
                  _buildWarningRow('Montant dépense', '${montant.toStringAsFixed(0)} FCFA', Colors.orange),
                  const Divider(height: 24),
                  _buildWarningRow('Déficit', '${deficit.toStringAsFixed(0)} FCFA', Colors.red),
                  const SizedBox(height: 8),
                  _buildWarningRow('Nouveau solde', '${nouveauSolde.toStringAsFixed(0)} FCFA', Colors.red, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le solde de la caisse deviendra négatif. Vous pouvez continuer si nécessaire.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
            child: const Text('Continuer quand même'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildWarningRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Actualise le solde de caisse après création d'une dépense
  Future<void> _refreshCashBalance() async {
    try {
      final cashSessionController = Get.find<CashSessionController>();
      await cashSessionController.loadActiveSession();
      print('✅ Solde de caisse actualisé');
    } catch (e) {
      print('⚠️ Impossible d\'actualiser le solde: $e');
    }
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text('financial_movements_delete'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('financial_movements_delete_confirm'.tr),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'financial_movements_reference'.tr}: ${widget.movement!.reference}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text('${'financial_movements_amount'.tr}: ${widget.movement!.montantFormate}'),
                  Text('${'financial_movements_description'.tr}: ${widget.movement!.description}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette action est irréversible.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _controller.deleteMovement(widget.movement!.id);
              Get.back(); // Ferme le dialog
              if (success) {
                Get.back(); // Retourne à la liste
                Get.snackbar(
                  'success'.tr,
                  'Mouvement supprimé avec succès',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.shade100,
                  colorText: Colors.green.shade800,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
