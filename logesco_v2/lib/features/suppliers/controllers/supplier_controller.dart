import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';

/// Contrôleur pour la gestion des fournisseurs avec GetX
class SupplierController extends GetxController {
  final SupplierService _supplierService = Get.find<SupplierService>();

  // Observables pour l'état de l'interface
  final RxList<Supplier> suppliers = <Supplier>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreData = true.obs;
  final int _pageSize = 20;

  // Debouncing pour la recherche
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();
    loadSuppliers();

    // Écouter les changements de recherche avec debouncing
    ever(searchQuery, (_) => _debounceSearch());
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// Charge la liste des fournisseurs
  Future<void> loadSuppliers({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        hasMoreData.value = true;
        suppliers.clear();
      }

      if (!hasMoreData.value) return;

      isLoading.value = currentPage.value == 1;
      isLoadingMore.value = currentPage.value > 1;
      hasError.value = false;
      errorMessage.value = '';

      final newSuppliers = await _supplierService.getSuppliers(
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        page: currentPage.value,
        limit: _pageSize,
      );

      if (newSuppliers.length < _pageSize) {
        hasMoreData.value = false;
      }

      if (currentPage.value == 1) {
        suppliers.assignAll(newSuppliers);
      } else {
        suppliers.addAll(newSuppliers);
      }

      currentPage.value++;
    } catch (e) {
      hasError.value = true;
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Erreur lors du chargement des fournisseurs';
      }

      Get.snackbar(
        'Erreur',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Recherche avec debouncing
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _resetAndLoadSuppliers();
    });
  }

  /// Remet à zéro et recharge les fournisseurs
  void _resetAndLoadSuppliers() {
    currentPage.value = 1;
    hasMoreData.value = true;
    loadSuppliers(refresh: true);
  }

  /// Met à jour la requête de recherche
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Efface la recherche
  void clearSearch() {
    searchQuery.value = '';
  }

  /// Rafraîchit la liste des fournisseurs
  Future<void> refreshSuppliers() async {
    await loadSuppliers(refresh: true);
  }

  /// Charge plus de fournisseurs (pagination)
  Future<void> loadMoreSuppliers() async {
    if (!isLoadingMore.value && hasMoreData.value) {
      await loadSuppliers();
    }
  }

  /// Navigue vers la création d'un fournisseur
  Future<void> goToCreateSupplier() async {
    print('🔄 Navigation vers création fournisseur');
    print('  - Route: /suppliers/create');

    try {
      final result = await Get.toNamed('/suppliers/create');
      print('🔙 Retour de la navigation, résultat: $result');

      // Toujours rafraîchir la liste après retour du formulaire
      print('🔄 Rafraîchissement de la liste des fournisseurs...');
      await refreshSuppliers();

      // Si un fournisseur a été créé, afficher un message
      if (result != null && result is Supplier) {
        print('🆕 Nouveau fournisseur créé: ${result.nom}');
        Get.snackbar(
          'Succès',
          'Fournisseur "${result.nom}" ajouté à la liste',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ Erreur navigation: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir le formulaire de création',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Navigue vers l'édition d'un fournisseur
  Future<void> goToEditSupplier(Supplier supplier) async {
    print('🔄 Navigation vers édition fournisseur ${supplier.id}');

    try {
      final result = await Get.toNamed('/suppliers/${supplier.id}/edit', arguments: supplier);

      // Si le fournisseur a été modifié, mettre à jour la liste
      if (result != null && result is Supplier) {
        print('✏️ Fournisseur modifié: ${result.nom}');

        // Trouver et remplacer le fournisseur dans la liste
        final index = suppliers.indexWhere((s) => s.id == result.id);
        if (index != -1) {
          suppliers[index] = result;
          print('✅ Fournisseur mis à jour dans la liste');
        } else {
          print('⚠️ Fournisseur non trouvé dans la liste, ajout en tête');
          suppliers.insert(0, result);
        }
      }
    } catch (e) {
      print('❌ Erreur navigation édition: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir le formulaire d\'édition',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Navigue vers les détails d'un fournisseur
  void goToSupplierDetail(Supplier supplier) {
    print('🔄 Navigation vers détails fournisseur ${supplier.id}');
    Get.toNamed('/suppliers/${supplier.id}', arguments: supplier);
  }

  /// Supprime un fournisseur avec confirmation
  Future<void> deleteSupplier(Supplier supplier) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer le fournisseur "${supplier.nom}" ?'),
            const SizedBox(height: 8),
            Text(
              'Note: La suppression échouera si le fournisseur a des commandes associées.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
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
        print('🔄 Début suppression fournisseur ID: ${supplier.id}');

        final success = await _supplierService.deleteSupplier(supplier.id);
        print('📋 Résultat suppression: $success');

        if (success) {
          // Supprimer de la liste locale
          suppliers.removeWhere((s) => s.id == supplier.id);
          print('✅ Fournisseur retiré de la liste locale');

          Get.snackbar(
            'Succès',
            'Fournisseur "${supplier.nom}" supprimé avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            duration: const Duration(seconds: 3),
          );
        } else {
          print('❌ Suppression échouée - service retourné false');
          Get.snackbar(
            'Erreur',
            'La suppression du fournisseur a échoué. Veuillez réessayer.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            duration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        print('❌ Exception lors de la suppression: $e');

        String message = 'Erreur lors de la suppression du fournisseur';
        if (e is ApiException) {
          switch (e.statusCode) {
            case 404:
              message = 'Fournisseur non trouvé';
              break;
            case 403:
              message = 'Vous n\'avez pas les droits pour supprimer ce fournisseur';
              break;
            case 409:
              message = 'Impossible de supprimer: le fournisseur a des commandes associées';
              break;
            case 500:
              message = 'Erreur serveur. Veuillez réessayer plus tard.';
              break;
            default:
              message = e.message.isNotEmpty ? e.message : message;
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
  }

  /// Récupère un fournisseur par ID
  Future<Supplier?> getSupplierById(int id) async {
    try {
      return await _supplierService.getSupplierById(id);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de récupérer les détails du fournisseur',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return null;
    }
  }

  /// Méthode appelée directement par le formulaire après création/modification
  void onSupplierSaved(Supplier supplier, {bool isEdit = false}) {
    print('📞 onSupplierSaved appelée pour: ${supplier.nom}');

    if (isEdit) {
      // Mise à jour d'un fournisseur existant
      final index = suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        suppliers[index] = supplier;
        print('✅ Fournisseur mis à jour dans la liste à l\'index $index');
      } else {
        suppliers.insert(0, supplier);
        print('⚠️ Fournisseur non trouvé pour mise à jour, ajouté en tête');
      }
    } else {
      // Nouveau fournisseur
      suppliers.insert(0, supplier);
      print('✅ Nouveau fournisseur ajouté en tête de liste');
    }

    // Forcer la mise à jour de l'interface
    suppliers.refresh();
  }
}
