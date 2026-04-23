import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../features/boutiques/controllers/boutique_controller.dart';

/// Service global pour injecter automatiquement le boutiqueId dans toutes les opérations
class BoutiqueContextService extends GetxService {
  static BoutiqueContextService get instance => Get.find<BoutiqueContextService>();

  /// Retourne l'ID de la boutique active de façon fiable
  int? get activeBoutiqueId {
    try {
      // Méthode 1: Via la méthode statique (plus fiable)
      final staticId = BoutiqueController.getActiveBoutiqueId();
      if (staticId != null) {
        print('🏪 BoutiqueContextService: ID via méthode statique = $staticId');
        return staticId;
      }

      // Méthode 2: Via l'instance du contrôleur
      if (Get.isRegistered<BoutiqueController>()) {
        final controller = Get.find<BoutiqueController>();
        final controllerId = controller.activeBoutiqueId;
        if (controllerId != null) {
          print('🏪 BoutiqueContextService: ID via contrôleur = $controllerId');
          return controllerId;
        }
      }

      // Méthode 3: Directement depuis GetStorage
      try {
        GetStorage? storage;

        // Essayer d'abord via Get.find
        if (Get.isRegistered<GetStorage>()) {
          storage = Get.find<GetStorage>();
        } else {
          // Sinon créer une instance directe
          storage = GetStorage();
        }

        final raw = storage.read('active_boutique_id');
        if (raw != null) {
          int? storageId;
          if (raw is int) {
            storageId = raw;
          } else if (raw is double) {
            storageId = raw.toInt();
          } else if (raw is String) {
            storageId = int.tryParse(raw);
          } else if (raw is num) {
            storageId = raw.toInt();
          }

          if (storageId != null) {
            print('🏪 BoutiqueContextService: ID via storage = $storageId');
            return storageId;
          }
        }
      } catch (e) {
        print('⚠️ BoutiqueContextService: Erreur lecture storage: $e');
      }

      print('⚠️ BoutiqueContextService: Aucun ID de boutique trouvé');
      return null;
    } catch (e) {
      print('❌ BoutiqueContextService: Erreur récupération ID: $e');
      return null;
    }
  }

  /// Injecte le boutiqueId dans les paramètres d'une requête API
  Map<String, dynamic> injectBoutiqueId(Map<String, dynamic> params) {
    final boutiqueId = activeBoutiqueId;
    if (boutiqueId != null) {
      params['boutiqueId'] = boutiqueId;
      print('🏪 BoutiqueContextService: Injection boutiqueId = $boutiqueId dans $params');
    } else {
      print('⚠️ BoutiqueContextService: Pas de boutiqueId à injecter dans $params');
    }
    return params;
  }

  /// Injecte le boutiqueId dans les paramètres de query d'une URL
  Map<String, dynamic> injectBoutiqueIdQuery(Map<String, dynamic>? queryParams) {
    final params = queryParams ?? <String, dynamic>{};
    final boutiqueId = activeBoutiqueId;
    if (boutiqueId != null) {
      params['boutiqueId'] = boutiqueId;
      print('🏪 BoutiqueContextService: Injection boutiqueId = $boutiqueId dans query $params');
    } else {
      print('⚠️ BoutiqueContextService: Pas de boutiqueId à injecter dans query $params');
    }
    return params;
  }

  /// Vérifie si une boutique est active
  bool get hasBoutiqueActive => activeBoutiqueId != null;

  /// Affiche un message d'erreur si aucune boutique n'est active
  void requireActiveBoutique(String operation) {
    if (!hasBoutiqueActive) {
      final error = 'Aucune boutique active pour l\'opération: $operation';
      print('❌ BoutiqueContextService: $error');
      throw Exception(error);
    }
  }

  /// Méthode de debug pour obtenir des informations détaillées
  Map<String, dynamic> getDebugInfo() {
    final info = <String, dynamic>{};

    try {
      info['hasController'] = Get.isRegistered<BoutiqueController>();

      if (Get.isRegistered<BoutiqueController>()) {
        final controller = Get.find<BoutiqueController>();
        info['controllerBoutiques'] = controller.boutiques.length;
        info['controllerActiveBoutique'] = controller.boutiquesActive.value?.nom;
        info['controllerActiveId'] = controller.activeBoutiqueId;
      }

      info['staticId'] = BoutiqueController.getActiveBoutiqueId();

      try {
        final storage = Get.find<GetStorage>();
        info['storageId'] = storage.read('active_boutique_id');
      } catch (e) {
        info['storageError'] = e.toString();
      }

      info['currentActiveBoutiqueId'] = activeBoutiqueId;
      info['hasBoutiqueActive'] = hasBoutiqueActive;
    } catch (e) {
      info['error'] = e.toString();
    }

    return info;
  }
}
