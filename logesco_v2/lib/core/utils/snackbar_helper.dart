import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'friendly_error.dart';

/// Clé globale pour ScaffoldMessenger — à passer à GetMaterialApp.scaffoldMessengerKey
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Utilitaire centralisé pour afficher des snackbars de façon sûre depuis
/// n'importe où (controllers, services, middlewares).
/// Utilise rootScaffoldMessengerKey au lieu de Get.snackbar() qui crashe
/// quand l'Overlay n'est pas encore monté.
class SnackbarHelper {
  /// Derniers messages d'erreur affichés : un même message n'est pas répété en rafale
  static final Map<String, DateTime> _recents = {};
  static const Duration _delaiAntiDoublon = Duration(seconds: 6);

  /// true si ce message vient d'être affiché (plusieurs requêtes qui échouent ensemble produisaient la même erreur
  /// quatre fois de suite)
  static bool _estDoublonRecent(String message) {
    final maintenant = DateTime.now();
    _recents.removeWhere((_, quand) => maintenant.difference(quand) > _delaiAntiDoublon);
    if (_recents.containsKey(message)) return true;
    _recents[message] = maintenant;
    return false;
  }

  static void success(String message, {String? title, Duration? duration}) {
    _show(
      title: title ?? 'common_success'.tr,
      message: message,
      backgroundColor: Colors.green.shade700,
      duration: duration,
    );
  }

  static void error(String message, {String? title, Duration? duration}) {
    // Une erreur technique (« FormatException: SyntaxError... », « Failed to fetch... ») est traduite en explication claire
    final propre = FriendlyError.nettoyer(message);
    if (_estDoublonRecent(propre)) return;
    _show(
      title: title ?? 'common_error'.tr,
      message: propre,
      backgroundColor: Colors.red.shade700,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  static void warning(String message, {String? title, Duration? duration}) {
    final propre = FriendlyError.nettoyer(message);
    if (_estDoublonRecent(propre)) return;
    _show(
      title: title ?? 'warning'.tr,
      message: propre,
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
