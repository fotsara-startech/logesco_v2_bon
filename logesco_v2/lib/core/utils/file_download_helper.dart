import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Imports conditionnels
import 'file_download_helper_web.dart' if (dart.library.io) 'file_download_helper_io.dart' as platform;

/// Utilitaire unifié pour sauvegarder/télécharger des fichiers
/// - Sur web : déclenche un téléchargement navigateur via dart:html
/// - Sur desktop/mobile : écrit dans getApplicationDocumentsDirectory
class FileDownloadHelper {
  /// Sauvegarde des bytes dans un fichier.
  /// Retourne le chemin du fichier sur desktop, ou le nom du fichier sur web.
  static Future<String> saveFile({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    return platform.saveFile(bytes: bytes, fileName: fileName, mimeType: mimeType);
  }

  /// Retourne true si on est sur web
  static bool get isWeb => kIsWeb;
}
