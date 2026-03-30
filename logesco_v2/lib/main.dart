import 'package:flutter/material.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.initialize();
  AppLogger.info('Application LOGESCO v2 starting...');

  await GetStorage.init();
  AppLogger.info('GetStorage initialized');

  // Démarre le backend embarqué uniquement en mode serveur
  if (!AppConfig.isClientMode) {
    final backendService = BackendService();
    final backendStarted = await backendService.initialize();
    if (backendStarted) {
      AppLogger.info('Backend service started successfully');
    } else {
      AppLogger.warning('Backend service failed to start - running in offline mode');
    }
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(backendService));
  } else {
    AppLogger.info('Mode client — backend embarqué ignoré');
  }

  await AppLogger.cleanupOldLogs();

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

/// Arrête le backend proprement quand l'application se ferme (mode serveur uniquement)
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final BackendService _backend;
  _AppLifecycleObserver(this._backend);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _backend.stop();
    }
  }
}

/// Application principale LOGESCO v2
class LogescoApp extends StatelessWidget {
  const LogescoApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      title: 'LOGESCO v2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: AppTranslations.fallbackLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppTranslations.supportedLocales,
      initialRoute: AppConfig.initialRoute,
      getPages: AppPages.pages,
      initialBinding: InitialBindings(),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => Scaffold(
          body: Center(child: Text('page_not_found'.tr)),
        ),
      ),
      onInit: () async {
        AppLogger.info('Application LOGESCO v2 initialized');
        try {
          final initService = Get.find<AppInitializationService>();
          await initService.initialize();
          AppLogger.info('App initialization service completed');
        } catch (e) {
          AppLogger.error('Error during app initialization', error: e);
          ErrorHandler.showError(e, context: 'App Initialization');
        }
      },
    );
  }
}
