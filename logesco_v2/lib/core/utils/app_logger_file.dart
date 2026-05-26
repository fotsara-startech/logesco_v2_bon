/// Implémentation native (mobile/desktop) des opérations fichier pour AppLogger
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File?> initLogFile() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return File('${logDir.path}/app_${DateTime.now().millisecondsSinceEpoch}.log');
  } catch (_) {
    return null;
  }
}

void writeToFile(File? logFile, String line) {
  try {
    logFile?.writeAsStringSync(line, mode: FileMode.append);
  } catch (_) {}
}

Future<void> cleanupOldLogFiles(int maxDays) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (await logDir.exists()) {
      final files = await logDir.list().toList();
      final cutoff = DateTime.now().subtract(Duration(days: maxDays));
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoff)) await file.delete();
        }
      }
    }
  } catch (_) {}
}

Future<int> getLogFilesSize() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (await logDir.exists()) {
      int total = 0;
      await for (final file in logDir.list()) {
        if (file is File) total += (await file.stat()).size;
      }
      return total;
    }
  } catch (_) {}
  return 0;
}

Future<List<Object>> exportLogFiles() async {
  final logs = <File>[];
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (await logDir.exists()) {
      await for (final file in logDir.list()) {
        if (file is File && file.path.endsWith('.log')) logs.add(file);
      }
    }
  } catch (_) {}
  return logs;
}
