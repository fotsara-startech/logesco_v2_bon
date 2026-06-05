import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Implémentation web : téléchargement via dart:html
Future<String> savePdfAndOpen(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();

  await Future.delayed(const Duration(milliseconds: 100));
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return fileName;
}
