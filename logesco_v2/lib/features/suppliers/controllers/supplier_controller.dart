import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';
import '../services/supplier_excel_service.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';

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
        errorMessage.value = 'suppliers_erreur_lors_chargement_fournisseurs'.tr;
      }

      SnackbarHelper.error(errorMessage.value);
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
    print('📝 Navigation vers création fournisseur');
    print('  - Route: /suppliers/create');

    try {
      final result = await Get.toNamed('/suppliers/create');
      print('📄 Retour de la navigation, résultat: $result');

      // Toujours rafraîchir la liste après retour du formulaire
      print('📝 Rafraîchissement de la liste des fournisseurs...');
      await refreshSuppliers();

      // Si un fournisseur a été créé, afficher un message
      if (result != null && result is Supplier) {
        print('🎉 Nouveau fournisseur créé: ${result.nom}');
        SnackbarHelper.success('suppliers_fournisseur_ajoute_liste'.trParams({'nom': '${result.nom}'}), duration: const Duration(seconds: 2));
      }
    } catch (e) {
      print('❌ Erreur navigation: $e');
      SnackbarHelper.error('customers_create_form_error'.tr);
    }
  }

  /// Navigue vers l'édition d'un fournisseur
  Future<void> goToEditSupplier(Supplier supplier) async {
    print('📝 Navigation vers édition fournisseur ${supplier.id}');

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
      SnackbarHelper.error('customers_edit_form_error'.tr);
    }
  }

  /// Navigue vers les détails d'un fournisseur
  void goToSupplierDetail(Supplier supplier) {
    print('📝 Navigation vers détails fournisseur ${supplier.id}');
    Get.toNamed('/suppliers/${supplier.id}', arguments: supplier);
  }

  /// Supprime un fournisseur avec confirmation
  Future<void> deleteSupplier(Supplier supplier) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('users_delete_confirm_title'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('suppliers_etes_vous_sur_vouloir_supprimer_fournisseur'.trParams({'nom': '${supplier.nom}'})),
            const SizedBox(height: 8),
            Text(
              'suppliers_note_suppression_echouera_si_fournisseur_commandes'.tr,
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
            child: Text('suppliers_form_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('suppliers_delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        isLoading.value = true;
        print('📝 Début suppression fournisseur ID: ${supplier.id}');

        final success = await _supplierService.deleteSupplier(supplier.id);
        print('📦 Résultat suppression: $success');

        if (success) {
          // Supprimer de la liste locale
          suppliers.removeWhere((s) => s.id == supplier.id);
          print('✅ Fournisseur retiré de la liste locale');

          SnackbarHelper.success('suppliers_fournisseur_supprime_avec_succes'.trParams({'nom': '${supplier.nom}'}), duration: const Duration(seconds: 3));
        } else {
          print('❌ Suppression échouée - service retourné false');
          SnackbarHelper.error('suppliers_suppression_fournisseur_echoue_veuillez_reessayer'.tr, duration: const Duration(seconds: 4));
        }
      } catch (e) {
        print('❌ Exception lors de la suppression: $e');

        String message = 'suppliers_erreur_lors_suppression_fournisseur'.tr;
        if (e is ApiException) {
          switch (e.statusCode) {
            case 404:
              message = 'suppliers_not_found'.tr;
              break;
            case 403:
              message = 'suppliers_vous_n_avez_pas_droits_supprimer'.tr;
              break;
            case 409:
              message = 'suppliers_impossible_supprimer_fournisseur_commandes_associees'.tr;
              break;
            case 500:
              message = 'suppliers_erreur_serveur_veuillez_reessayer_plus_tard'.tr;
              break;
            default:
              message = e.message.isNotEmpty ? e.message : message;
          }
        }

        SnackbarHelper.error(message, duration: const Duration(seconds: 5));
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
      SnackbarHelper.error('suppliers_impossible_recuperer_details_fournisseur'.tr);
      return null;
    }
  }

  /// Charge les transactions d'un fournisseur
  Future<void> loadSupplierTransactions(int supplierId) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      print('📝 Chargement des transactions du fournisseur $supplierId...');

      final transactions = await _supplierService.getSupplierTransactions(supplierId);
      supplierTransactions.assignAll(transactions);

      print('✅ ${transactions.length} transaction(s) chargée(s)');
    } catch (e) {
      hasError.value = true;
      if (e is ApiException) {
        errorMessage.value = e.message;
      } else {
        errorMessage.value = 'accounts_erreur_lors_chargement_transactions'.tr;
      }

      print('❌ Erreur chargement transactions: $e');

      SnackbarHelper.error(errorMessage.value);
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
      print('💾 Paiement fournisseur $supplierId: $montant FCFA');

      final success = await _supplierService.paySupplier(
        supplierId,
        montant,
        description: description,
      );

      if (success) {
        SnackbarHelper.success('suppliers_paiement_fcfa_enregistre'.trParams({'toStringAsFixed': '${montant.toStringAsFixed(0)}'}));
        return true;
      } else {
        SnackbarHelper.error('suppliers_paiement_echoue'.tr);
        return false;
      }
    } catch (e) {
      print('❌ Erreur paiement fournisseur: $e');

      String message = 'suppliers_payment_error'.tr;
      if (e is ApiException) {
        message = e.message;
      }

      SnackbarHelper.error(message);
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
      print('💾 Paiement commande $procurementId du fournisseur $supplierId: $montant FCFA');
      print('  - Créer mouvement financier: $createFinancialMovement');

      final success = await _supplierService.paySupplierForProcurement(
        supplierId,
        montant,
        procurementId,
        description: description,
        createFinancialMovement: createFinancialMovement,
      );

      if (success) {
        SnackbarHelper.success('suppliers_paiement_fcfa_enregistre_commande'.trParams({'toStringAsFixed': '${montant.toStringAsFixed(0)}'}));
        return true;
      } else {
        SnackbarHelper.error('suppliers_paiement_echoue'.tr);
        return false;
      }
    } catch (e) {
      print('❌ Erreur paiement commande: $e');

      String message = 'suppliers_payment_error'.tr;
      if (e is ApiException) {
        message = e.message;
      }

      SnackbarHelper.error(message);
      return false;
    }
  }

  /// Récupère les données du relevé de compte fournisseur
  Future<Map<String, dynamic>?> getSupplierStatement(int supplierId) async {
    try {
      print('📝 Récupération relevé fournisseur $supplierId');
      return await _supplierService.getSupplierStatement(supplierId);
    } catch (e) {
      print('❌ Erreur récupération relevé: $e');
      SnackbarHelper.error('suppliers_impossible_recuperer_releve_compte'.tr);
      return null;
    }
  }

  /// Méthode appelée directement par le formulaire après création/modification
  void onSupplierSaved(Supplier supplier, {bool isEdit = false}) {
    print('✅ onSupplierSaved appelée pour: ${supplier.nom}');

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
      SnackbarHelper.info('suppliers_recuperation_fournisseurs'.tr, title: 'Export en cours');

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

        SnackbarHelper.info('suppliers_aucun_fournisseur_exporter'.tr, title: 'no_data'.tr);
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
      SnackbarHelper.info('customers_export_generating'.tr, title: 'Export en cours');

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
        final filename = kIsWeb ? filePath : filePath.split('/').last;

        if (kIsWeb) {
          SnackbarHelper.success(
            'suppliers_export_fournisseur_s_reussi_nfichier'.trParams({'length': '${allSuppliers.length}', 'filename': '${filename}'}),
            title: 'customers_export_success'.tr,
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.dialog(
            AlertDialog(
              title: Text('customers_export_success'.tr),
              content: Text(
                'Export de ${allSuppliers.length} fournisseur(s) réussi.\n'
                'Fichier: $filename',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('suppliers_close'.tr),
                ),
              ],
            ),
          );
        }
      } else {
        SnackbarHelper.error('suppliers_erreur_lors_export_fournisseurs'.tr);
      }
    } catch (e) {
      print('❌ Erreur export fournisseurs: $e');
      // Fermer le snackbar de progression en cas d'erreur
      try {
        if (Get.isSnackbarOpen == true) {
          Get.closeCurrentSnackbar();
        }
      } catch (e) {
        // Ignorer l'erreur de fermeture
      }

      SnackbarHelper.error('suppliers_erreur_lors_export'.trParams({'e': '${e}'}));
    }
  }

  /// Importe des fournisseurs depuis Excel
  Future<void> importFromExcel() async {
    try {
      print('📝 Début de l\'import Excel des fournisseurs...');

      SnackbarHelper.info('suppliers_selection_fichier'.tr, title: 'Import en cours', duration: const Duration(seconds: 2));

      final importData = await _excelService.importSuppliersFromExcel();

      print('📊 Données importées: ${importData?.length ?? 0} fournisseurs');

      if (importData == null || importData.isEmpty) {
        print('⚠️  Aucune donnée à importer');
        SnackbarHelper.info('customers_import_no_file'.tr, title: 'suppliers_annule'.tr);
        return;
      }

      print('✅ ${importData.length} fournisseurs trouvés dans le fichier');

      // Afficher un aperçu et demander confirmation
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('suppliers_importer_fournisseur_s'.trParams({'length': '${importData.length}'})),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: importData.length > 5 ? 5 : importData.length,
              itemBuilder: (context, index) {
                final data = importData[index];
                return ListTile(
                  title: Text(data.nom),
                  subtitle: Text(data.telephone ?? 'customers_no_phone'.tr),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('suppliers_form_cancel'.tr),
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
          title: Text('customers_import_success'.tr),
          content: Text(
            'suppliers_importes_nerreurs'.trParams({'successCount': '${successCount}', 'errorCount': '${errorCount}'}),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('suppliers_close'.tr),
            ),
          ],
        ),
      );
    } catch (e) {
      SnackbarHelper.error('suppliers_erreur_lors_import'.trParams({'e': '${e}'}));
    }
  }

  /// Télécharge le template d'import
  Future<void> downloadTemplate() async {
    try {
      final filePath = await _excelService.generateImportTemplate();

      if (filePath != null) {
        Get.dialog(
          AlertDialog(
            title: Text('customers_template_success'.tr),
            content: Text(
              'Template d\'import généré avec succès.\n'
              'Fichier: ${kIsWeb ? filePath : filePath.split('/').last}',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('suppliers_close'.tr),
              ),
            ],
          ),
        );
      } else {
        SnackbarHelper.error('customers_template_error'.tr);
      }
    } catch (e) {
      SnackbarHelper.error('suppliers_erreur'.trParams({'e': '${e}'}));
    }
  }
}
