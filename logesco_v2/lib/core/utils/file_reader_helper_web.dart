import 'dart:typed_data';

/// Sur web, on ne peut pas lire depuis un path — retourner null.
/// FilePicker.bytes doit être utilisé directement.
Future<Uint8List?> readFileFromPath(String path) async {
  return null;
}
