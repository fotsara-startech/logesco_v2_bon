import 'dart:io';
import 'dart:typed_data';

/// Sur desktop, lire le fichier depuis le path.
Future<Uint8List?> readFileFromPath(String path) async {
  try {
    final file = File(path);
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}
