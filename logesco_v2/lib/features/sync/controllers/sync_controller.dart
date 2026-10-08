import 'dart:async';
import 'package:get/get.dart';
import '../services/sync_status_service.dart';
import '../../../core/utils/snackbar_helper.dart';

class SyncController extends GetxController {
  final SyncStatusService _service = SyncStatusService();

  final Rx<SyncStatus?> status = Rx<SyncStatus?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSyncing = false.obs;

  Timer? _pollTimer;
  bool _staleWarned = false;

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
    }
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
