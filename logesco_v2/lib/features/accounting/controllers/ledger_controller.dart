import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../boutiques/controllers/boutique_controller.dart';
import '../services/ledger_service.dart';

/// Contrôleur de la comptabilité en partie double (écritures, plan comptable, états, exercices).
class LedgerController extends GetxController {
  final LedgerService _service = LedgerService(Get.find<AuthService>());

  final isLoading = false.obs;
  final parametres = <String, dynamic>{}.obs;
  final comptes = <Map<String, dynamic>>[].obs;
  final journaux = <Map<String, dynamic>>[].obs;
  final exercices = <Map<String, dynamic>>[].obs;
  final ecritures = <Map<String, dynamic>>[].obs;
  final totalEcritures = 0.obs;

  // Filtres
  final filtreJournal = RxnString();
  final filtreStatut = RxnString();
  final parBoutique = false.obs; // false = toutes les boutiques (consolidé)

  // États
  final grandLivre = Rxn<Map<String, dynamic>>();
  final balance = Rxn<Map<String, dynamic>>();

  LedgerService get service => _service;

  bool get ouvertureFaite => parametres['ouvertureValidee'] == true;
  bool get modeExpert => parametres['modeAffichage'] == 'expert';

  int? get _boutiqueId => parBoutique.value ? BoutiqueController.getActiveBoutiqueId() : null;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<T?> _run<T>(Future<T> Function() action, {String? succes}) async {
    try {
      final r = await action();
      if (succes != null) SnackbarHelper.success(succes);
      return r;
    } on LedgerException catch (e) {
      SnackbarHelper.error(e.message);
    } catch (e) {
      SnackbarHelper.error(e.toString());
    }
    return null;
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    try {
      parametres.value = await _service.getParametres();
      journaux.value = await _service.journaux();
      exercices.value = await _service.exercices();
      comptes.value = await _service.comptes();
      derniereGeneration.value = await _service.derniereGeneration();
      await loadEcritures();
    } on LedgerException catch (e) {
      SnackbarHelper.error(e.message);
    } catch (e) {
      SnackbarHelper.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadEcritures() async {
    final r = await _run(() => _service.ecritures(
          journalCode: filtreJournal.value,
          statut: filtreStatut.value,
          boutiqueId: _boutiqueId,
        ));
    if (r == null) return;
    ecritures.value = List<Map<String, dynamic>>.from(r['ecritures'] as List);
    totalEcritures.value = (r['total'] as num).toInt();
  }

  Future<void> loadComptes({String? q}) async {
    final r = await _run(() => _service.comptes(q: q));
    if (r != null) comptes.value = r;
  }

  // ── Écritures ──
  Future<bool> enregistrerEcriture({int? id, required Map<String, dynamic> donnees}) async {
    final r = await _run(
      () => id == null ? _service.creerEcriture(donnees) : _service.modifierEcriture(id, donnees),
      succes: 'compta_msg_ecriture_enregistree'.tr,
    );
    if (r != null) await loadEcritures();
    return r != null;
  }

  Future<bool> valider(int id) async {
    final r = await _run(() => _service.validerEcriture(id), succes: 'compta_msg_ecriture_validee'.tr);
    if (r != null) await loadEcritures();
    return r != null;
  }

  Future<bool> supprimer(int id) async {
    final ok = await _run(() async {
      await _service.supprimerEcriture(id);
      return true;
    }, succes: 'compta_msg_brouillon_supprime'.tr);
    if (ok == true) await loadEcritures();
    return ok == true;
  }

  Future<bool> contrepasser(int id, {String? motif}) async {
    final r = await _run(() => _service.contrepasser(id, motif: motif), succes: 'compta_msg_contrepassee'.tr);
    if (r != null) await loadEcritures();
    return r != null;
  }

  // ── Plan comptable ──
  Future<bool> creerCompte(String numero, String libelle) async {
    final r = await _run(() => _service.creerCompte({'numero': numero, 'libelle': libelle}), succes: 'compta_msg_compte_cree'.tr);
    if (r != null) await loadComptes();
    return r != null;
  }

  // ── États ──
  Future<void> chargerGrandLivre(String compte, {String? dateDebut, String? dateFin}) async {
    grandLivre.value = await _run(() => _service.grandLivre(compte, dateDebut: dateDebut, dateFin: dateFin, boutiqueId: _boutiqueId));
  }

  Future<void> chargerBalance({String? dateDebut, String? dateFin}) async {
    balance.value = await _run(() => _service.balance(dateDebut: dateDebut, dateFin: dateFin, boutiqueId: _boutiqueId));
  }

  // ── Écritures automatiques et contrôles ──
  final generationEnCours = false.obs;
  final derniereGeneration = Rxn<Map<String, dynamic>>();
  final controles = Rxn<Map<String, dynamic>>();

  Future<void> chargerDerniereGeneration() async {
    derniereGeneration.value = await _run<Map<String, dynamic>?>(() => _service.derniereGeneration());
  }

  Future<void> lancerGeneration() async {
    generationEnCours.value = true;
    final r = await _run(() => _service.generer());
    generationEnCours.value = false;
    if (r == null) return;
    if (r['ignore'] != null) {
      SnackbarHelper.warning(r['ignore'].toString());
      return;
    }
    derniereGeneration.value = r;
    final erreurs = (r['erreurs'] as List).length;
    SnackbarHelper.success(erreurs == 0 ? 'compta_msg_generation_ok'.tr : 'compta_msg_generation_errors'.trParams({'n': '$erreurs'}));
    await loadEcritures();
  }

  Future<void> chargerControles() async {
    controles.value = await _run(() => _service.controles());
  }

  // ── Exercices, paramètres, ouverture ──
  Future<bool> creerExercice(String libelle, String debut, String fin) async {
    final r = await _run(() => _service.creerExercice({'libelle': libelle, 'dateDebut': debut, 'dateFin': fin}), succes: 'compta_msg_exercice_cree'.tr);
    if (r != null) exercices.value = await _service.exercices();
    return r != null;
  }

  Future<void> basculerPeriode(int exerciceId, int mois, bool verrouiller) async {
    final r = await _run(() => _service.changerPeriode(exerciceId, mois, verrouiller ? 'verrouillee' : 'ouverte'));
    if (r != null) exercices.value = await _service.exercices();
  }

  Future<void> changerParametres(Map<String, dynamic> patch) async {
    final r = await _run(() => _service.updateParametres(patch), succes: 'compta_msg_parametres_enregistres'.tr);
    if (r != null) parametres.value = r;
  }

  Future<bool> enregistrerOuverture(Map<String, dynamic> donnees) async {
    final r = await _run(() => _service.enregistrerOuverture(donnees), succes: 'compta_msg_ouverture_enregistree'.tr);
    if (r != null) await refreshAll();
    return r != null;
  }
}
