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
    if (result != null) status.value = result;
  }

  Future<void> refresh() => _fetchStatus();

  Future<void> triggerSync() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      final ok = await _service.triggerSync();
      if (ok) {
        SnackbarHelper.success('sync_success'.tr);
        await _fetchStatus();
      } else {
        SnackbarHelper.error('sync_failed'.tr);
      }
    } finally {
      isSyncing.value = false;
    }
  }

  bool get isType3 => status.value?.isType3 ?? false;
  int get pendingCount => status.value?.pendingCount ?? 0;
}
