import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../printing/services/printing_service.dart';
import '../models/company_profile.dart';
import '../services/company_settings_service.dart';

class CompanySettingsController extends GetxController {
  final CompanySettingsService _companySettingsService = CompanySettingsService(Get.find<AuthService>());

  // État du profil d'entreprise
  final Rx<CompanyProfile?> _companyProfile = Rx<CompanyProfile?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isSaving = false.obs;
  final RxBool _hasUnsavedChanges = false.obs;

  // Contrôleurs de formulaire
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nuiRccmController = TextEditingController();
  final TextEditingController sloganController = TextEditingController();

  // État du logo
  final Rx<String?> _logoPath = Rx<String?>(null);
  String? get logoPath => _logoPath.value;

  // Langue des factures
  final Rx<String> _selectedLanguage = 'fr'.obs;
  String get selectedLanguage => _selectedLanguage.value;

  /// Définit la langue des factures
  void setLanguage(String language) {
    if (language != _selectedLanguage.value) {
      _selectedLanguage.value = language;
      _hasUnsavedChanges.value = true;
    }
  }

  // Clé du formulaire pour la validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Erreurs de validation
  final RxMap<String, String> _validationErrors = <String, String>{}.obs;

  // Permissions
  final RxBool _canEdit = false.obs;
  final RxBool _isAdmin = false.obs;

  // Getters
  CompanyProfile? get companyProfile => _companyProfile.value;
  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  bool get hasUnsavedChanges => _hasUnsavedChanges.value;
  Map<String, String> get validationErrors => _validationErrors;
  bool get canEdit => _canEdit.value;
  bool get isAdmin => _isAdmin.value;
  bool get hasProfile => _companyProfile.value != null;

  @override
  void onInit() {
    super.onInit();
    _initializePermissions();
    _setupFormListeners();
    loadCompanyProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    locationController.dispose();
    phoneController.dispose();
    emailController.dispose();
    nuiRccmController.dispose();
    sloganController.dispose();
    super.onClose();
  }

  /// Initialise les permissions utilisateur
  void _initializePermissions() {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    _isAdmin.value = user?.role.isAdmin ?? false;
    _canEdit.value = user?.role.canManageCompanySettings ?? false;
  }

  /// Configure les écouteurs de changement de formulaire
  void _setupFormListeners() {
    nameController.addListener(_onFormChanged);
    addressController.addListener(_onFormChanged);
    locationController.addListener(_onFormChanged);
    phoneController.addListener(_onFormChanged);
    emailController.addListener(_onFormChanged);
    nuiRccmController.addListener(_onFormChanged);
    sloganController.addListener(_onFormChanged);
  }

  /// Appelé quand le formulaire change
  void _onFormChanged() {
    if (_companyProfile.value != null) {
      final hasChanges = _hasFormChanges();
      if (hasChanges != _hasUnsavedChanges.value) {
        _hasUnsavedChanges.value = hasChanges;
      }
    }
  }

  /// Vérifie s'il y a des changements dans le formulaire
  bool _hasFormChanges() {
    final profile = _companyProfile.value;
    if (profile == null) return false;

    return nameController.text.trim() != profile.name ||
        addressController.text.trim() != profile.address ||
        locationController.text.trim() != (profile.location ?? '') ||
        phoneController.text.trim() != (profile.phone ?? '') ||
        emailController.text.trim() != (profile.email ?? '') ||
        nuiRccmController.text.trim() != (profile.nuiRccm ?? '') ||
        sloganController.text.trim() != (profile.slogan ?? '') ||
        _logoPath.value != profile.logo ||
        _selectedLanguage.value != (profile.receiptLanguage ?? 'fr');
  }

  /// Charge le profil d'entreprise
  Future<void> loadCompanyProfile({bool forceRefresh = false}) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _validationErrors.clear();

    try {
      final response = await _companySettingsService.getCompanyProfile(forceRefresh: forceRefresh);

      if (response.success && response.data != null) {
        _companyProfile.value = response.data;
        _populateForm(response.data!);
        _hasUnsavedChanges.value = false;

        // Mettre à jour le profil partagé dans le service d'impression
        PrintingService.setCompanyProfile(response.data);

        if (forceRefresh) {
          SnackbarUtils.showSuccess('Profil rechargé avec succès');
        }
      } else {
        // Profil non trouvé, initialiser un profil vide
        if (response.message?.contains('non trouvé') == true) {
          _companyProfile.value = null;
          _clearForm();
        } else {
          SnackbarUtils.showError(response.message ?? 'Erreur lors du chargement du profil');
        }
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur de connexion: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Remplit le formulaire avec les données du profil
  void _populateForm(CompanyProfile profile) {
    nameController.text = profile.name;
    addressController.text = profile.address;
    locationController.text = profile.location ?? '';
    phoneController.text = profile.phone ?? '';
    emailController.text = profile.email ?? '';
    nuiRccmController.text = profile.nuiRccm ?? '';
    sloganController.text = profile.slogan ?? '';
    _logoPath.value = profile.logo;
    _selectedLanguage.value = profile.receiptLanguage ?? 'fr';
  }

  /// Vide le formulaire
  void _clearForm() {
    nameController.clear();
    addressController.clear();
    locationController.clear();
    phoneController.clear();
    emailController.clear();
    nuiRccmController.clear();
    sloganController.clear();
    _logoPath.value = null;
    _hasUnsavedChanges.value = false;
  }

  /// Sauvegarde le profil d'entreprise
  Future<void> saveCompanyProfile() async {
    if (!_canEdit.value) {
      SnackbarUtils.showError('Vous n\'avez pas les permissions pour modifier le profil');
      return;
    }

    if (_isSaving.value) return;

    // Valider le formulaire
    if (!formKey.currentState!.validate()) {
      SnackbarUtils.showError('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    _isSaving.value = true;
    _validationErrors.clear();

    try {
      final request = CompanyProfileRequest(
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        location: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        nuiRccm: nuiRccmController.text.trim().isEmpty ? null : nuiRccmController.text.trim(),
        logo: _logoPath.value,
        slogan: sloganController.text.trim().isEmpty ? null : sloganController.text.trim(),
        receiptLanguage: _selectedLanguage.value,
      );

      final response = _companyProfile.value == null ? await _companySettingsService.createCompanyProfile(request) : await _companySettingsService.updateCompanyProfile(request);

      if (response.success && response.data != null) {
        _companyProfile.value = response.data;
        _hasUnsavedChanges.value = false;

        // Mettre à jour le profil partagé dans le service d'impression
        PrintingService.setCompanyProfile(response.data);
        print('✅ Profil d\'entreprise mis à jour dans le service d\'impression');

        SnackbarUtils.showSuccess(response.message ?? 'Profil sauvegardé avec succès');
      } else {
        if (response.errors != null && response.errors!.isNotEmpty) {
          // Afficher les erreurs de validation
          for (final error in response.errors!) {
            _validationErrors[error.field] = error.message;
          }
        }
        SnackbarUtils.showError(response.message ?? 'Erreur lors de la sauvegarde');
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur de connexion: $e');
    } finally {
      _isSaving.value = false;
    }
  }

  /// Supprime le profil d'entreprise
  Future<void> deleteCompanyProfile() async {
    if (!_isAdmin.value) {
      SnackbarUtils.showError('Seuls les administrateurs peuvent supprimer le profil');
      return;
    }

    if (_companyProfile.value == null) return;

    // Demander confirmation
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer le profil d\'entreprise ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isLoading.value = true;

    try {
      final response = await _companySettingsService.deleteCompanyProfile();

      if (response.success) {
        _companyProfile.value = null;
        _clearForm();
        SnackbarUtils.showSuccess(response.message ?? 'Profil supprimé avec succès');
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur de connexion: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Réinitialise le formulaire aux valeurs originales
  void resetForm() {
    if (_companyProfile.value != null) {
      _populateForm(_companyProfile.value!);
    } else {
      _clearForm();
    }
    _validationErrors.clear();
    _hasUnsavedChanges.value = false;
  }

  /// Valide un champ spécifique
  String? validateField(String field, String value) {
    final tempProfile = CompanyProfile(
      name: field == 'name' ? value : nameController.text,
      address: field == 'address' ? value : addressController.text,
      location: field == 'location' ? value : locationController.text,
      phone: field == 'phone' ? value : phoneController.text,
      email: field == 'email' ? value : emailController.text,
      nuiRccm: field == 'nuiRccm' ? value : nuiRccmController.text,
      slogan: field == 'slogan' ? value : sloganController.text,
      logo: _logoPath.value,
    );

    final errors = tempProfile.validate();
    return errors[field];
  }

  /// Vérifie si l'utilisateur peut quitter sans sauvegarder
  Future<bool> canPop() async {
    if (!_hasUnsavedChanges.value) return true;

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text(
          'Vous avez des modifications non sauvegardées. '
          'Voulez-vous les abandonner ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Rafraîchit les données
  Future<void> refresh() async {
    await loadCompanyProfile(forceRefresh: true);
  }

  /// Obtient l'erreur de validation pour un champ
  String? getFieldError(String field) {
    return _validationErrors[field];
  }

  /// Efface l'erreur de validation pour un champ
  void clearFieldError(String field) {
    _validationErrors.remove(field);
  }

  /// Sélectionne un fichier logo
  Future<void> selectLogo() async {
    try {
      // Ouvrir le sélecteur de fichiers pour les images
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Vérifier que le fichier existe
        final file = File(filePath);
        if (!await file.exists()) {
          SnackbarUtils.showError('Le fichier sélectionné n\'existe pas');
          return;
        }

        // Vérifier la taille du fichier (max 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          SnackbarUtils.showError('Le fichier est trop volumineux (max 5MB)');
          return;
        }

        // Mettre à jour le chemin du logo
        _logoPath.value = filePath;
        _hasUnsavedChanges.value = true;

        SnackbarUtils.showSuccess('Logo sélectionné: ${result.files.single.name}');
      }
    } catch (e) {
      print('❌ Erreur lors de la sélection du logo: $e');
      SnackbarUtils.showError('Erreur lors de la sélection du fichier: $e');
    }
  }

  /// Supprime le logo
  void removeLogo() {
    _logoPath.value = null;
    _hasUnsavedChanges.value = true;
  }
}
