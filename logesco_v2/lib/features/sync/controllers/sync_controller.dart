import 'dart:async';
import 'package:get/get.dart';
import '../services/sync_status_service.dart';
import '../../../core/utils/snackbar_helper.dart';

class SyncController extends GetxController {
  final SyncStatusService _service = SyncStatusService();

  final Rx<SyncStatus?> status = Rx<SyncStatus?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSyncing = false.obs;

  /// Détail de chaque élément non synchronisé (vide si tout est à jour)
  final RxList<SyncDetailItem> details = <SyncDetailItem>[].obs;

  /// Dernier contrôle d'écart avec le cloud (null tant qu'aucun n'a abouti)
  final Rx<SyncDriftReport?> drift = Rx<SyncDriftReport?>(null);
  final RxBool isCheckingDrift = false.obs;

  Timer? _pollTimer;
  bool _staleWarned = false;
  bool _driftWarned = false;

  @override
  void onInit() {
    super.onInit();
    _fetchStatus();
    // Poll toutes les 30s
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchStatus());
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> _fetchStatus() async {
    final result = await _service.getStatus();
    if (result != null) {
      status.value = result;
      // Alerte visible une fois par session : des données restent sans partir
      // vers le cloud depuis plus de 24 h (liaison bloquée, serveur injoignable…)
      if (result.isType3 && result.isStale && !_staleWarned) {
        _staleWarned = true;
        SnackbarHelper.warning(
          '${result.pendingCount} opération(s) ne sont pas synchronisées depuis ${result.pendingAgeLabel}. '
          'Vérifiez la connexion internet (menu Synchronisation).',
          duration: const Duration(seconds: 10),
        );
      }
      if (!result.isStale) _staleWarned = false;

      // Écart avec le cloud qui dure depuis plus d'un jour : invisible ailleurs, donc signalé une fois par session
      if (result.isType3 && result.driftAnciens > 0 && !_driftWarned) {
        _driftWarned = true;
        SnackbarHelper.warning(
          '${result.driftAnciens} élément(s) diffèrent entre ce poste et le cloud depuis plus d\'un jour. '
          'Voir le menu Synchronisation.',
          duration: const Duration(seconds: 10),
        );
      }

      // Détail de ce qui n'est pas synchronisé : seulement s'il y a quelque chose à expliquer
      if (result.isType3 && (result.hasPending || result.pullIssuesCount > 0)) {
        await _fetchDetails();
      } else {
        details.clear();
      }

      // Contrôle d'écart : on rapatrie le rapport quand le serveur en a un
      if (result.isType3 && result.driftInexpliques != null && !isCheckingDrift.value) {
        final rapport = await _service.getDrift();
        if (rapport != null) drift.value = rapport;
      }
    }
  }

  /// Aperçu de ce qui peut être renvoyé vers le cloud (lève une exception avec le message du serveur)
  Future<SyncResendResult> apercuRenvoi() => _service.resend(dryRun: true);

  /// Renvoie vers le cloud ce qui est sans risque ; le contrôle d'écart sera à jour après l'envoi
  Future<SyncResendResult?> renvoyer() async {
    try {
      final r = await _service.resend(dryRun: false);
      SnackbarHelper.success('${r.envoyes} élément(s) mis en file d\'envoi vers le cloud.');
      await _fetchStatus();
      return r;
    } catch (e) {
      SnackbarHelper.error(e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  /// Relance la comparaison avec le cloud et affiche le résultat
  Future<void> verifierEcart() async {
    if (isCheckingDrift.value) return;
    isCheckingDrift.value = true;
    try {
      final rapport = await _service.getDrift(refresh: true);
      if (rapport == null) {
        SnackbarHelper.error('Contrôle impossible : cloud injoignable ou serveur trop ancien.');
      } else {
        drift.value = rapport;
      }
    } finally {
      isCheckingDrift.value = false;
    }
  }

  Future<void> _fetchDetails() async {
    final items = await _service.getDetails();
    // null = serveur ancien sans cette route : on garde l'affichage par module
    if (items != null) details.assignAll(items);
  }

  Future<void> refresh() => _fetchStatus();

  Future<void> triggerSync() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      final error = await _service.triggerSync();
      if (error == null) {
        SnackbarHelper.success('sync_success'.tr);
      } else {
        SnackbarHelper.error(error);
      }
      await _fetchStatus();
    } finally {
      isSyncing.value = false;
    }
  }

  bool get isType3 => status.value?.isType3 ?? false;
  int get pendingCount => status.value?.pendingCount ?? 0;
}
