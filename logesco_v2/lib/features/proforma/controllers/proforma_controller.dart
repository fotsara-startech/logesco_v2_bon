import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../sales/models/sale.dart';
import '../../cash_registers/controllers/cash_session_controller.dart';
import '../../printing/services/printing_service.dart';
import '../../printing/models/models.dart';
import '../../printing/controllers/printing_controller.dart';
import '../../printing/views/receipt_preview_page.dart';
import '../../company_settings/controllers/company_settings_controller.dart';
import '../../boutiques/controllers/boutique_controller.dart';
import '../models/proforma_invoice.dart';
import '../services/proforma_service.dart';

class ProformaController extends GetxController {
  final ProformaService _service = ProformaService(Get.find<AuthService>());
  final PrintingService _printingService = PrintingService(Get.find<AuthService>());

  // État — variables normales + update() pour GetBuilder
  List<ProformaInvoice> proformas = [];
  bool isLoading = false;
  bool isSaving = false;
  bool isValidating = false;
  String statusFilter = '';
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadProformas(refresh: true);

    // Écouter les changements de boutique active
    if (Get.isRegistered<BoutiqueController>()) {
      final boutiqueController = Get.find<BoutiqueController>();
      ever(boutiqueController.boutiquesActive, (_) {
        // Recharger les proformas quand la boutique change
        loadProformas(refresh: true);
      });
    }
  }

  Future<void> loadProformas({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      proformas = [];
    }
    if (!_hasMore) return;

    isLoading = true;
    update();

    try {
      int? vendeurId;
      try {
        final auth = Get.find<AuthController>();
        final user = auth.currentUser.value;
        if (user != null && !user.role.isAdmin) vendeurId = user.id;
      } catch (_) {}

      final response = await _service.getProformas(
        page: _currentPage,
        statut: statusFilter.isEmpty ? null : statusFilter,
        vendeurId: vendeurId,
      );

      if (response.success && response.data != null) {
        if (refresh) {
          proformas = response.data!;
        } else {
          proformas = [...proformas, ...response.data!];
        }
        if (response.pagination != null) {
          _hasMore = _currentPage < response.pagination!.totalPages;
        } else {
          _hasMore = false;
        }
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur chargement proformas');
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur: $e');
    } finally {
      isLoading = false;
      update();
    }
  }

  void setStatusFilter(String status) {
    statusFilter = status;
    update();
    loadProformas(refresh: true);
  }

  /// Crée une proforma depuis le panier actuel
  Future<ProformaInvoice?> createFromCart(SalesController salesCtrl) async {
    if (salesCtrl.cartItems.isEmpty) {
      SnackbarUtils.showError('Le panier est vide');
      return null;
    }

    salesCtrl.clampCartPricesToMinimum();

    isSaving = true;
    update();

    try {
      final details = salesCtrl.cartItems.map((item) {
        final diff = item.originalPrice - item.unitPrice;
        return CreateProformaDetailRequest(
          produitId: item.productId,
          quantite: item.quantity,
          prixUnitaire: item.unitPrice,
          prixAffiche: item.originalPrice,
          remiseAppliquee: diff > 0 ? diff : 0.0,
          justificationRemise: item.discountJustification,
        );
      }).toList();

      final request = CreateProformaRequest(
        clientId: salesCtrl.selectedCustomer?.id,
        modePaiement: salesCtrl.paymentMode,
        montantRemise: salesCtrl.discount,
        montantTva: salesCtrl.tvaAmount,
        tauxTva: salesCtrl.tvaEnabled ? salesCtrl.tvaRate : null,
        dateVente: salesCtrl.customSaleDate,
        details: details,
      );

      final response = await _service.createProforma(request);

      if (response.success && response.data != null) {
        proformas = [response.data!, ...proformas];
        update();
        SnackbarUtils.showSuccess('Proforma ${response.data!.numeroProforma} créée');
        return response.data;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur création proforma');
        return null;
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur: $e');
      return null;
    } finally {
      isSaving = false;
      update();
    }
  }

  /// Met à jour une proforma existante depuis le panier
  Future<bool> updateFromCart(int proformaId, SalesController salesCtrl) async {
    if (salesCtrl.cartItems.isEmpty) {
      SnackbarUtils.showError('Le panier est vide');
      return false;
    }

    salesCtrl.clampCartPricesToMinimum();

    isSaving = true;
    update();

    try {
      final details = salesCtrl.cartItems.map((item) {
        final diff = item.originalPrice - item.unitPrice;
        return CreateProformaDetailRequest(
          produitId: item.productId,
          quantite: item.quantity,
          prixUnitaire: item.unitPrice,
          prixAffiche: item.originalPrice,
          remiseAppliquee: diff > 0 ? diff : 0.0,
          justificationRemise: item.discountJustification,
        );
      }).toList();

      final request = CreateProformaRequest(
        clientId: salesCtrl.selectedCustomer?.id,
        modePaiement: salesCtrl.paymentMode,
        montantRemise: salesCtrl.discount,
        montantTva: salesCtrl.tvaAmount,
        tauxTva: salesCtrl.tvaEnabled ? salesCtrl.tvaRate : null,
        dateVente: salesCtrl.customSaleDate,
        details: details,
      );

      final response = await _service.updateProforma(proformaId, request);

      if (response.success && response.data != null) {
        final idx = proformas.indexWhere((p) => p.id == proformaId);
        if (idx >= 0) {
          proformas = List.from(proformas)..[idx] = response.data!;
        }
        update();
        SnackbarUtils.showSuccess('Proforma mise à jour');
        return true;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur mise à jour');
        return false;
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur: $e');
      return false;
    } finally {
      isSaving = false;
      update();
    }
  }

  /// Valide une proforma → crée la vente réelle
  Future<Sale?> validateProforma(
    ProformaInvoice proforma, {
    required String modePaiement,
    required double montantPaye,
    DateTime? dateVente,
    double? montantTva,
    double? tauxTva,
  }) async {
    try {
      final cashCtrl = Get.find<CashSessionController>();
      if (!cashCtrl.canMakeSales) {
        SnackbarUtils.showError('Vous devez vous connecter à une caisse pour valider une proforma');
        Get.toNamed('/cash-session');
        return null;
      }
    } catch (_) {}

    isValidating = true;
    update();

    try {
      final request = ValidateProformaRequest(
        modePaiement: modePaiement,
        montantPaye: montantPaye,
        dateVente: dateVente,
        montantTva: montantTva,
        tauxTva: tauxTva,
      );

      final response = await _service.validateProforma(proforma.id, request);

      if (response.success && response.data != null) {
        final sale = response.data!;

        try {
          final cashCtrl = Get.find<CashSessionController>();
          if (cashCtrl.canMakeSales) cashCtrl.addToCurrentBalance(sale.montantPaye);
        } catch (_) {}

        try {
          await _printingService.generateReceipt(
            request: GenerateReceiptRequest(
              saleId: sale.id.toString(),
              format: PrintFormat.thermal,
              includeCompanyInfo: true,
            ),
          );
        } catch (_) {}

        await loadProformas(refresh: true);

        try {
          final salesCtrl = Get.find<SalesController>();
          await salesCtrl.loadSales(refresh: true);
          await salesCtrl.loadStocks();
        } catch (_) {}

        SnackbarHelper.success('Vente ${sale.numeroVente} créée avec succès', duration: const Duration(seconds: 4));

        return sale;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur lors de la validation');
        return null;
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur: $e');
      return null;
    } finally {
      isValidating = false;
      update();
    }
  }

  /// Imprime / prévisualise une proforma
  Future<void> printProforma(ProformaInvoice proforma) async {
    try {
      // Récupérer le profil d'entreprise
      final companyCtrl = Get.find<CompanySettingsController>();
      if (companyCtrl.companyProfile == null) {
        await companyCtrl.loadCompanyProfile();
      }

      final companyProfile = companyCtrl.companyProfile;
      if (companyProfile == null) {
        SnackbarUtils.showError('Profil entreprise non configuré. Allez dans Paramètres > Entreprise.');
        return;
      }

      // Construire le Receipt depuis la proforma
      final receipt = Receipt.fromProforma(
        proforma: proforma,
        companyInfo: companyProfile,
        format: PrintFormat.a4,
      );

      // S'assurer que PrintingController est disponible
      if (!Get.isRegistered<PrintingController>()) {
        Get.put(PrintingController());
      }
      final printingCtrl = Get.find<PrintingController>();
      printingCtrl.selectReceipt(receipt);

      // Naviguer vers la prévisualisation
      Get.to(() => const ReceiptPreviewPage(), arguments: receipt);
    } catch (e) {
      SnackbarUtils.showError('Erreur lors de la génération du document: $e');
    }
  }

  /// Annule une proforma
  Future<bool> cancelProforma(int id) async {
    try {
      final response = await _service.cancelProforma(id);
      if (response.success) {
        proformas = proformas.where((p) => p.id != id).toList();
        update();
        SnackbarUtils.showSuccess('Proforma annulée');
        return true;
      } else {
        SnackbarUtils.showError(response.message ?? 'Erreur annulation');
        return false;
      }
    } catch (e) {
      SnackbarUtils.showError('Erreur: $e');
      return false;
    }
  }
}
