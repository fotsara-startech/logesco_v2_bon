import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
import '../models/expiration_date.dart';
import '../services/expiration_date_service.dart';

/// Contrôleur GetX pour gérer les dates de péremption
class ExpirationDateController extends GetxController {
  final ExpirationDateService _service = ExpirationDateService();

  // État
  final isLoading = false.obs;
  final expirationDates = <ExpirationDate>[].obs;
  final alertStats = Rxn<ExpirationAlertStats>();

  // Filtres
  final selectedFilter = 'all'.obs; // all, expired, critical, warning
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadExpirationDates();
  }

  /// Charge les dates de péremption
  Future<void> loadExpirationDates({int? produitId}) async {
    try {
      isLoading.value = true;

      final result = await _service.getExpirationDates(
        produitId: produitId,
        estEpuise: false,
      );

      expirationDates.value = result['data'] as List<ExpirationDate>;
    } catch (e) {
      SnackbarHelper.error('Impossible de charger les dates de péremption: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Charge les alertes de péremption
  Future<void> loadAlerts({String? niveauAlerte, int joursMax = 30}) async {
    try {
      isLoading.value = true;

      final result = await _service.getExpirationAlerts(
        niveauAlerte: niveauAlerte,
        joursMax: joursMax,
      );

      expirationDates.value = result['data'] as List<ExpirationDate>;
      if (result['stats'] != null) {
        alertStats.value = result['stats'] as ExpirationAlertStats;
      }
    } catch (e) {
      SnackbarHelper.error('Impossible de charger les alertes: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Crée une nouvelle date de péremption
  Future<bool> createExpirationDate({
    required int produitId,
    required DateTime datePeremption,
    required int quantite,
    String? numeroLot,
    String? notes,
  }) async {
    try {
      isLoading.value = true;

      await _service.createExpirationDate(
        produitId: produitId,
        datePeremption: datePeremption,
        quantite: quantite,
        numeroLot: numeroLot,
        notes: notes,
      );

      SnackbarHelper.success('Date de péremption ajoutée');

      await loadExpirationDates(produitId: produitId);
      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible d\'ajouter la date: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Met à jour une date de péremption
  Future<bool> updateExpirationDate(
    int id, {
    DateTime? datePeremption,
    int? quantite,
    String? numeroLot,
    String? notes,
  }) async {
    try {
      isLoading.value = true;

      await _service.updateExpirationDate(
        id,
        datePeremption: datePeremption,
        quantite: quantite,
        numeroLot: numeroLot,
        notes: notes,
      );

      SnackbarHelper.success('Date de péremption mise à jour');

      await loadExpirationDates();
      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de mettre à jour: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprime une date de péremption
  Future<bool> deleteExpirationDate(int id) async {
    try {
      isLoading.value = true;

      await _service.deleteExpirationDate(id);

      SnackbarHelper.success('Date de péremption supprimée');

      await loadExpirationDates();
      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de supprimer: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Marque une date comme épuisée
  Future<bool> markAsExhausted(int id) async {
    try {
      isLoading.value = true;

      await _service.markAsExhausted(id);

      SnackbarHelper.success('Marqué comme épuisé');

      await loadExpirationDates();
      return true;
    } catch (e) {
      SnackbarHelper.error('Impossible de marquer comme épuisé: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Filtre les dates selon le filtre sélectionné
  List<ExpirationDate> get filteredDates {
    var dates = expirationDates.toList();

    // Appliquer le filtre de niveau
    switch (selectedFilter.value) {
      case 'expired':
        dates = dates.where((d) => d.estPerime).toList();
        break;
      case 'critical':
        dates = dates.where((d) => d.niveauAlerte == 'critique').toList();
        break;
      case 'warning':
        dates = dates.where((d) => d.niveauAlerte == 'avertissement').toList();
        break;
    }

    // Appliquer la recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      dates = dates.where((d) {
        final produitNom = d.produit?.nom.toLowerCase() ?? '';
        final numeroLot = d.numeroLot?.toLowerCase() ?? '';
        return produitNom.contains(query) || numeroLot.contains(query);
      }).toList();
    }

    // Trier par date de péremption (les plus proches en premier)
    dates.sort((a, b) => a.datePeremption.compareTo(b.datePeremption));

    return dates;
  }

  /// Change le filtre
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  /// Met à jour la recherche
  void updateSearch(String query) {
    searchQuery.value = query;
  }
}
