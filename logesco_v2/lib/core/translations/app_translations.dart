import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'fr_translations.dart';
import 'en_translations.dart';
import 'es_translations.dart';

/// Classe principale de gestion des traductions de l'application
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'fr_FR': frTranslations,
        'en_US': enTranslations,
        'es_ES': esTranslations,
      };

  /// Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  /// Langue par défaut
  static const Locale fallbackLocale = Locale('fr', 'FR');

  /// Obtenir la locale actuelle
  static Locale get currentLocale => Get.locale ?? fallbackLocale;

  /// Changer la langue de l'application
  static Future<void> changeLocale(Locale locale) async {
    await Get.updateLocale(locale);
  }

  /// Changer la langue par code (fr, en, es)
  static Future<void> changeLanguage(String languageCode) async {
    Locale locale;
    switch (languageCode) {
      case 'en':
        locale = const Locale('en', 'US');
        break;
      case 'es':
        locale = const Locale('es', 'ES');
        break;
      case 'fr':
      default:
        locale = const Locale('fr', 'FR');
        break;
    }
    await changeLocale(locale);
  }

  /// Obtenir le code de langue actuel (fr, en, es)
  static String get currentLanguageCode {
    final locale = currentLocale;
    return locale.languageCode;
  }
}
