import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Implémentation desktop/mobile : écriture dans Documents
Future<String> saveFile({
  required Uint8List bytes,
  required String fileName,
  String? mimeType,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
  return filePath;
}
