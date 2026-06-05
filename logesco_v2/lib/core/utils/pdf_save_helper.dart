import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Imports conditionnels web vs desktop/mobile
import 'pdf_save_helper_web.dart' if (dart.library.io) 'pdf_save_helper_io.dart' as platform;

/// Sauvegarde un PDF et l'ouvre automatiquement.
/// - Web     : déclenche un téléchargement navigateur
/// - Desktop : écrit dans Documents et ouvre avec le lecteur PDF par défaut
Future<String> savePdfAndOpen(Uint8List bytes, String fileName) async {
  if (kIsWeb) {
    return platform.savePdfAndOpen(bytes, fileName);
  }
  return platform.savePdfAndOpen(bytes, fileName);
}
