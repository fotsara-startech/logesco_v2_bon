import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/exceptions.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../models/ville.dart';
import '../models/zone.dart';
import '../models/commercial.dart';
import '../services/commercial_service.dart';
import 'commercial_controller.dart';

/// Contrôleur du formulaire de création/modification d'un commercial.
///
/// La cascade ville → zone se fait entièrement côté client : la liste
/// complète des zones est déjà chargée par [CommercialController], on la
/// filtre ici sur la ville sélectionnée plutôt que de refaire un appel
/// réseau à chaque changement de ville.
class CommercialFormController extends GetxController {
  final CommercialService _service = Get.find<CommercialService>();
  late final CommercialController _commercialController;

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final telephoneController = TextEditingController();

  final Rx<Ville?> selectedVille = Rx<Ville?>(null);
  final Rx<Zone?> selectedZone = Rx<Zone?>(null);
  final RxBool isActive = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isEditing = false.obs;

  Commercial? _currentCommercial;

  List<Zone> get zonesDisponibles {
    final villeId = selectedVille.value?.id;
    if (villeId == null) return [];
    return _commercialController.zonesDe(villeId);
  }

  @override
  void onInit() {
    super.onInit();
    _commercialController = Get.find<CommercialController>();
    _initializeForm();
  }

  @override
  void onClose() {
    nomController.dispose();
    prenomController.dispose();
    telephoneController.dispose();
    super.onClose();
  }

  void _initializeForm() {
    final commercial = Get.arguments as Commercial?;
    if (commercial == null) return;

    isEditing.value = true;
    _currentCommercial = commercial;

    nomController.text = commercial.nom;
    prenomController.text = commercial.prenom ?? '';
    telephoneController.text = commercial.telephone ?? '';
    isActive.value = commercial.isActive;

    final zone = commercial.zone;
    if (zone != null) {
      selectedZone.value = zone;
      selectedVille.value = zone.ville ?? _commercialController.villes.firstWhereOrNull((v) => v.id == zone.villeId);
    }
  }

  /// Changement de ville : réinitialise la zone sélectionnée si elle
  /// n'appartient plus à la ville choisie.
  void setVille(Ville? ville) {
    selectedVille.value = ville;
    if (ville != null && selectedZone.value?.villeId != ville.id) {
      selectedZone.value = null;
    }
  }

  void setZone(Zone? zone) => selectedZone.value = zone;

  String? validateNom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom du commercial est obligatoire';
    }
    return null;
  }

  String? validateZone(Zone? value) {
    if (value == null) return 'La zone est obligatoire';
    return null;
  }

  Future<void> saveCommercial() async {
    if (nomController.text.trim().isEmpty) {
      SnackbarHelper.error('Le nom du commercial est obligatoire');
      return;
    }
    if (selectedZone.value == null) {
      SnackbarHelper.error('Veuillez sélectionner une zone');
      return;
    }

    try {
      isLoading.value = true;

      final form = CommercialForm(
        nom: nomController.text.trim(),
        prenom: prenomController.text.trim().isEmpty ? null : prenomController.text.trim(),
        telephone: telephoneController.text.trim().isEmpty ? null : telephoneController.text.trim(),
        zoneId: selectedZone.value!.id,
        isActive: isActive.value,
      );

      Commercial saved;
      if (isEditing.value && _currentCommercial != null) {
        saved = await _service.updateCommercial(_currentCommercial!.id, form);
        SnackbarHelper.success('Commercial modifié avec succès');
      } else {
        saved = await _service.createCommercial(form);
        SnackbarHelper.success('Commercial créé avec succès');
      }

      _commercialController.onCommercialSaved(saved, isEdit: isEditing.value);
      Get.back(result: saved);
    } catch (e) {
      String message = 'Erreur lors de la sauvegarde du commercial';
      if (e is ApiException) message = e.message;
      SnackbarHelper.error(message, duration: const Duration(seconds: 5));
    } finally {
      isLoading.value = false;
    }
  }
}
