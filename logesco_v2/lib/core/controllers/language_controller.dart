import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import '../translations/app_translations.dart';

/// Contrôleur pour la gestion de la langue de l'application
class LanguageController extends GetxController {
  final _storage = GetStorage();

  // Langue actuelle (fr ou en)
  final currentLanguage = 'fr'.obs;

  @override
  void onInit() {
    super.onInit();
    // Charger la langue sauvegardée
    final savedLanguage = _storage.read('app_language') ?? 'fr';
    currentLanguage.value = savedLanguage;
  }

  /// Changer la langue de l'application
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == currentLanguage.value) return;

    try {
      // Sauvegarder la préférence
      await _storage.write('app_language', languageCode);

      // Mettre à jour la langue
      currentLanguage.value = languageCode;

      // Changer la locale de GetX
      await AppTranslations.changeLanguage(languageCode);

      // Afficher un message de succès
      String message;
      switch (languageCode) {
        case 'fr':
          message = 'La langue a été changée en Français';
          break;
        case 'en':
          message = 'Language changed to English';
          break;
        case 'es':
          message = 'Idioma cambiado a Español';
          break;
        default:
          message = 'Language changed';
      }

      final context = Get.context;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final context = Get.context;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_unknown'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Obtenir le nom de la langue actuelle
  String get currentLanguageName {
    switch (currentLanguage.value) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Français';
    }
  }

  /// Obtenir le drapeau de la langue actuelle
  String get currentLanguageFlag {
    switch (currentLanguage.value) {
      case 'fr':
        return '';
      case 'en':
        return '';
      case 'es':
        return '';
      default:
        return '';
    }
  }
}
