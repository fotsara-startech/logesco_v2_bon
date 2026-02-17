import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'customer_controller.dart';

/// Contrôleur pour le formulaire de création/modification des clients
class CustomerFormController extends GetxController {
  final CustomerService _customerService = Get.find<CustomerService>();

  // Clé du formulaire
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Contrôleurs des champs
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();

  // État
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;

  // Client en cours d'édition
  Customer? _currentCustomer;

  @override
  void onInit() {
    super.onInit();
    print('🔧 Initialisation CustomerFormController');
    _initializeForm();
  }

  @override
  void onClose() {
    nomController.dispose();
    prenomController.dispose();
    telephoneController.dispose();
    emailController.dispose();
    adresseController.dispose();
    super.onClose();
  }

  /// Initialise le formulaire selon le mode (création/édition)
  void _initializeForm() {
    final customer = Get.arguments as Customer?;

    if (customer != null) {
      print('📝 Mode édition - Client: ${customer.nomComplet}');
      isEditing.value = true;
      _currentCustomer = customer;
      _populateForm(customer);
    } else {
      print('➕ Mode création');
    }
  }

  /// Remplit le formulaire avec les données du client
  void _populateForm(Customer customer) {
    nomController.text = customer.nom;
    prenomController.text = customer.prenom ?? '';
    telephoneController.text = customer.telephone ?? '';
    emailController.text = customer.email ?? '';
    adresseController.text = customer.adresse ?? '';
  }

  /// Valide le nom du client
  String? validateNom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom du client est obligatoire';
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

  /// Sauvegarde le client
  Future<void> saveCustomer() async {
    print('💾 Tentative de sauvegarde du client');

    if (!formKey.currentState!.validate()) {
      print('❌ Validation du formulaire échouée');
      return;
    }

    try {
      isLoading.value = true;
      print('🔄 Début de la sauvegarde...');

      final customerForm = CustomerForm(
        nom: nomController.text.trim(),
        prenom: prenomController.text.trim().isEmpty ? null : prenomController.text.trim(),
        telephone: telephoneController.text.trim().isEmpty ? null : telephoneController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        adresse: adresseController.text.trim().isEmpty ? null : adresseController.text.trim(),
      );

      print('📋 Données du formulaire: ${customerForm.toJson()}');

      Customer savedCustomer;

      if (isEditing.value && _currentCustomer != null) {
        // Modification
        print('✏️ Modification du client ${_currentCustomer!.id}');
        savedCustomer = await _customerService.updateCustomer(
          _currentCustomer!.id,
          customerForm,
        );

        Get.snackbar(
          'Succès',
          'Client modifié avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        // Création
        print('➕ Création d\'un nouveau client');
        savedCustomer = await _customerService.createCustomer(customerForm);

        Get.snackbar(
          'Succès',
          'Client créé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      }

      print('✅ Sauvegarde réussie - ID: ${savedCustomer.id}');

      // Notifier le contrôleur principal directement
      try {
        final customerController = Get.find<CustomerController>();
        customerController.onCustomerSaved(savedCustomer, isEdit: isEditing.value);
        print('📞 Contrôleur principal notifié avec succès');
      } catch (e) {
        print('⚠️ Impossible de notifier le contrôleur principal: $e');
      }

      // Retourner à la liste avec le client créé/modifié
      print('🔙 Retour vers la liste avec le client: ${savedCustomer.nomComplet}');

      // Attendre un peu pour que le snackbar s'affiche
      await Future.delayed(const Duration(milliseconds: 500));

      // Utiliser Navigator.pop pour éviter les problèmes avec Get.back()
      try {
        if (Get.context != null) {
          Navigator.of(Get.context!).pop(savedCustomer);
          print('✅ Navigation retour avec Navigator.pop() effectuée');
        } else {
          print('⚠️ Pas de contexte, utilisation de Get.offNamed');
          Get.offNamed('/customers');
        }
      } catch (e) {
        print('❌ Erreur lors du retour: $e');
        try {
          print('🔄 Tentative avec Get.offNamed vers /customers');
          Get.offNamed('/customers');
        } catch (e2) {
          print('❌ Erreur avec Get.offNamed: $e2');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
      print('❌ Type d\'erreur: ${e.runtimeType}');

      String message = 'Erreur lors de la sauvegarde du client';

      if (e is ApiException) {
        message = e.message;
        print('📋 ApiException - Status: ${e.statusCode}, Message: ${e.message}');

        // Gestion spécifique des erreurs de validation
        if (e.statusCode == 409) {
          if (e.message.toLowerCase().contains('email')) {
            message = 'Cette adresse email est déjà utilisée par un autre client';
          }
        }
      } else if (e is TypeError) {
        message = 'Erreur de format des données reçues du serveur';
        print('📋 TypeError détails: $e');
      } else {
        print('📋 Erreur générique: $e');
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
    prenomController.clear();
    telephoneController.clear();
    emailController.clear();
    adresseController.clear();
  }
}
