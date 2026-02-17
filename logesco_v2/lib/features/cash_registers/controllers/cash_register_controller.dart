import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/cash_register_model.dart';
import '../services/cash_register_service.dart';
import '../services/mock_cash_register_service.dart';
import '../../../core/config/api_config.dart';

/// Contrôleur pour la gestion des caisses
class CashRegisterController extends GetxController {
  // État des données
  final RxList<CashRegister> cashRegisters = <CashRegister>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Caisse sélectionnée pour modification
  final Rx<CashRegister?> selectedCashRegister = Rx<CashRegister?>(null);

  @override
  void onInit() {
    super.onInit();
    loadCashRegisters();
  }

  /// Charger toutes les caisses
  Future<void> loadCashRegisters() async {
    try {
      isLoading.value = true;
      final cashRegisterList = ApiConfig.useTestData ? await MockCashRegisterService.getAllCashRegisters() : await CashRegisterService.getAllCashRegisters();
      cashRegisters.assignAll(cashRegisterList);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les caisses: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Caisses filtrées selon la recherche
  List<CashRegister> get filteredCashRegisters {
    if (searchQuery.value.isEmpty) {
      return cashRegisters;
    }
    return cashRegisters.where((cashRegister) {
      return cashRegister.nom.toLowerCase().contains(searchQuery.value.toLowerCase()) || cashRegister.description.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  /// Créer une nouvelle caisse
  Future<bool> createCashRegister(CashRegister cashRegister) async {
    try {
      isLoading.value = true;
      final newCashRegister = ApiConfig.useTestData ? await MockCashRegisterService.createCashRegister(cashRegister) : await CashRegisterService.createCashRegister(cashRegister);
      cashRegisters.add(newCashRegister);

      Get.snackbar(
        'Succès',
        'Caisse créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer la caisse: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mettre à jour une caisse
  Future<bool> updateCashRegister(CashRegister cashRegister) async {
    try {
      isLoading.value = true;
      final updatedCashRegister =
          ApiConfig.useTestData ? await MockCashRegisterService.updateCashRegister(cashRegister.id!, cashRegister) : await CashRegisterService.updateCashRegister(cashRegister.id!, cashRegister);

      final index = cashRegisters.indexWhere((c) => c.id == cashRegister.id);
      if (index != -1) {
        cashRegisters[index] = updatedCashRegister;
      }

      Get.snackbar(
        'Succès',
        'Caisse mise à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour la caisse: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprimer une caisse
  Future<bool> deleteCashRegister(int cashRegisterId) async {
    try {
      ApiConfig.useTestData ? await MockCashRegisterService.deleteCashRegister(cashRegisterId) : await CashRegisterService.deleteCashRegister(cashRegisterId);
      cashRegisters.removeWhere((cashRegister) => cashRegister.id == cashRegisterId);

      Get.snackbar(
        'Succès',
        'Caisse supprimée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la caisse: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Ouvrir une caisse
  Future<bool> openCashRegister(int cashRegisterId, double soldeInitial) async {
    try {
      final updatedCashRegister = ApiConfig.useTestData
          ? await MockCashRegisterService.openCashRegister(cashRegisterId, soldeInitial, 1, 'Utilisateur') // TODO: Récupérer l'utilisateur connecté
          : await CashRegisterService.openCashRegister(cashRegisterId, soldeInitial);

      final index = cashRegisters.indexWhere((c) => c.id == cashRegisterId);
      if (index != -1) {
        cashRegisters[index] = updatedCashRegister;
      }

      Get.snackbar(
        'Succès',
        'Caisse ouverte avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir la caisse: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Fermer une caisse
  Future<bool> closeCashRegister(int cashRegisterId) async {
    try {
      // Récupérer le solde actuel de la caisse pour la fermeture
      final currentCashRegister = cashRegisters.firstWhere((c) => c.id == cashRegisterId);
      final finalAmount = currentCashRegister.soldeActuel;

      final updatedCashRegister = ApiConfig.useTestData
          ? await MockCashRegisterService.closeCashRegister(cashRegisterId, finalAmount, 1, 'Utilisateur') // TODO: Récupérer l'utilisateur connecté
          : await CashRegisterService.closeCashRegister(cashRegisterId);

      final index = cashRegisters.indexWhere((c) => c.id == cashRegisterId);
      if (index != -1) {
        cashRegisters[index] = updatedCashRegister;
      }

      Get.snackbar(
        'Succès',
        'Caisse fermée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de fermer la caisse: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return false;
    }
  }

  /// Sélectionner une caisse pour modification
  void selectCashRegister(CashRegister? cashRegister) {
    selectedCashRegister.value = cashRegister;
  }

  /// Mettre à jour la requête de recherche
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Confirmer la suppression d'une caisse
  void confirmDeleteCashRegister(CashRegister cashRegister) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la caisse "${cashRegister.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              deleteCashRegister(cashRegister.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
