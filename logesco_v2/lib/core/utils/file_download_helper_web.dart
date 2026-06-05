import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Implémentation web : téléchargement via dart:html
Future<String> saveFile({
  required Uint8List bytes,
  required String fileName,
  String? mimeType,
}) async {
  try {
    final mime = mimeType ?? _guessMime(fileName);
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    // Ajouter au DOM, cliquer, puis nettoyer
    html.document.body?.append(anchor);
    anchor.click();

    // Attendre un peu avant de nettoyer (permet au navigateur de traiter le téléchargement)
    await Future.delayed(const Duration(milliseconds: 100));
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return fileName;
  } catch (e) {
    print('❌ Erreur lors du téléchargement web: $e');
    rethrow;
  }
}

String _guessMime(String fileName) {
  if (fileName.endsWith('.pdf')) return 'application/pdf';
  if (fileName.endsWith('.xlsx')) return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  if (fileName.endsWith('.xls')) return 'application/vnd.ms-excel';
  if (fileName.endsWith('.csv')) return 'text/csv';
  return 'application/octet-stream';
}
