/// Stub web — toutes les opérations fichier sont des no-ops
Future<Object?> initLogFile() async => null;
void writeToFile(Object? logFile, String line) {}
Future<void> cleanupOldLogFiles(int maxDays) async {}
Future<int> getLogFilesSize() async => 0;
Future<List<Object>> exportLogFiles() async => [];
