import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Système de logging centralisé pour l'application LOGESCO
class AppLogger {
  static const String _appTag = 'LOGESCO';
  static AppLogger? _instance;
  static File? _logFile;

  AppLogger._();

  static AppLogger get instance {
    _instance ??= AppLogger._();
    return _instance!;
  }

  /// Initialise le système de logging
  static Future<void> initialize() async {
    if (!kDebugMode) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final logDir = Directory('${directory.path}/logs');

        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }

        _logFile = File('${logDir.path}/app_${DateTime.now().millisecondsSinceEpoch}.log');
      } catch (e) {
        developer.log('Failed to initialize log file: $e', name: _appTag);
      }
    }
  }

  /// Log d'information
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log('INFO', message, tag: tag, data: data);
  }

  /// Log d'erreur
  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag, Map<String, dynamic>? data}) {
    _log('ERROR', message, tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  /// Log de débogage
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag, data: data);
    }
  }

  /// Log d'avertissement
  static void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log('WARNING', message, tag: tag, data: data);
  }

  /// Log d'audit pour les actions utilisateur
  static void audit(String action, {String? userId, Map<String, dynamic>? details}) {
    final auditData = {
      'action': action,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?details,
    };

    _log('AUDIT', 'User action: $action', tag: 'AUDIT', data: auditData);
  }

  /// Log de performance
  static void performance(String operation, Duration duration, {Map<String, dynamic>? data}) {
    final perfData = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    };

    _log('PERFORMANCE', 'Operation: $operation took ${duration.inMilliseconds}ms', tag: 'PERFORMANCE', data: perfData);
  }

  /// Log de navigation
  static void navigation(String from, String to, {Map<String, dynamic>? data}) {
    final navData = {
      'from': from,
      'to': to,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    };

    _log('NAVIGATION', 'Navigation: $from -> $to', tag: 'NAVIGATION', data: navData);
  }

  /// Log d'API
  static void api(String method, String endpoint, int statusCode, Duration duration, {Map<String, dynamic>? data}) {
    final apiData = {
      'method': method,
      'endpoint': endpoint,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    };

    final level = statusCode >= 400 ? 'ERROR' : 'INFO';
    _log(level, 'API: $method $endpoint -> $statusCode (${duration.inMilliseconds}ms)', tag: 'API', data: apiData);
  }

  /// Log de sécurité
  static void security(String event, {Map<String, dynamic>? data}) {
    final securityData = {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    };

    _log('SECURITY', 'Security event: $event', tag: 'SECURITY', data: securityData);
  }

  /// Méthode interne de logging
  static void _log(
    String level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag ?? _appTag;

    // Log vers la console en développement
    if (kDebugMode) {
      developer.log(
        message,
        name: logTag,
        time: DateTime.now(),
        level: _getLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );

      if (data != null) {
        developer.log(
          'Data: ${data.toString()}',
          name: logTag,
          time: DateTime.now(),
        );
      }
    }

    // Log vers fichier en production
    if (!kDebugMode && _logFile != null) {
      _writeToFile(timestamp, level, logTag, message, data, error, stackTrace);
    }
  }

  /// Écrit dans le fichier de log
  static void _writeToFile(
    String timestamp,
    String level,
    String tag,
    String message,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    try {
      final logEntry = {
        'timestamp': timestamp,
        'level': level,
        'tag': tag,
        'message': message,
        if (data != null) 'data': data,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };

      final logLine = '${logEntry.toString()}\n';
      _logFile?.writeAsStringSync(logLine, mode: FileMode.append);
    } catch (e) {
      // Éviter les boucles infinies en cas d'erreur de logging
      developer.log('Failed to write to log file: $e', name: _appTag);
    }
  }

  /// Convertit le niveau de log en valeur numérique
  static int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      case 'AUDIT':
        return 850;
      case 'PERFORMANCE':
        return 750;
      case 'NAVIGATION':
        return 700;
      case 'API':
        return 800;
      case 'SECURITY':
        return 950;
      default:
        return 800;
    }
  }

  /// Nettoie les anciens fichiers de log
  static Future<void> cleanupOldLogs({int maxDays = 7}) async {
    if (kDebugMode) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (await logDir.exists()) {
        final files = await logDir.list().toList();
        final cutoffDate = DateTime.now().subtract(Duration(days: maxDays));

        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await file.delete();
              info('Deleted old log file: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      error('Failed to cleanup old logs', error: e);
    }
  }

  /// Obtient la taille totale des logs
  static Future<int> getLogSize() async {
    if (kDebugMode) return 0;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (await logDir.exists()) {
        final files = await logDir.list().toList();
        int totalSize = 0;

        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            totalSize += stat.size;
          }
        }

        return totalSize;
      }
    } catch (e) {
      error('Failed to get log size', error: e);
    }

    return 0;
  }

  /// Exporte les logs pour le support technique
  static Future<List<File>> exportLogs() async {
    final logs = <File>[];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (await logDir.exists()) {
        final files = await logDir.list().toList();

        for (final file in files) {
          if (file is File && file.path.endsWith('.log')) {
            logs.add(file);
          }
        }
      }
    } catch (e) {
      error('Failed to export logs', error: e);
    }

    return logs;
  }
}
