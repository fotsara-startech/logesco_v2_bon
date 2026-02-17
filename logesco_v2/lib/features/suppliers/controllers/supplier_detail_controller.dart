import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/exceptions.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';
import 'supplier_controller.dart';

/// Contrôleur pour la vue de détail d'un fournisseur
class SupplierDetailController extends GetxController {
  final SupplierService _supplierService = Get.find<SupplierService>();

  // État
  final Rx<Supplier?> supplier = Rx<Supplier?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // ID du fournisseur
  late int supplierId;

  @override
  void onInit() {
    super.onInit();
    _initializeSupplier();
  }

  /// Initialise le fournisseur depuis les arguments ou les paramètres
  void _initializeSupplier() {
    // Essayer de récupérer depuis les arguments d'abord
    final supplierArg = Get.arguments as Supplier?;
    if (supplierArg != null) {
      supplier.value = supplierArg;
      supplierId = supplierArg.id;
      return;
    }

    // Sinon, récupérer l'ID depuis les paramètres de route
    final idParam = Get.parameters['id'];
    if (idParam != null) {
      supplierId = int.tryParse(idParam) ?? 0;
      if (supplierId > 0) {
        loadSupplier();
      } else {
        hasError.value = true;
        errorMessage.value = 'ID de fournisseur invalide';
      }
    } else {
      hasError.value = true;
      errorMessage.value = 'Aucun fournisseur spécifié';
    }
  }

  /// Charge les détails du fournisseur
  Future<void> loadSupplier() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final loadedSupplier = await _supplierService.getSupplierById(supplierId);

      if (loadedSupplier != null) {
        supplier.value = loadedSupplier;
      } else {
        hasError.value = true;
        errorMessage.value = 'Fournisseur non trouvé';
      }
    } catch (e) {
      hasError.value = true;
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Erreur lors du chargement du fournisseur';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigue vers l'édition du fournisseur
  void editSupplier() {
    if (supplier.value != null) {
      Get.toNamed('/suppliers/${supplier.value!.id}/edit', arguments: supplier.value)?.then((result) {
        // Si un fournisseur modifié est retourné, mettre à jour
        if (result is Supplier) {
          supplier.value = result;

          // Mettre à jour aussi dans la liste si le contrôleur existe
          try {
            final listController = Get.find<SupplierController>();
            final index = listController.suppliers.indexWhere((s) => s.id == result.id);
            if (index != -1) {
              listController.suppliers[index] = result;
            }
          } catch (e) {
            // Le contrôleur de liste n'existe pas, pas grave
          }
        }
      });
    }
  }

  /// Supprime le fournisseur
  Future<void> deleteSupplier() async {
    if (supplier.value == null) return;

    // Vérifier d'abord si le fournisseur peut être supprimé
    try {
      final canDelete = await _supplierService.canDeleteSupplier(supplier.value!.id);
      if (!canDelete) {
        Get.snackbar(
          'Suppression impossible',
          'Ce fournisseur ne peut pas être supprimé car il a des commandes associées.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de vérifier les dépendances du fournisseur',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le fournisseur "${supplier.value!.nom}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        isLoading.value = true;
        final success = await _supplierService.deleteSupplier(supplier.value!.id);

        if (success) {
          // Supprimer aussi de la liste si le contrôleur existe
          try {
            final listController = Get.find<SupplierController>();
            listController.suppliers.removeWhere((s) => s.id == supplier.value!.id);
          } catch (e) {
            // Le contrôleur de liste n'existe pas, pas grave
          }

          Get.snackbar(
            'Succès',
            'Fournisseur supprimé avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );

          // Retourner à la liste
          Get.back();
        } else {
          throw Exception('Échec de la suppression');
        }
      } catch (e) {
        String message = 'Erreur lors de la suppression du fournisseur';
        if (e is ApiException) {
          message = e.message;
        }

        Get.snackbar(
          'Erreur',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  /// Appelle le fournisseur
  Future<void> callSupplier(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir l\'application téléphone',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Envoie un email au fournisseur
  Future<void> emailSupplier(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir l\'application email',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Affiche l'adresse sur la carte
  Future<void> showAddressOnMap(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir l\'application cartes',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Affiche les commandes du fournisseur
  void viewOrders() {
    Get.snackbar(
      'Fonctionnalité',
      'Affichage des commandes à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
