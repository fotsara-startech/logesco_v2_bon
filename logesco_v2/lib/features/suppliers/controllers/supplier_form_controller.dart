import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';
import 'supplier_controller.dart';

/// Contrôleur pour le formulaire de création/modification des fournisseurs
class SupplierFormController extends GetxController {
  final SupplierService _supplierService = Get.find<SupplierService>();

  // Clé du formulaire
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Contrôleurs des champs
  final TextEditingController nomController = TextEditingController();
  final TextEditingController personneContactController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();

  // État
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;

  // Fournisseur en cours d'édition
  Supplier? _currentSupplier;

  @override
  void onInit() {
    super.onInit();
    print('🔧 Initialisation SupplierFormController');
    _initializeForm();
  }

  @override
  void onClose() {
    nomController.dispose();
    personneContactController.dispose();
    telephoneController.dispose();
    emailController.dispose();
    adresseController.dispose();
    super.onClose();
  }

  /// Initialise le formulaire selon le mode (création/édition)
  void _initializeForm() {
    final supplier = Get.arguments as Supplier?;

    if (supplier != null) {
      print('📝 Mode édition - Fournisseur: ${supplier.nom}');
      isEditing.value = true;
      _currentSupplier = supplier;
      _populateForm(supplier);
    } else {
      print('➕ Mode création');
    }
  }

  /// Remplit le formulaire avec les données du fournisseur
  void _populateForm(Supplier supplier) {
    nomController.text = supplier.nom;
    personneContactController.text = supplier.personneContact ?? '';
    telephoneController.text = supplier.telephone ?? '';
    emailController.text = supplier.email ?? '';
    adresseController.text = supplier.adresse ?? '';
  }

  /// Valide le nom du fournisseur
  String? validateNom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom du fournisseur est obligatoire';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Valide le téléphone
  String? validateTelephone(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      // Regex simple pour valider un numéro de téléphone
      final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
      if (!phoneRegex.hasMatch(value.trim())) {
        return 'Format de téléphone invalide';
      }
      if (value.trim().length < 8) {
        return 'Le numéro de téléphone est trop court';
      }
    }
    return null;
  }

  /// Valide l'email
  String? validateEmail(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Format d\'email invalide';
      }
    }
    return null;
  }

  /// Sauvegarde le fournisseur
  Future<void> saveSupplier() async {
    print('💾 Tentative de sauvegarde du fournisseur');

    if (!formKey.currentState!.validate()) {
      print('❌ Validation du formulaire échouée');
      return;
    }

    try {
      isLoading.value = true;
      print('🔄 Début de la sauvegarde...');

      final supplierForm = SupplierForm(
        nom: nomController.text.trim(),
        personneContact: personneContactController.text.trim().isEmpty ? null : personneContactController.text.trim(),
        telephone: telephoneController.text.trim().isEmpty ? null : telephoneController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        adresse: adresseController.text.trim().isEmpty ? null : adresseController.text.trim(),
      );

      print('📋 Données du formulaire: ${supplierForm.toJson()}');

      Supplier savedSupplier;

      if (isEditing.value && _currentSupplier != null) {
        // Modification
        print('✏️ Modification du fournisseur ${_currentSupplier!.id}');
        savedSupplier = await _supplierService.updateSupplier(
          _currentSupplier!.id,
          supplierForm,
        );

        Get.snackbar(
          'Succès',
          'Fournisseur modifié avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        // Création
        print('➕ Création d\'un nouveau fournisseur');
        savedSupplier = await _supplierService.createSupplier(supplierForm);

        Get.snackbar(
          'Succès',
          'Fournisseur créé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      }

      print('✅ Sauvegarde réussie - ID: ${savedSupplier.id}');

      // Notifier le contrôleur principal directement
      try {
        final supplierController = Get.find<SupplierController>();
        supplierController.onSupplierSaved(savedSupplier, isEdit: isEditing.value);
        print('📞 Contrôleur principal notifié avec succès');
      } catch (e) {
        print('⚠️ Impossible de notifier le contrôleur principal: $e');
      }

      // Retourner à la liste avec le fournisseur créé/modifié
      print('🔙 Retour vers la liste avec le fournisseur: ${savedSupplier.nom}');

      // Attendre un peu pour que le snackbar s'affiche
      await Future.delayed(const Duration(milliseconds: 800));

      // Essayer plusieurs méthodes de retour
      try {
        Get.back(result: savedSupplier);
        print('✅ Navigation retour avec Get.back() effectuée');
      } catch (e) {
        print('❌ Erreur lors du retour avec Get.back(): $e');
        try {
          print('🔄 Tentative avec Get.offNamed vers /suppliers');
          Get.offNamed('/suppliers');
        } catch (e2) {
          print('❌ Erreur avec Get.offNamed: $e2');
          print('🔄 Tentative finale avec Get.offAllNamed');
          Get.offAllNamed('/suppliers');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');

      String message = 'Erreur lors de la sauvegarde du fournisseur';

      if (e is ApiException) {
        message = e.message;

        // Gestion spécifique des erreurs de validation
        if (e.statusCode == 409) {
          if (e.message.toLowerCase().contains('email')) {
            message = 'Cette adresse email est déjà utilisée par un autre fournisseur';
          }
        }
      }

      Get.snackbar(
        'Erreur',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Réinitialise le formulaire
  void resetForm() {
    formKey.currentState?.reset();
    nomController.clear();
    personneContactController.clear();
    telephoneController.clear();
    emailController.clear();
    adresseController.clear();
  }
}
