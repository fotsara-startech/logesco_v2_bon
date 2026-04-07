import 'package:logesco_v2/core/utils/snackbar_helper.dart';

class SnackbarUtils {
  static void showSuccess(String message) {
    SnackbarHelper.success(message, duration: const Duration(seconds: 3));
  }

  static void showError(String message) {
    SnackbarHelper.error(message, duration: const Duration(seconds: 4));
  }

  static void showWarning(String message) {
    SnackbarHelper.warning(message, duration: const Duration(seconds: 3));
  }

  static void showInfo(String message) {
    SnackbarHelper.info(message, title: 'Information', duration: const Duration(seconds: 3));
  }
}
