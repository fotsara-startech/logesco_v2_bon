import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/boutique_model.dart';
import '../models/stock_transfert_model.dart';
import '../services/boutique_service.dart';
import '../../inventory/controllers/inventory_controller.dart';
import '../../inventory/controllers/inventory_getx_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../financial_movements/services/financial_movement_service.dart';
import '../../stock_inventory/controllers/stock_inventory_controller.dart';
import '../../cash_registers/controllers/cash_register_controller.dart';
import '../../cash_registers/controllers/cash_session_controller.dart';
import '../../auth/controllers/auth_controller.dart';

/// Gère le contexte multi-boutique : boutique active, liste, transferts
class BoutiqueController extends GetxController {
  final BoutiqueService _service = Get.find<BoutiqueService>();
  final _storage = GetStorage();

  static const _activeBoutiqueKey = 'active_boutique_id';

  // ─── État observable ─────────────────────────────────────────────────────────

  final RxList<Boutique> boutiques = <Boutique>[].obs;
  final Rx<Boutique?> boutiquesActive = Rx<Boutique?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<StockTransfert> transferts = <StockTransfert>[].obs;
  final RxBool isTransferLoading = false.obs;

  // ─── Getters ─────────────────────────────────────────────────────────────────

  int? get activeBoutiqueId => boutiquesActive.value?.id;
  bool get hasBoutiques => boutiques.isNotEmpty;
  bool get isMultiBoutique => boutiques.length > 1;

  /// Accès statique à l'ID de la boutique active — utilisé par tous les modules
  static int? getActiveBoutiqueId() {
    try {
      final ctrl = Get.find<BoutiqueController>();
      // 1. Boutique active en mémoire (source principale)
      if (ctrl.boutiquesActive.value != null) {
        return ctrl.boutiquesActive.value!.id;
      }
      // 2. Boutiques chargées mais active pas encore définie
      if (ctrl.boutiques.isNotEmpty) {
        final principale = ctrl.boutiques.firstWhereOrNull((b) => b.estPrincipale);
        final id = principale?.id ?? ctrl.boutiques.first.id;
        // Définir la boutique active maintenant
        ctrl.boutiquesActive.value = principale ?? ctrl.boutiques.first;
        return id;
      }
    } catch (_) {}
    // 3. Dernier recours : GetStorage (lecture robuste sans type)
    try {
      final raw = GetStorage().read(_activeBoutiqueKey);
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is double) return raw.toInt();
      if (raw is String) return int.tryParse(raw);
      return (raw as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Écouter les changements d'authentification pour charger les boutiques automatiquement
    ever(Get.find<AuthController>().isAuthenticated, (bool authenticated) {
      if (authenticated) {
        loadBoutiques();
      } else {
        // Réinitialiser quand déconnecté
        boutiques.clear();
        boutiquesActive.value = null;
      }
    });
  }

  // ─── Chargement ──────────────────────────────────────────────────────────────

  Future<void> loadBoutiques() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final list = await _service.getBoutiques();
      boutiques.assignAll(list);
      _restoreActiveBoutique();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Restaure la boutique active depuis le stockage local, ou prend la principale
  void _restoreActiveBoutique() {
    if (boutiques.isEmpty) return;

    // Lire l'id sauvegardé de façon robuste (sans type strict)
    final raw = _storage.read(_activeBoutiqueKey);
    int? savedId;
    if (raw is int)
      savedId = raw;
    else if (raw is double)
      savedId = raw.toInt();
    else if (raw is String)
      savedId = int.tryParse(raw);
    else if (raw is num) savedId = raw.toInt();

    if (savedId != null) {
      final saved = boutiques.firstWhereOrNull((b) => b.id == savedId);
      if (saved != null) {
        boutiquesActive.value = saved;
        return;
      }
    }
    // Fallback : boutique principale ou première de la liste
    boutiquesActive.value = boutiques.firstWhereOrNull((b) => b.estPrincipale) ?? boutiques.first;
    _storage.write(_activeBoutiqueKey, boutiquesActive.value!.id);
  }

  /// Change la boutique active — vérifie que l'utilisateur y a accès
  void switchBoutique(Boutique boutique) {
    // La liste `boutiques` est déjà filtrée par le backend selon les assignations
    // On vérifie simplement que la boutique est dans la liste autorisée
    if (!boutiques.any((b) => b.id == boutique.id)) {
      return; // Accès refusé silencieux — ne devrait pas arriver via l'UI
    }
    boutiquesActive.value = boutique;
    _storage.write(_activeBoutiqueKey, boutique.id);
    _reloadAllContextes();
  }

  /// Recharge tous les modules avec le contexte de la nouvelle boutique
  void _reloadAllContextes() {
    // Stock (InventoryController - legacy)
    try {
      Get.find<InventoryController>().refreshStock();
    } catch (_) {}

    // Stock (InventoryGetxController - page actuelle)
    try {
      Get.find<InventoryGetxController>().refreshAll();
    } catch (_) {}

    // Inventaire de stock physique
    try {
      Get.find<StockInventoryController>().loadInventories();
    } catch (_) {}

    // Caisses
    try {
      Get.find<CashRegisterController>().loadCashRegisters();
    } catch (_) {}

    // Session de caisse active (recharger pour la nouvelle boutique)
    try {
      Get.find<CashSessionController>().loadActiveSession();
    } catch (_) {}

    // Historique sessions de caisse
    try {
      Get.find<CashSessionController>().loadSessionHistory();
    } catch (_) {}

    // Dashboard
    try {
      Get.find<DashboardController>().refresh();
    } catch (_) {}

    // SalesController (vider le panier et recharger)
    try {
      Get.find<SalesController>().reloadForBoutique();
    } catch (_) {}

    // Mouvements financiers (invalider le cache)
    try {
      Get.find<FinancialMovementService>().refreshCache();
    } catch (_) {}
  }

  // ─── CRUD boutiques ──────────────────────────────────────────────────────────

  Future<Boutique?> createBoutique({
    required String nom,
    String? adresse,
    String? telephone,
    String? email,
    String? description,
  }) async {
    try {
      isLoading.value = true;
      final boutique = await _service.createBoutique(
        nom: nom,
        adresse: adresse,
        telephone: telephone,
        email: email,
        description: description,
      );
      boutiques.add(boutique);
      return boutique;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateBoutique(int id, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final updated = await _service.updateBoutique(id, data);
      final idx = boutiques.indexWhere((b) => b.id == id);
      if (idx != -1) boutiques[idx] = updated;
      if (boutiquesActive.value?.id == id) boutiquesActive.value = updated;
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteBoutique(int id) async {
    try {
      await _service.deleteBoutique(id);
      boutiques.removeWhere((b) => b.id == id);
      if (boutiquesActive.value?.id == id) _restoreActiveBoutique();
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  // ─── Transferts de stock ─────────────────────────────────────────────────────

  Future<void> loadTransferts({int? boutiqueId}) async {
    try {
      isTransferLoading.value = true;
      final list = await _service.getTransferts(boutiqueId: boutiqueId ?? activeBoutiqueId);
      transferts.assignAll(list);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isTransferLoading.value = false;
    }
  }

  Future<StockTransfert?> createTransfert({
    required int sourceBoutiqueId,
    required int destBoutiqueId,
    required int produitId,
    required int quantite,
    String? notes,
  }) async {
    try {
      isTransferLoading.value = true;
      final transfert = await _service.createTransfert(
        sourceBoutiqueId: sourceBoutiqueId,
        destBoutiqueId: destBoutiqueId,
        produitId: produitId,
        quantite: quantite,
        notes: notes,
      );
      transferts.insert(0, transfert);
      return transfert;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isTransferLoading.value = false;
    }
  }
}
