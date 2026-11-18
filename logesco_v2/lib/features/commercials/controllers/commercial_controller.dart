import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../models/ville.dart';
import '../models/zone.dart';
import '../models/commercial.dart';
import '../services/commercial_service.dart';

/// Contrôleur pour la gestion des villes, zones et commerciaux terrain.
///
/// Les trois listes tiennent largement en mémoire (un commerce a des
/// dizaines de commerciaux, pas des milliers) : pas de pagination, tout est
/// chargé en une fois et tenu à jour localement après chaque mutation.
class CommercialController extends GetxController {
  final CommercialService _service = Get.find<CommercialService>();

  final RxList<Ville> villes = <Ville>[].obs;
  final RxList<Zone> zones = <Zone>[].obs;
  final RxList<Commercial> commerciaux = <Commercial>[].obs;

  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  List<Commercial> get commerciauxFiltres {
    if (searchQuery.value.isEmpty) return commerciaux;
    final q = searchQuery.value.toLowerCase();
    return commerciaux.where((c) => c.nomComplet.toLowerCase().contains(q)).toList();
  }

  /// Zones triées, groupées visuellement par ville — utilisé par les
  /// dropdowns qui n'ont pas besoin d'une sélection de ville préalable.
  List<Zone> zonesDe(int villeId) => zones.where((z) => z.villeId == villeId).toList();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _service.getVilles(),
        _service.getZones(),
        _service.getCommerciaux(),
      ]);
      villes.assignAll(results[0] as List<Ville>);
      zones.assignAll(results[1] as List<Zone>);
      commerciaux.assignAll(results[2] as List<Commercial>);
    } catch (e) {
      SnackbarHelper.error('commercials_erreur_lors_chargement_commerciaux'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) => searchQuery.value = query;

  /// Ouvre un dialogue simple pour créer une ville, retourne la ville créée.
  Future<Ville?> createVilleDialog() async {
    final controller = TextEditingController();
    final nom = await Get.dialog<String>(
      AlertDialog(
        title: Text('commercials_nouvelle_ville'.tr),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: 'commercials_nom_ville'.tr),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('suppliers_form_cancel'.tr)),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: Text('suppliers_form_create'.tr),
          ),
        ],
      ),
    );

    if (nom == null || nom.isEmpty) return null;

    try {
      final ville = await _service.createVille(nom);
      villes.add(ville);
      villes.sort((a, b) => a.nom.compareTo(b.nom));
      SnackbarHelper.success('commercials_ville_creee'.trParams({'nom': '${ville.nom}'}));
      return ville;
    } catch (e) {
      SnackbarHelper.error('commercials_erreur_lors_creation_ville'.tr);
      return null;
    }
  }

  /// Ouvre un dialogue simple pour créer une zone dans une ville donnée.
  Future<Zone?> createZoneDialog(int villeId) async {
    final controller = TextEditingController();
    final nom = await Get.dialog<String>(
      AlertDialog(
        title: Text('commercials_nouvelle_zone'.tr),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: 'commercials_nom_zone_quartier'.tr),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('suppliers_form_cancel'.tr)),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text.trim()),
            child: Text('suppliers_form_create'.tr),
          ),
        ],
      ),
    );

    if (nom == null || nom.isEmpty) return null;

    try {
      final zone = await _service.createZone(nom, villeId);
      zones.add(zone);
      SnackbarHelper.success('commercials_zone_creee'.trParams({'nom': '${zone.nom}'}));
      return zone;
    } catch (e) {
      SnackbarHelper.error('commercials_erreur_lors_creation_zone'.tr);
      return null;
    }
  }

  Future<void> deleteCommercial(Commercial commercial) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('users_delete_confirm_title'.tr),
        content: Text('commercials_supprimer_commercial'.trParams({'nomComplet': '${commercial.nomComplet}'})),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('suppliers_form_cancel'.tr)),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('suppliers_delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _service.deleteCommercial(commercial.id);
      if (success) {
        commerciaux.removeWhere((c) => c.id == commercial.id);
        SnackbarHelper.success('commercials_commercial_supprime'.trParams({'nomComplet': '${commercial.nomComplet}'}));
      } else {
        SnackbarHelper.error('commercials_suppression_echoue'.tr);
      }
    } catch (e) {
      String message = 'Erreur lors de la suppression';
      if (e is ApiException && e.statusCode == 409) {
        message = 'Impossible de supprimer : des ventes sont attribuées à ce commercial. '
            'Désactivez-le plutôt que de le supprimer.';
      }
      SnackbarHelper.error(message, duration: const Duration(seconds: 5));
    }
  }

  void onCommercialSaved(Commercial commercial, {bool isEdit = false}) {
    if (isEdit) {
      final index = commerciaux.indexWhere((c) => c.id == commercial.id);
      if (index != -1) {
        commerciaux[index] = commercial;
      } else {
        commerciaux.insert(0, commercial);
      }
    } else {
      commerciaux.insert(0, commercial);
    }
    commerciaux.refresh();
  }
}
