import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';
import '../services/supplier_excel_service.dart';

/// Contrôleur pour la gestion des fournisseurs avec GetX
class SupplierController extends GetxController {
  final SupplierService _supplierService = Get.find<SupplierService>();
  final SupplierExcelService _excelService = SupplierExcelService();

  // Observables pour l'état de l'interface
  final RxList<Supplier> suppliers = <Supplier>[].obs;
  final RxList<SupplierTransaction> supplierTransactions = <SupplierTransaction>[].obs;
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

  /// Charge les transactions d'un fournisseur
  Future<void> loadSupplierTransactions(int supplierId) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      print('🔄 Chargement des transactions du fournisseur $supplierId...');

      final transactions = await _supplierService.getSupplierTransactions(supplierId);
      supplierTransactions.assignAll(transactions);

      print('✅ ${transactions.length} transaction(s) chargée(s)');
    } catch (e) {
      hasError.value = true;
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'Erreur lors du chargement des transactions';
      }

      print('❌ Erreur chargement transactions: $e');

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

  /// Paie un fournisseur (enregistre un paiement)
  Future<bool> paySupplier(
    int supplierId,
    double montant, {
    String? description,
  }) async {
    try {
      print('💰 Paiement fournisseur $supplierId: $montant FCFA');

      final success = await _supplierService.paySupplier(
        supplierId,
        montant,
        description: description,
      );

      if (success) {
        Get.snackbar(
          'Succès',
          'Paiement de ${montant.toStringAsFixed(0)} FCFA enregistré',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        return true;
      } else {
        Get.snackbar(
          'Erreur',
          'Le paiement a échoué',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('❌ Erreur paiement fournisseur: $e');

      String message = 'Erreur lors du paiement';
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
      return false;
    }
  }

  /// Paie une commande spécifique d'un fournisseur
  Future<bool> paySupplierForProcurement(
    int supplierId,
    double montant,
    int procurementId, {
    String? description,
    bool createFinancialMovement = false,
  }) async {
    try {
      print('💰 Paiement commande $procurementId du fournisseur $supplierId: $montant FCFA');
      print('  - Créer mouvement financier: $createFinancialMovement');

      final success = await _supplierService.paySupplierForProcurement(
        supplierId,
        montant,
        procurementId,
        description: description,
        createFinancialMovement: createFinancialMovement,
      );

      if (success) {
        Get.snackbar(
          'Succès',
          'Paiement de ${montant.toStringAsFixed(0)} FCFA enregistré pour la commande',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        return true;
      } else {
        Get.snackbar(
          'Erreur',
          'Le paiement a échoué',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
        return false;
      }
    } catch (e) {
      print('❌ Erreur paiement commande: $e');

      String message = 'Erreur lors du paiement';
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
      return false;
    }
  }

  /// Récupère les données du relevé de compte fournisseur
  Future<Map<String, dynamic>?> getSupplierStatement(int supplierId) async {
    try {
      print('📄 Récupération relevé fournisseur $supplierId');
      return await _supplierService.getSupplierStatement(supplierId);
    } catch (e) {
      print('❌ Erreur récupération relevé: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de récupérer le relevé de compte',
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

  /// Exporte tous les fournisseurs vers Excel
  Future<void> exportToExcel() async {
    try {
      Get.snackbar(
        'Export en cours',
        'Récupération des fournisseurs...',
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(days: 1), // Durée très longue pour éviter la fermeture auto
      );

      // Récupérer tous les fournisseurs par pagination
      List<Supplier> allSuppliers = [];
      int currentPage = 1;
      const int pageSize = 100; // Limite maximale acceptée par l'API
      bool hasMore = true;

      while (hasMore) {
        final pageSuppliers = await _supplierService.getSuppliers(
          page: currentPage,
          limit: pageSize,
        );

        if (pageSuppliers.isEmpty) {
          hasMore = false;
        } else {
          allSuppliers.addAll(pageSuppliers);

          // Si on a reçu moins que la limite, c'est la dernière page
          if (pageSuppliers.length < pageSize) {
            hasMore = false;
          } else {
            currentPage++;
          }
        }
      }

      if (allSuppliers.isEmpty) {
        // Fermer le snackbar de progression
        try {
          if (Get.isSnackbarOpen == true) {
            Get.closeCurrentSnackbar();
          }
        } catch (e) {
          // Ignorer l'erreur de fermeture
        }

        Get.snackbar(
          'Aucune donnée',
          'Aucun fournisseur à exporter',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      // Fermer le snackbar de progression
      try {
        if (Get.isSnackbarOpen == true) {
          Get.closeCurrentSnackbar();
        }
      } catch (e) {
        // Ignorer l'erreur de fermeture
      }

      // Afficher la progression de génération
      Get.snackbar(
        'Export en cours',
        'Génération du fichier Excel...',
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(days: 1), // Durée très longue pour éviter la fermeture auto
      );

      final filePath = await _excelService.exportSuppliersToExcel(allSuppliers);

      // Fermer le snackbar de progression avec un délai
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        if (Get.isSnackbarOpen == true) {
          Get.closeCurrentSnackbar();
        }
      } catch (e) {
        // Ignorer l'erreur de fermeture
      }

      // Attendre que le snackbar soit complètement fermé
      await Future.delayed(const Duration(milliseconds: 200));

      if (filePath != null) {
        Get.dialog(
          AlertDialog(
            title: const Text('Export réussi'),
            content: Text(
              'Export de ${allSuppliers.length} fournisseur(s) réussi.\n'
              'Fichier: ${filePath.split('/').last}',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Erreur lors de l\'export des fournisseurs',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      // Fermer le snackbar de progression en cas d'erreur
      try {
        if (Get.isSnackbarOpen == true) {
          Get.closeCurrentSnackbar();
        }
      } catch (e) {
        // Ignorer l'erreur de fermeture
      }

      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'export: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Importe des fournisseurs depuis Excel
  Future<void> importFromExcel() async {
    try {
      print('🔄 Début de l\'import Excel des fournisseurs...');

      Get.snackbar(
        'Import en cours',
        'Sélection du fichier...',
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );

      final importData = await _excelService.importSuppliersFromExcel();

      print('📊 Données importées: ${importData?.length ?? 0} fournisseurs');

      if (importData == null || importData.isEmpty) {
        print('⚠️  Aucune donnée à importer');
        Get.snackbar(
          'Annulé',
          'Aucun fichier sélectionné ou fichier vide',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      print('✅ ${importData.length} fournisseurs trouvés dans le fichier');

      // Afficher un aperçu et demander confirmation
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Importer ${importData.length} fournisseur(s) ?'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: importData.length > 5 ? 5 : importData.length,
              itemBuilder: (context, index) {
                final data = importData[index];
                return ListTile(
                  title: Text(data.nom),
                  subtitle: Text(data.telephone ?? 'Pas de téléphone'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Importer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Importer les fournisseurs
      int successCount = 0;
      int errorCount = 0;

      for (final data in importData) {
        try {
          final supplierForm = SupplierForm(
            nom: data.nom,
            personneContact: data.contact,
            telephone: data.telephone,
            email: data.email,
            adresse: data.adresse,
          );

          await _supplierService.createSupplier(supplierForm);
          successCount++;
        } catch (e) {
          errorCount++;
          print('❌ Erreur import fournisseur ${data.nom}: $e');
        }
      }

      // Rafraîchir la liste
      await refreshSuppliers();

      Get.dialog(
        AlertDialog(
          title: const Text('Import terminé'),
          content: Text(
            'Importés: $successCount\nErreurs: $errorCount',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'import: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  /// Télécharge le template d'import
  Future<void> downloadTemplate() async {
    try {
      final filePath = await _excelService.generateImportTemplate();

      if (filePath != null) {
        Get.dialog(
          AlertDialog(
            title: const Text('Template généré'),
            content: Text(
              'Template d\'import généré avec succès.\n'
              'Fichier: ${filePath.split('/').last}',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          'Erreur',
          'Erreur lors de la génération du template',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
