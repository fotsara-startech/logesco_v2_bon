import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'license_log.dart';

/// Copie DURABLE de la clé de licence, dans un fichier du dossier de données de l'utilisateur, hors du coffre de Windows.
///
/// Pourquoi : la licence est rangée dans le stockage sécurisé de Windows, qui répond parfois mal (accès simultanés au
/// fichier, lenteur, verrou d'antivirus) et peut être vidé par d'autres causes (profil Windows réinitialisé, outil de
/// nettoyage). Sans autre copie, la licence disparaissait et l'écran de blocage redemandait la clé.
///
/// Avec cette copie, la licence peut être RESTAURÉE seule : l'application revalide la clé de façon complète (signature,
/// appareil, expiration : exactement les contrôles d'une activation). Ce n'est donc pas un contournement : une clé expirée
/// ou liée à un autre appareil est refusée comme avant, et un fichier recopié sur un autre ordinateur ne vaut rien.
///
/// Emplacement : %LOCALAPPDATA%\LOGESCO\license\license.key
/// La clé n'est jamais écrite dans le journal de licence. Aucune méthode ne lève d'erreur.
class LicenseKeyBackup {
  /// Pour les tests : dossier de destination à la place de %LOCALAPPDATA%\LOGESCO\license
  @visibleForTesting
  static String? overrideDirectory;

  File? _fichier() {
    try {
      final base = Platform.environment['LOCALAPPDATA'] ?? Platform.environment['TEMP'] ?? Directory.systemTemp.path;
      final dir = Directory(overrideDirectory ?? '$base${Platform.pathSeparator}LOGESCO${Platform.pathSeparator}license');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return File('${dir.path}${Platform.pathSeparator}license.key');
    } catch (_) {
      return null;
    }
  }

  /// Enregistre la clé (écriture atomique : fichier temporaire puis renommage, jamais un fichier à moitié écrit)
  Future<bool> save(String licenseKey) async {
    final f = _fichier();
    if (f == null || licenseKey.trim().isEmpty) return false;
    try {
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode({'cle': licenseKey.trim(), 'ecritLe': DateTime.now().toIso8601String()}), flush: true);
      await tmp.rename(f.path);
      return true;
    } catch (e) {
      LicenseLog.error('copie-cle', "écriture de la copie de la clé impossible", e);
      return false;
    }
  }

  /// Relit la clé (null si absente ou illisible)
  Future<String?> load() async {
    final f = _fichier();
    if (f == null) return null;
    try {
      if (!f.existsSync()) return null;
      final json = jsonDecode(await f.readAsString());
      final cle = (json is Map ? json['cle'] : null)?.toString().trim();
      return (cle == null || cle.isEmpty) ? null : cle;
    } catch (e) {
      LicenseLog.error('copie-cle', 'lecture de la copie de la clé impossible', e);
      return null;
    }
  }

  /// Supprime la copie (réinitialisation explicite de la licence uniquement)
  Future<void> clear() async {
    final f = _fichier();
    if (f == null) return;
    try {
      if (f.existsSync()) await f.delete();
      final tmp = File('${f.path}.tmp');
      if (tmp.existsSync()) await tmp.delete();
    } catch (_) {/* sans importance */}
  }
}
