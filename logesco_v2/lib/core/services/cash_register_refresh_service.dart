import 'package:get/get.dart';
import '../../features/cash_registers/controllers/cash_register_controller.dart';

/// Service singleton pour rafraîchir les caisses depuis n'importe où dans l'app
class CashRegisterRefreshService {
  static final CashRegisterRefreshService _instance = CashRegisterRefreshService._internal();

  factory CashRegisterRefreshService() {
    return _instance;
  }

  CashRegisterRefreshService._internal();

  /// Rafraîchit le solde des caisses
  /// Fonctionne même si le contrôleur n'est pas enregistré
  Future<void> refreshCashRegisters() async {
    try {
      print('🔄 [CashRegisterRefreshService] ========== DEBUT RAFRAICHISSEMENT ==========');
      print('🔄 [CashRegisterRefreshService] Tentative de rafraîchissement des caisses');

      // Vérifier si le contrôleur existe déjà
      if (Get.isRegistered<CashRegisterController>()) {
        print('✅ [CashRegisterRefreshService] Contrôleur trouvé, rafraîchissement...');
        final controller = Get.find<CashRegisterController>();
        print('📊 [CashRegisterRefreshService] Nombre de caisses avant: ${controller.cashRegisters.length}');

        await controller.refreshCashRegisters();

        print('📊 [CashRegisterRefreshService] Nombre de caisses après: ${controller.cashRegisters.length}');
        if (controller.cashRegisters.isNotEmpty) {
          for (var caisse in controller.cashRegisters) {
            print('💰 [CashRegisterRefreshService] Caisse: ${caisse.nom} - Solde: ${caisse.soldeActuel} FCFA - Active: ${caisse.isActive}');
          }
        }
        print('✅ [CashRegisterRefreshService] Caisses rafraîchies via contrôleur existant');
      } else {
        // Créer temporairement le contrôleur pour rafraîchir
        print('⚠️ [CashRegisterRefreshService] Contrôleur non trouvé, création temporaire...');
        final controller = Get.put(CashRegisterController(), tag: 'temp_refresh');
        print('📊 [CashRegisterRefreshService] Contrôleur temporaire créé');

        await controller.loadCashRegisters();

        print('📊 [CashRegisterRefreshService] Nombre de caisses chargées: ${controller.cashRegisters.length}');
        if (controller.cashRegisters.isNotEmpty) {
          for (var caisse in controller.cashRegisters) {
            print('💰 [CashRegisterRefreshService] Caisse: ${caisse.nom} - Solde: ${caisse.soldeActuel} FCFA - Active: ${caisse.isActive}');
          }
        }
        print('✅ [CashRegisterRefreshService] Caisses rafraîchies via contrôleur temporaire');
        // Ne pas supprimer le contrôleur, il pourrait être utilisé ailleurs
      }

      print('🔄 [CashRegisterRefreshService] ========== FIN RAFRAICHISSEMENT ==========');
    } catch (e, stackTrace) {
      print('❌ [CashRegisterRefreshService] ========== ERREUR RAFRAICHISSEMENT ==========');
      print('❌ [CashRegisterRefreshService] Erreur lors du rafraîchissement: $e');
      print('❌ [CashRegisterRefreshService] Stack trace: $stackTrace');
      print('❌ [CashRegisterRefreshService] ========================================');
    }
  }

  /// Force le rafraîchissement de tous les contrôleurs de caisse enregistrés
  Future<void> forceRefreshAll() async {
    try {
      print('🔄 [CashRegisterRefreshService] Rafraîchissement forcé de tous les contrôleurs');

      // Rafraîchir tous les contrôleurs enregistrés
      final controllers = <CashRegisterController>[];

      // Contrôleur principal
      if (Get.isRegistered<CashRegisterController>()) {
        controllers.add(Get.find<CashRegisterController>());
      }

      // Contrôleur temporaire si existe
      if (Get.isRegistered<CashRegisterController>(tag: 'temp_refresh')) {
        controllers.add(Get.find<CashRegisterController>(tag: 'temp_refresh'));
      }

      // Rafraîchir tous
      for (var controller in controllers) {
        await controller.refreshCashRegisters();
      }

      print('✅ [CashRegisterRefreshService] ${controllers.length} contrôleur(s) rafraîchi(s)');
    } catch (e) {
      print('❌ [CashRegisterRefreshService] Erreur lors du rafraîchissement forcé: $e');
    }
  }
}
