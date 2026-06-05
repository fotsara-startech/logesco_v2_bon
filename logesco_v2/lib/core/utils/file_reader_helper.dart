import 'dart:typed_data';

// Imports conditionnels
import 'file_reader_helper_web.dart' if (dart.library.io) 'file_reader_helper_io.dart' as platform;

/// Lit un fichier depuis un chemin (desktop) ou retourne null (web).
/// Sur web, utiliser bytes directement depuis FilePicker.
Future<Uint8List?> readFileFromPath(String path) async {
  return platform.readFileFromPath(path);
}
