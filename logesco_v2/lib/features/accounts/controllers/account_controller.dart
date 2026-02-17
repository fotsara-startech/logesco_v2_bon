import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/account.dart';
import '../services/account_service.dart';

/// Contrôleur pour la gestion des comptes avec GetX
class AccountController extends GetxController {
  final AccountService _accountService = Get.find<AccountService>();

  // Observables pour les comptes clients
  final RxList<CompteClient> comptesClients = <CompteClient>[].obs;
  final RxBool isLoadingClients = false.obs;
  final RxBool isLoadingMoreClients = false.obs;
  final RxString searchQueryClients = ''.obs;
  final RxString errorMessageClients = ''.obs;
  final RxBool hasErrorClients = false.obs;

  // Observables pour les comptes fournisseurs
  final RxList<CompteFournisseur> comptesFournisseurs = <CompteFournisseur>[].obs;
  final RxBool isLoadingFournisseurs = false.obs;
  final RxBool isLoadingMoreFournisseurs = false.obs;
  final RxString searchQueryFournisseurs = ''.obs;
  final RxString errorMessageFournisseurs = ''.obs;
  final RxBool hasErrorFournisseurs = false.obs;

  // Observables pour les transactions
  final RxList<TransactionCompte> transactions = <TransactionCompte>[].obs;
  final RxBool isLoadingTransactions = false.obs;
  final RxBool isLoadingMoreTransactions = false.obs;

  // Pagination
  final RxInt currentPageClients = 1.obs;
  final RxBool hasMoreDataClients = true.obs;
  final RxInt currentPageFournisseurs = 1.obs;
  final RxBool hasMoreDataFournisseurs = true.obs;
  final RxInt currentPageTransactions = 1.obs;
  final RxBool hasMoreDataTransactions = true.obs;
  final int _pageSize = 20;

  // Filtres
  final Rxn<double> soldeMinFilter = Rxn<double>();
  final Rxn<double> soldeMaxFilter = Rxn<double>();
  final Rxn<bool> enDepassementFilter = Rxn<bool>();

  // Debouncing pour la recherche
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();
    loadComptesClients();
    loadComptesFournisseurs();

    // Écouter les changements de recherche avec debouncing
    ever(searchQueryClients, (_) => _debounceSearchClients());
    ever(searchQueryFournisseurs, (_) => _debounceSearchFournisseurs());
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  /// Charge la liste des comptes clients
  Future<void> loadComptesClients({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPageClients.value = 1;
        hasMoreDataClients.value = true;
        comptesClients.clear();
      }

      if (!hasMoreDataClients.value) return;

      isLoadingClients.value = currentPageClients.value == 1;
      isLoadingMoreClients.value = currentPageClients.value > 1;
      hasErrorClients.value = false;
      errorMessageClients.value = '';

      final newComptes = await _accountService.getComptesClients(
        search: searchQueryClients.value.isEmpty ? null : searchQueryClients.value,
        soldeMin: soldeMinFilter.value,
        soldeMax: soldeMaxFilter.value,
        enDepassement: enDepassementFilter.value,
        page: currentPageClients.value,
        limit: _pageSize,
      );

      if (newComptes.length < _pageSize) {
        hasMoreDataClients.value = false;
      }

      if (currentPageClients.value == 1) {
        comptesClients.assignAll(newComptes);
      } else {
        comptesClients.addAll(newComptes);
      }

      currentPageClients.value++;
    } catch (e) {
      hasErrorClients.value = true;
      if (e is ApiException) {
        errorMessageClients.value = e.message;
      } else {
        errorMessageClients.value = 'Erreur lors du chargement des comptes clients';
      }

      Get.snackbar(
        'Erreur',
        errorMessageClients.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoadingClients.value = false;
      isLoadingMoreClients.value = false;
    }
  }

  /// Charge la liste des comptes fournisseurs
  Future<void> loadComptesFournisseurs({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPageFournisseurs.value = 1;
        hasMoreDataFournisseurs.value = true;
        comptesFournisseurs.clear();
      }

      if (!hasMoreDataFournisseurs.value) return;

      isLoadingFournisseurs.value = currentPageFournisseurs.value == 1;
      isLoadingMoreFournisseurs.value = currentPageFournisseurs.value > 1;
      hasErrorFournisseurs.value = false;
      errorMessageFournisseurs.value = '';

      final newComptes = await _accountService.getComptesFournisseurs(
        search: searchQueryFournisseurs.value.isEmpty ? null : searchQueryFournisseurs.value,
        soldeMin: soldeMinFilter.value,
        soldeMax: soldeMaxFilter.value,
        enDepassement: enDepassementFilter.value,
        page: currentPageFournisseurs.value,
        limit: _pageSize,
      );

      if (newComptes.length < _pageSize) {
        hasMoreDataFournisseurs.value = false;
      }

      if (currentPageFournisseurs.value == 1) {
        comptesFournisseurs.assignAll(newComptes);
      } else {
        comptesFournisseurs.addAll(newComptes);
      }

      currentPageFournisseurs.value++;
    } catch (e) {
      hasErrorFournisseurs.value = true;
      if (e is ApiException) {
        errorMessageFournisseurs.value = e.message;
      } else {
        errorMessageFournisseurs.value = 'Erreur lors du chargement des comptes fournisseurs';
      }

      Get.snackbar(
        'Erreur',
        errorMessageFournisseurs.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoadingFournisseurs.value = false;
      isLoadingMoreFournisseurs.value = false;
    }
  }

  /// Recherche avec debouncing pour les clients
  void _debounceSearchClients() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _resetAndLoadComptesClients();
    });
  }

  /// Recherche avec debouncing pour les fournisseurs
  void _debounceSearchFournisseurs() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _resetAndLoadComptesFournisseurs();
    });
  }

  /// Remet à zéro et recharge les comptes clients
  void _resetAndLoadComptesClients() {
    currentPageClients.value = 1;
    hasMoreDataClients.value = true;
    loadComptesClients(refresh: true);
  }

  /// Remet à zéro et recharge les comptes fournisseurs
  void _resetAndLoadComptesFournisseurs() {
    currentPageFournisseurs.value = 1;
    hasMoreDataFournisseurs.value = true;
    loadComptesFournisseurs(refresh: true);
  }

  /// Met à jour la requête de recherche pour les clients
  void updateSearchQueryClients(String query) {
    searchQueryClients.value = query;
  }

  /// Met à jour la requête de recherche pour les fournisseurs
  void updateSearchQueryFournisseurs(String query) {
    searchQueryFournisseurs.value = query;
  }

  /// Applique les filtres de solde
  void applyFilters({
    double? soldeMin,
    double? soldeMax,
    bool? enDepassement,
  }) {
    soldeMinFilter.value = soldeMin;
    soldeMaxFilter.value = soldeMax;
    enDepassementFilter.value = enDepassement;

    _resetAndLoadComptesClients();
    _resetAndLoadComptesFournisseurs();
  }

  /// Efface tous les filtres
  void clearFilters() {
    searchQueryClients.value = '';
    searchQueryFournisseurs.value = '';
    soldeMinFilter.value = null;
    soldeMaxFilter.value = null;
    enDepassementFilter.value = null;

    _resetAndLoadComptesClients();
    _resetAndLoadComptesFournisseurs();
  }

  /// Rafraîchit les listes
  Future<void> refreshAll() async {
    await Future.wait([
      loadComptesClients(refresh: true),
      loadComptesFournisseurs(refresh: true),
    ]);
  }

  /// Crée une transaction client
  Future<void> createTransactionClient(
    int clientId,
    TransactionForm transactionForm,
  ) async {
    try {
      final compteUpdated = await _accountService.createTransactionClient(
        clientId,
        transactionForm,
      );

      // Mettre à jour le compte dans la liste
      final index = comptesClients.indexWhere((c) => c.clientId == clientId);
      if (index != -1) {
        comptesClients[index] = compteUpdated;
      }

      Get.snackbar(
        'Succès',
        'Transaction client créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      String message = 'Erreur lors de la création de la transaction';
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
      rethrow;
    }
  }

  /// Crée une transaction fournisseur
  Future<void> createTransactionFournisseur(
    int fournisseurId,
    TransactionForm transactionForm,
  ) async {
    try {
      final compteUpdated = await _accountService.createTransactionFournisseur(
        fournisseurId,
        transactionForm,
      );

      // Mettre à jour le compte dans la liste
      final index = comptesFournisseurs.indexWhere((c) => c.fournisseurId == fournisseurId);
      if (index != -1) {
        comptesFournisseurs[index] = compteUpdated;
      }

      Get.snackbar(
        'Succès',
        'Transaction fournisseur créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      String message = 'Erreur lors de la création de la transaction';
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
      rethrow;
    }
  }

  /// Met à jour la limite de crédit d'un client
  Future<void> updateLimiteCreditClient(
    int clientId,
    double nouvelleLimit,
  ) async {
    try {
      final limiteCreditForm = LimiteCreditForm(limiteCredit: nouvelleLimit);
      final compteUpdated = await _accountService.updateLimiteCreditClient(
        clientId,
        limiteCreditForm,
      );

      // Mettre à jour le compte dans la liste
      final index = comptesClients.indexWhere((c) => c.clientId == clientId);
      if (index != -1) {
        comptesClients[index] = compteUpdated;
      }

      Get.snackbar(
        'Succès',
        'Limite de crédit client mise à jour',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      String message = 'Erreur lors de la mise à jour de la limite de crédit';
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
      rethrow;
    }
  }

  /// Met à jour la limite de crédit d'un fournisseur
  Future<void> updateLimiteCreditFournisseur(
    int fournisseurId,
    double nouvelleLimit,
  ) async {
    try {
      final limiteCreditForm = LimiteCreditForm(limiteCredit: nouvelleLimit);
      final compteUpdated = await _accountService.updateLimiteCreditFournisseur(
        fournisseurId,
        limiteCreditForm,
      );

      // Mettre à jour le compte dans la liste
      final index = comptesFournisseurs.indexWhere((c) => c.fournisseurId == fournisseurId);
      if (index != -1) {
        comptesFournisseurs[index] = compteUpdated;
      }

      Get.snackbar(
        'Succès',
        'Limite de crédit fournisseur mise à jour',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      String message = 'Erreur lors de la mise à jour de la limite de crédit';
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
      rethrow;
    }
  }

  /// Charge l'historique des transactions pour un compte
  Future<void> loadTransactions({
    required bool isClient,
    required int accountId,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        currentPageTransactions.value = 1;
        hasMoreDataTransactions.value = true;
        transactions.clear();
      }

      if (!hasMoreDataTransactions.value) return;

      isLoadingTransactions.value = currentPageTransactions.value == 1;
      isLoadingMoreTransactions.value = currentPageTransactions.value > 1;

      final newTransactions = isClient
          ? await _accountService.getTransactionsClient(
              accountId,
              page: currentPageTransactions.value,
              limit: _pageSize,
            )
          : await _accountService.getTransactionsFournisseur(
              accountId,
              page: currentPageTransactions.value,
              limit: _pageSize,
            );

      if (newTransactions.length < _pageSize) {
        hasMoreDataTransactions.value = false;
      }

      if (currentPageTransactions.value == 1) {
        transactions.assignAll(newTransactions);
      } else {
        transactions.addAll(newTransactions);
      }

      currentPageTransactions.value++;
    } catch (e) {
      String message = 'Erreur lors du chargement des transactions';
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
      isLoadingTransactions.value = false;
      isLoadingMoreTransactions.value = false;
    }
  }

  /// Navigue vers les détails d'un compte client
  void goToCompteClientDetail(CompteClient compte) {
    Get.toNamed('/accounts/clients/${compte.clientId}', arguments: compte);
  }

  /// Navigue vers les détails d'un compte fournisseur
  void goToCompteFournisseurDetail(CompteFournisseur compte) {
    Get.toNamed('/accounts/suppliers/${compte.fournisseurId}', arguments: compte);
  }

  /// Calcule le nombre de comptes en dépassement
  int get nombreComptesClientsEnDepassement {
    return comptesClients.where((c) => c.estEnDepassement).length;
  }

  int get nombreComptesFournisseursEnDepassement {
    return comptesFournisseurs.where((c) => c.estEnDepassement).length;
  }

  /// Calcule le total des dettes clients
  double get totalDettesClients {
    return comptesClients.fold(0.0, (sum, compte) => sum + compte.soldeActuel);
  }

  /// Calcule le total des dettes fournisseurs
  double get totalDettesFournisseurs {
    return comptesFournisseurs.fold(0.0, (sum, compte) => sum + compte.soldeActuel);
  }
}
