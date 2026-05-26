import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

// Imports conditionnels pour dart:io (non disponible sur web)
import 'app_logger_file.dart' if (dart.library.html) 'app_logger_file_stub.dart' as file_logger;

/// Système de logging centralisé pour l'application LOGESCO
class AppLogger {
  static const String _appTag = 'LOGESCO';
  static Object? _logFile; // File sur native, null sur web

  /// Initialise le système de logging
  static Future<void> initialize() async {
    if (!kDebugMode) {
      _logFile = await file_logger.initLogFile();
    }
  }

  static void info(String message, {String? tag, Map<String, dynamic>? data}) => _log('INFO', message, tag: tag, data: data);

  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag, Map<String, dynamic>? data}) =>
      _log('ERROR', message, tag: tag, data: data, error: error, stackTrace: stackTrace);

  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (kDebugMode) _log('DEBUG', message, tag: tag, data: data);
  }

  static void warning(String message, {String? tag, Map<String, dynamic>? data}) => _log('WARNING', message, tag: tag, data: data);

  static void audit(String action, {String? userId, Map<String, dynamic>? details}) {
    _log('AUDIT', 'User action: $action', tag: 'AUDIT', data: {
      'action': action,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      ...?details,
    });
  }

  static void performance(String operation, Duration duration, {Map<String, dynamic>? data}) {
    _log('PERFORMANCE', 'Operation: $operation took ${duration.inMilliseconds}ms', tag: 'PERFORMANCE', data: {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    });
  }

  static void navigation(String from, String to, {Map<String, dynamic>? data}) {
    _log('NAVIGATION', 'Navigation: $from -> $to', tag: 'NAVIGATION', data: {
      'from': from,
      'to': to,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    });
  }

  static void api(String method, String endpoint, int statusCode, Duration duration, {Map<String, dynamic>? data}) {
    final level = statusCode >= 400 ? 'ERROR' : 'INFO';
    _log(level, 'API: $method $endpoint -> $statusCode (${duration.inMilliseconds}ms)', tag: 'API', data: {
      'method': method,
      'endpoint': endpoint,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    });
  }

  static void security(String event, {Map<String, dynamic>? data}) {
    _log('SECURITY', 'Security event: $event', tag: 'SECURITY', data: {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      ...?data,
    });
  }

  static void _log(String level, String message, {String? tag, Map<String, dynamic>? data, dynamic error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag ?? _appTag;

    if (kDebugMode) {
      developer.log(message, name: logTag, time: DateTime.now(), level: _getLevelValue(level), error: error, stackTrace: stackTrace);
      if (data != null) developer.log('Data: $data', name: logTag, time: DateTime.now());
    }

    if (!kDebugMode && _logFile != null) {
      final logEntry = {
        'timestamp': timestamp,
        'level': level,
        'tag': logTag,
        'message': message,
        if (data != null) 'data': data,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };
      file_logger.writeToFile(_logFile as dynamic, '${logEntry.toString()}\n');
    }
  }

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
      case 'SECURITY':
        return 950;
      default:
        return 800;
    }
  }

  static Future<void> cleanupOldLogs({int maxDays = 7}) async {
    if (kDebugMode) return;
    await file_logger.cleanupOldLogFiles(maxDays);
  }

  static Future<int> getLogSize() async {
    if (kDebugMode) return 0;
    return file_logger.getLogFilesSize();
  }

  static Future<List<Object>> exportLogs() async {
    return file_logger.exportLogFiles();
  }
}
