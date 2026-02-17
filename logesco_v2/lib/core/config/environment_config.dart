import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration d'environnement adaptative pour le déploiement hybride
class EnvironmentConfig {
  /// Détecte si l'application fonctionne en mode local
  static bool get isLocal => !kIsWeb && Platform.isWindows && _hasLocalAPI();

  /// Détecte si l'application fonctionne en mode web
  static bool get isWeb => kIsWeb;

  /// Détecte si l'application fonctionne en mode desktop
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// URL de base de l'API selon l'environnement
  static String get apiBaseUrl {
    if (isLocal) {
      return 'http://localhost:8080/api/v1';
    } else if (isWeb) {
      return 'http://localhost:8080/api/v1';
    } else {
      return _getConfiguredUrl();
    }
  }

  /// Type de base de données selon l'environnement
  static DatabaseType get dbType {
    return isLocal ? DatabaseType.sqlite : DatabaseType.postgresql;
  }

  /// Nom de l'application
  static String get appName => 'LOGESCO v2';

  /// Version de l'application
  static String get appVersion => '2.0.0';

  /// Timeout par défaut pour les requêtes API (en secondes)
  static int get apiTimeout => 30;

  /// Durée de session par défaut (en minutes)
  static int get sessionDuration => 30;

  /// Vérifie si l'API locale est disponible
  static bool _hasLocalAPI() {
    // TODO: Implémenter la vérification de disponibilité de l'API locale
    // Pour l'instant, on assume qu'elle est disponible en mode local
    return true;
  }

  /// Récupère l'URL configurée pour les environnements personnalisés
  static String _getConfiguredUrl() {
    // TODO: Implémenter la lecture de configuration personnalisée
    return 'http://localhost:8080/api/v1';
  }
}

/// Types de base de données supportés
enum DatabaseType {
  sqlite,
  postgresql,
}
