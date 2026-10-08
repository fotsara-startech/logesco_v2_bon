import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Journal des décisions de licence, écrit dans un fichier texte.
///
/// Sert à expliquer a posteriori un blocage "licence expirée / aucun
/// abonnement" : la vérification est entièrement locale et ne laissait
/// jusqu'ici aucune trace de ce qu'elle avait lu ni de pourquoi elle avait
/// conclu à un refus.
///
/// Emplacement : %LOCALAPPDATA%\LOGESCO\logs\license.log
/// Aucun secret n'est écrit (ni clé de licence, ni empreinte complète).
/// Toutes les méthodes sont sans risque : une erreur d'écriture est ignorée,
/// et l'écriture ne retarde jamais la vérification de licence.
class LicenseLog {
  LicenseLog._();

  static const int _maxBytes = 512 * 1024;
  static File? _file;
  static bool _initFailed = false;
  static Future<void> _queue = Future.value();

  /// Pour les tests : dossier de destination à la place de %LOCALAPPDATA%\LOGESCO\logs
  @visibleForTesting
  static String? overrideDirectory;

  /// Pour les tests : attend la fin des écritures en cours
  @visibleForTesting
  static Future<void> flush() => _queue;

  @visibleForTesting
  static void reset() {
    _file = null;
    _initFailed = false;
  }

  /// Chemin du fichier (utile pour l'afficher à l'utilisateur / au support)
  static String? get path => _resolve()?.path;

  /// Écrit une ligne `2026-10-08 12:49:50.123 [source] message`
  static void log(String source, String message) {
    final line = '${_stamp(DateTime.now())} [$source] $message\n';
    // Écritures mises en file : ordre garanti, jamais d'attente côté appelant
    _queue = _queue.then((_) => _append(line)).catchError((_) {});
  }

  /// Variante pour les erreurs : ajoute le type de l'exception
  static void error(String source, String message, Object e) {
    log(source, '$message — ${e.runtimeType}: $e');
  }

  static File? _resolve() {
    if (_file != null) return _file;
    if (_initFailed) return null;
    try {
      final base = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['TEMP'] ?? Directory.systemTemp.path;
      final dir = Directory(overrideDirectory ?? '$base${Platform.pathSeparator}LOGESCO${Platform.pathSeparator}logs');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      _file = File('${dir.path}${Platform.pathSeparator}license.log');
      return _file;
    } catch (_) {
      _initFailed = true;
      return null;
    }
  }

  static Future<void> _append(String line) async {
    final f = _resolve();
    if (f == null) return;
    try {
      // Rotation simple : on garde l'ancien fichier en .1
      if (f.existsSync() && f.lengthSync() > _maxBytes) {
        final old = File('${f.path}.1');
        if (old.existsSync()) old.deleteSync();
        f.renameSync(old.path);
      }
      await f.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (_) {
      // journal indisponible : sans conséquence pour la licence
    }
  }

  static String _stamp(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}.${d.millisecond.toString().padLeft(3, '0')}';
  }
}
