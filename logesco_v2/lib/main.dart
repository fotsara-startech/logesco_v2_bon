import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/bindings/initial_bindings.dart';
import 'core/routes/app_pages.dart';
import 'core/config/app_config.dart';
import 'core/services/app_initialization_service.dart';
import 'core/services/backend_service.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/error_handler.dart';
import 'core/translations/app_translations.dart';

import 'shared/themes/app_theme.dart';

void main() async {
  // Assure que les widgets Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise le système de logging
  await AppLogger.initialize();
  AppLogger.info('Application LOGESCO v2 starting...');

  // Initialise GetStorage
  await GetStorage.init();
  AppLogger.info('GetStorage initialized');

  // Initialise et démarre le backend embarqué
  final backendService = BackendService();
  final backendStarted = await backendService.initialize();
  if (backendStarted) {
    AppLogger.info('Backend service started successfully');
  } else {
    AppLogger.warning('Backend service failed to start - running in offline mode');
  }

  // Nettoie les anciens logs
  await AppLogger.cleanupOldLogs();

  // Configure la gestion d'erreurs globale
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  AppLogger.info('Application LOGESCO v2 started successfully');
  runApp(const LogescoApp());
}

/// Application principale LOGESCO v2
class LogescoApp extends StatelessWidget {
  const LogescoApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ LogescoApp build appelé');

    // Récupérer la langue sauvegardée
    final storage = GetStorage();
    final savedLanguage = storage.read('app_language') ?? 'fr';

    Locale locale;
    switch (savedLanguage) {
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

    return GetMaterialApp(
      // Configuration de base
      title: 'LOGESCO v2',
      debugShowCheckedModeBanner: false,

      // Thème de l'application
      theme: AppTheme.lightTheme,

      // Configuration des traductions GetX
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: AppTranslations.fallbackLocale,

      // Configuration des localisations Flutter
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppTranslations.supportedLocales,

      // Configuration des routes
      initialRoute: AppConfig.initialRoute,
      getPages: AppPages.pages,

      // Injection de dépendances initiale
      initialBinding: InitialBindings(),

      // Configuration par défaut
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      // Gestion des erreurs de route
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => Scaffold(
          body: Center(
            child: Text('page_not_found'.tr),
          ),
        ),
      ),

      // Initialisation post-bindings
      onInit: () async {
        AppLogger.info('Application LOGESCO v2 initialized');

        // Initialiser l'application (vérifier admin, etc.)
        try {
          final initService = Get.find<AppInitializationService>();
          await initService.initialize();
          initService.showAppStatus();
          AppLogger.info('App initialization service completed');
        } catch (e) {
          AppLogger.error('Error during app initialization', error: e);
          ErrorHandler.showError(e, context: 'App Initialization');
        }
      },
    );
  }
}
