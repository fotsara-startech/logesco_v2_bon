import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/customer.dart';
import '../models/customer_transaction.dart';
import '../services/customer_service.dart';
import '../services/api_customer_service.dart';

/// Contrôleur pour la gestion des clients avec GetX
class CustomerController extends GetxController {
  final CustomerService _customerService = Get.find<CustomerService>();

  // Observables pour l'état de l'interface
  final RxList<Customer> customers = <Customer>[].obs;
  final RxList<CustomerTransaction> customerTransactions = <CustomerTransaction>[].obs;
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
    loadCustomers();

    // Écouter les changements de recherche avec debouncing
    ever(searchQuery, (_) => _debounceSearch());
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// Charge la liste des clients
  Future<void> loadCustomers({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        hasMoreData.value = true;
        customers.clear();
      }

      if (!hasMoreData.value) return;

      isLoading.value = currentPage.value == 1;
      isLoadingMore.value = currentPage.value > 1;
      hasError.value = false;
      errorMessage.value = '';

      final newCustomers = await _customerService.getCustomers(
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        page: currentPage.value,
        limit: _pageSize,
      );

      if (newCustomers.length < _pageSize) {
        hasMoreData.value = false;
      }

      if (currentPage.value == 1) {
        customers.assignAll(newCustomers);
      } else {
        customers.addAll(newCustomers);
      }

      currentPage.value++;
    } catch (e) {
      hasError.value = true;
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Erreur lors du chargement des clients';
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
      _resetAndLoadCustomers();
    });
  }

  /// Remet à zéro et recharge les clients
  void _resetAndLoadCustomers() {
    currentPage.value = 1;
    hasMoreData.value = true;
    loadCustomers(refresh: true);
  }

  /// Met à jour la requête de recherche
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Efface la recherche
  void clearSearch() {
    searchQuery.value = '';
  }

  /// Rafraîchit la liste des clients
  Future<void> refreshCustomers() async {
    await loadCustomers(refresh: true);
  }

  /// Charge plus de clients (pagination)
  Future<void> loadMoreCustomers() async {
    if (!isLoadingMore.value && hasMoreData.value) {
      await loadCustomers();
    }
  }

  /// Navigue vers la création d'un client
  Future<void> goToCreateCustomer() async {
    print('🔄 Navigation vers création client');
    print('  - Route: /customers/create');

    // Sauvegarder l'état actuel pour comparaison
    final initialCount = customers.length;
    print('📊 Nombre de clients avant navigation: $initialCount');

    try {
      final result = await Get.toNamed('/customers/create');
      print('🔙 Retour de la navigation, résultat: $result');
      print('📊 Type du résultat: ${result.runtimeType}');

      // Toujours rafraîchir la liste après retour du formulaire
      print('🔄 Rafraîchissement de la liste des clients...');
      await refreshCustomers();

      final finalCount = customers.length;
      print('📊 Nombre de clients après rafraîchissement: $finalCount');

      // Vérifier si un nouveau client a été ajouté
      if (finalCount > initialCount) {
        print('✅ Nouveau client détecté dans la liste');
        Get.snackbar(
          'Succès',
          'Client ajouté avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );
      } else if (result != null && result is Customer) {
        print('🆕 Client créé selon le résultat: ${result.nomComplet}');
        // Forcer l'ajout si pas détecté dans le rafraîchissement
        customers.insert(0, result);
        Get.snackbar(
          'Succès',
          'Client "${result.nomComplet}" ajouté à la liste',
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

  /// Navigue vers l'édition d'un client
  Future<void> goToEditCustomer(Customer customer) async {
    print('🔄 Navigation vers édition client ${customer.id}');

    try {
      final result = await Get.toNamed('/customers/${customer.id}/edit', arguments: customer);

      // Si le client a été modifié, mettre à jour la liste
      if (result != null && result is Customer) {
        print('✏️ Client modifié: ${result.nomComplet}');

        // Trouver et remplacer le client dans la liste
        final index = customers.indexWhere((c) => c.id == result.id);
        if (index != -1) {
          customers[index] = result;
          print('✅ Client mis à jour dans la liste');
        } else {
          print('⚠️ Client non trouvé dans la liste, ajout en tête');
          customers.insert(0, result);
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

  /// Navigue vers les détails d'un client
  void goToCustomerDetail(Customer customer) {
    Get.toNamed('/customers/${customer.id}', arguments: customer);
  }

  /// Supprime un client avec confirmation
  Future<void> deleteCustomer(Customer customer) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer le client "${customer.nomComplet}" ?'),
            const SizedBox(height: 8),
            Text(
              'Note: La suppression échouera si le client a des ventes associées.',
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
        final success = await _customerService.deleteCustomer(customer.id);

        if (success) {
          customers.remove(customer);
          Get.snackbar(
            'Succès',
            'Client supprimé avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
          );
        } else {
          throw Exception('Échec de la suppression');
        }
      } catch (e) {
        String message = 'Erreur lors de la suppression du client';
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

  /// Récupère un client par ID
  Future<Customer?> getCustomerById(int id) async {
    try {
      return await _customerService.getCustomerById(id);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de récupérer les détails du client',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return null;
    }
  }

  /// Méthode appelée directement par le formulaire après création/modification
  void onCustomerSaved(Customer customer, {bool isEdit = false}) {
    print('📞 onCustomerSaved appelée pour: ${customer.nomComplet}');

    if (isEdit) {
      // Mise à jour d'un client existant
      final index = customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        customers[index] = customer;
        print('✅ Client mis à jour dans la liste à l\'index $index');
      } else {
        customers.insert(0, customer);
        print('⚠️ Client non trouvé pour mise à jour, ajouté en tête');
      }
    } else {
      // Nouveau client
      customers.insert(0, customer);
      print('✅ Nouveau client ajouté en tête de liste');
    }

    // Forcer la mise à jour de l'interface
    customers.refresh();
  }

  /// Charge l'historique des transactions d'un client
  Future<void> loadCustomerTransactions(int customerId) async {
    try {
      print('📥 Chargement des transactions pour le client $customerId...');
      isLoading.value = true;
      hasError.value = false;

      final transactions = await _customerService.getCustomerTransactions(customerId);
      print('✅ ${transactions.length} transaction(s) récupérée(s)');
      customerTransactions.assignAll(transactions);
      print('📊 customerTransactions.length = ${customerTransactions.length}');
    } catch (e) {
      print('❌ Erreur chargement transactions: $e');
      hasError.value = true;
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Erreur lors du chargement des transactions';
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
    }
  }

  /// Enregistre un paiement de dette pour un client
  Future<bool> payCustomerDebt(int customerId, double montant, {String? description}) async {
    try {
      print('💰 Paiement dette client $customerId: $montant FCFA');
      isLoading.value = true;

      // Vérifier que le service est ApiCustomerService
      if (_customerService is! ApiCustomerService) {
        throw Exception('Service non supporté pour le paiement');
      }

      final apiService = _customerService as ApiCustomerService;
      final success = await apiService.payCustomerDebt(customerId, montant, description: description);

      if (success) {
        print('✅ Paiement enregistré avec succès');
        Get.snackbar(
          'Succès',
          'Paiement de ${montant.toStringAsFixed(0)} FCFA enregistré',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        return true;
      } else {
        throw Exception('Échec de l\'enregistrement du paiement');
      }
    } catch (e) {
      print('❌ Erreur paiement dette: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'enregistrement du paiement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Enregistre un paiement de dette pour une vente spécifique
  Future<bool> payCustomerDebtForSale(int customerId, double montant, int venteId, {String? description}) async {
    try {
      print('💰 [Controller] Paiement dette client $customerId pour vente $venteId: $montant FCFA');
      print('  - Description: $description');
      isLoading.value = true;

      // Vérifier que le service est ApiCustomerService
      if (_customerService is! ApiCustomerService) {
        print('❌ [Controller] Service n\'est pas ApiCustomerService');
        throw Exception('Service non supporté pour le paiement');
      }

      print('✅ [Controller] Service est ApiCustomerService, appel du service...');
      final apiService = _customerService as ApiCustomerService;
      final success = await apiService.payCustomerDebtForSale(
        customerId,
        montant,
        venteId,
        description: description,
      );

      print('📊 [Controller] Résultat du service: $success');

      if (success) {
        print('✅ [Controller] Paiement pour vente enregistré avec succès');
        Get.snackbar(
          'Succès',
          'Paiement de ${montant.toStringAsFixed(0)} FCFA enregistré',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        return true;
      } else {
        print('❌ [Controller] Service a retourné false');
        throw Exception('Échec de l\'enregistrement du paiement');
      }
    } catch (e) {
      print('❌ [Controller] Erreur paiement dette pour vente: $e');
      print('  - Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'enregistrement du paiement: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      print('🔄 [Controller] isLoading = false');
      isLoading.value = false;
    }
  }

  /// Récupère les données du relevé de compte
  Future<Map<String, dynamic>?> getCustomerStatement(int customerId) async {
    try {
      print('📄 Récupération relevé de compte client $customerId');

      // Vérifier que le service est ApiCustomerService
      if (_customerService is! ApiCustomerService) {
        throw Exception('Service non supporté pour le relevé');
      }

      final apiService = _customerService as ApiCustomerService;
      final statementData = await apiService.getCustomerStatement(customerId);

      if (statementData != null) {
        print('✅ Relevé de compte récupéré');
        return statementData;
      } else {
        throw Exception('Aucune donnée de relevé reçue');
      }
    } catch (e) {
      print('❌ Erreur récupération relevé: $e');
      throw Exception('Erreur lors de la récupération du relevé: $e');
    }
  }
}
