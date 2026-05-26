/// Stub web de BackendService — aucune fonctionnalité (dart:io non disponible sur web)
class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  bool get isRunning => false;
  int get port => 8080;
  String get baseUrl => 'http://localhost:8080';

  Future<bool> initialize() async => false;
  Future<bool> waitUntilReady({int maxSeconds = 120}) async => false;
  Future<void> stop() async {}
  Future<bool> checkHealth() async => false;
  Future<void> dispose() async {}
}
