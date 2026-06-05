import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

/// Implémentation desktop/mobile : écriture dans Documents + ouverture automatique
Future<String> savePdfAndOpen(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
  try {
    await OpenFile.open(filePath);
  } catch (_) {
    // Ouverture automatique non critique
  }
  return filePath;
}
