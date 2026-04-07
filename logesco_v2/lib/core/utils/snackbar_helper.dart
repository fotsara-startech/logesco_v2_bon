import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Clé globale pour ScaffoldMessenger — à passer à GetMaterialApp.scaffoldMessengerKey
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Utilitaire centralisé pour afficher des snackbars de façon sûre depuis
/// n'importe où (controllers, services, middlewares).
/// Utilise rootScaffoldMessengerKey au lieu de Get.snackbar() qui crashe
/// quand l'Overlay n'est pas encore monté.
class SnackbarHelper {
  static void success(String message, {String? title, Duration? duration}) {
    _show(
      title: title ?? 'common_success'.tr,
      message: message,
      backgroundColor: Colors.green.shade700,
      duration: duration,
    );
  }

  static void error(String message, {String? title, Duration? duration}) {
    _show(
      title: title ?? 'common_error'.tr,
      message: message,
      backgroundColor: Colors.red.shade700,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  static void warning(String message, {String? title, Duration? duration}) {
    _show(
      title: title ?? 'warning'.tr,
      message: message,
      backgroundColor: Colors.orange.shade700,
      duration: duration,
    );
  }

  static void info(String message, {String? title, Duration? duration}) {
    _show(
      title: title ?? 'common_info'.tr,
      message: message,
      backgroundColor: Colors.blue.shade700,
      duration: duration,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            if (message.isNotEmpty) Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
