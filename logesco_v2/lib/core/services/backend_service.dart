import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Gère le cycle de vie du backend Node.js embarqué.
///
/// Le backend est installé dans:
///   %LOCALAPPDATA%\LOGESCO\backend\
///     node.exe        → Node.js portable
///     src\server.js   → Code source backend
///     node_modules\   → Dépendances
///     database\       → SQLite (données persistantes)
///
/// Stratégie de démarrage sur Windows (app sans console) :
///   1. Écrire un .vbs qui lance node.exe sans fenêtre (windowStyle=0)
///   2. Lancer ce .vbs via wscript.exe en mode détaché
///   3. Attendre que /health réponde (polling toutes les secondes)
class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  bool _isRunning = false;
  bool _watchdogActive = false;
  bool _isRestarting = false;
  Timer? _watchdogTimer;
  final int _port = 8080;

  // ─── Circuit breaker ───────────────────────────────────────────────────────
  // Quand true, ApiClient sait que le backend est down et supprime les
  // snackbars d'erreur répétées. Remis à false dès que /health répond à nouveau.
  bool _backendDown = false;
  bool get isBackendDown => _backendDown;

  // Callback optionnel appelé quand le backend est restauré
  // Injecté par main.dart pour afficher un toast discret
  void Function()? onBackendRestored;

  bool get isRunning => _isRunning;
  int get port => _port;
  String get baseUrl => 'http://localhost:$_port';

  /// Marque le backend comme actif (appelé depuis le lifecycle observer)
  void markRunning() {
    _isRunning = true;
    _markBackendUp();
  }

  void _markBackendDown() {
    if (_backendDown) return;
    _backendDown = true;
    debugPrint('🔴 BackendService: circuit breaker OUVERT (backend down)');
  }

  void _markBackendUp() {
    if (!_backendDown) return;
    _backendDown = false;
    debugPrint('🟢 BackendService: circuit breaker FERMÉ (backend up)');
    try {
      onBackendRestored?.call();
    } catch (_) {}
  }

  // ═══ Chemins ═══════════════════════════════════════════════════════════════

  String get _backendDir {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? p.join(Platform.environment['USERPROFILE'] ?? r'C:\Users\Default', 'AppData', 'Local');
    return p.join(localAppData, 'LOGESCO', 'backend');
  }

  String get _nodeExe {
    final portable = p.join(_backendDir, 'node.exe');
    if (File(portable).existsSync()) return portable;
    for (final c in [
      r'C:\Program Files\nodejs\node.exe',
      r'C:\Program Files (x86)\nodejs\node.exe',
    ]) {
      if (File(c).existsSync()) return c;
    }
    return 'node';
  }

  String get _serverJs => p.join(_backendDir, 'src', 'server.js');

  // ═══ API publique ══════════════════════════════════════════════════════════

  Future<bool> initialize() async {
    debugPrint('🚀 BackendService: initialisation...');

    if (!Platform.isWindows) {
      debugPrint('⚠️ Plateforme non supportée');
      return false;
    }

    if (await checkHealth()) {
      debugPrint('✅ Backend déjà en cours sur $baseUrl');
      _isRunning = true;
      _startWatchdog();
      return true;
    }

    if (!File(_serverJs).existsSync()) {
      debugPrint('❌ Backend introuvable: $_serverJs');
      return false;
    }

    _ensureEnvFile();
    _start(); // non-awaité → l'app attend via waitUntilReady
    return true;
  }

  /// Redémarre le backend silencieusement (watchdog ou veille)
  Future<bool> restart() async {
    if (_isRestarting) return false;
    _isRestarting = true;
    debugPrint('🔄 BackendService: redémarrage...');
    _isRunning = false;
    try {
      await Process.run('taskkill', ['/F', '/IM', 'node.exe'], runInShell: true);
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 500));
    _ensureEnvFile();
    final ok = await _start();
    if (ok) {
      _startWatchdog();
      _markBackendUp();
    }
    _isRestarting = false;
    return ok;
  }

  /// Watchdog de fond — vérifie le health toutes les 15s et relance si mort
  void _startWatchdog() {
    if (_watchdogActive) return;
    _watchdogActive = true;
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_isRestarting) return;
      final alive = await checkHealth();
      if (!alive) {
        if (_isRunning) {
          // Premier échec détecté → ouvrir le circuit breaker immédiatement
          _isRunning = false;
          _markBackendDown();
          debugPrint('⚠️ Watchdog: backend mort — relance silencieuse...');
        }
        if (!_isRestarting) {
          _watchdogActive = false;
          _watchdogTimer?.cancel();
          await restart();
        }
      } else if (!_isRunning) {
        // Backend répond de nouveau sans qu'on l'ait relancé (cas rare)
        _isRunning = true;
        _markBackendUp();
      }
    });
  }

  Future<bool> waitUntilReady({int maxSeconds = 60}) async {
    if (_isRunning) return true;
    for (int i = 0; i < maxSeconds; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isRunning) return true;
      if (await checkHealth()) {
        _isRunning = true;
        return true;
      }
    }
    return false;
  }

  Future<void> stop() async {
    debugPrint('🛑 BackendService: arrêt via taskkill...');
    _watchdogTimer?.cancel();
    _watchdogActive = false;
    try {
      await Process.run('taskkill', ['/F', '/IM', 'node.exe'], runInShell: true);
    } catch (_) {}
    _isRunning = false;
    debugPrint('✅ Backend arrêté');
  }

  Future<bool> checkHealth() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final req = await client.getUrl(Uri.parse('$baseUrl/health'));
      final res = await req.close().timeout(const Duration(seconds: 2));
      client.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ═══ Privé ═════════════════════════════════════════════════════════════════

  void _ensureEnvFile() {
    final envFile = File(p.join(_backendDir, '.env'));
    final dbDir = Directory(p.join(_backendDir, 'database'));
    final dbPath = p.join(_backendDir, 'database', 'logesco.db').replaceAll('\\', '/');
    final dbUrl = 'file:$dbPath';

    // Créer le dossier database s'il n'existe pas
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    // Copier la base template si la base n'existe pas
    final dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      final templateDb = File(p.join(_backendDir, 'database', 'logesco_template.db'));
      if (templateDb.existsSync()) {
        debugPrint('📋 Copie de la base de données template...');
        templateDb.copySync(dbPath);
        debugPrint('✅ Base de données initialisée depuis le template');
      } else {
        debugPrint('⚠️  Template de base de données introuvable, sera créé au démarrage');
      }
    }

    if (envFile.existsSync()) {
      var content = envFile.readAsStringSync();
      if (content.contains('DATABASE_URL=file:./') || content.contains('DATABASE_URL=file:.\\')) {
        content = content.replaceAll(RegExp(r'DATABASE_URL=file:[^\n]+'), 'DATABASE_URL=$dbUrl');
        envFile.writeAsStringSync(content);
      }
    } else {
      envFile.writeAsStringSync(
        'NODE_ENV=production\n'
        'PORT=8080\n'
        'DATABASE_URL=$dbUrl\n'
        'JWT_SECRET=logesco-secret-${DateTime.now().millisecondsSinceEpoch}\n'
        'JWT_EXPIRES_IN=365d\n'
        'CORS_ORIGIN=*\n'
        'LOG_LEVEL=info\n',
      );
    }
  }

  Future<bool> _start() async {
    if (_isRunning) return true;

    try {
      final backendDir = _backendDir;
      final nodeExe = _nodeExe;
      final serverJs = _serverJs;
      final dbPath = p.join(backendDir, 'database', 'logesco.db').replaceAll('\\', '/');

      debugPrint('⚙️ Démarrage backend via wscript + cmd...');
      debugPrint('   node: $nodeExe');
      debugPrint('   server: $serverJs');

      // Étape 1 : générer un .cmd avec les variables d'env + appel node.
      // Les SET dans un .cmd sont hérités par les processus enfants.
      final cmdPath = p.join(backendDir, '_logesco_start.cmd');
      final cmdContent = [
        '@echo off',
        'SET LOGESCO_DATA_DIR=$backendDir',
        'SET PORT=$_port',
        'SET NODE_ENV=production',
        'SET DATABASE_URL=file:$dbPath',
        '"$nodeExe" "$serverJs"',
      ].join('\r\n');
      File(cmdPath).writeAsStringSync(cmdContent);

      // Étape 2 : générer un .vbs qui lance ce .cmd sans fenêtre console.
      // WshShell.Run avec windowStyle=0 et bWaitOnReturn=False = invisible + non-bloquant.
      // NOTE: WshShell.Environment("PROCESS") n'est PAS hérité par les enfants →
      //       c'est pourquoi on passe par un .cmd intermédiaire avec SET.
      final vbsPath = p.join(backendDir, '_logesco_start.vbs');
      final vbsContent = [
        'Set WshShell = CreateObject("WScript.Shell")',
        'Dim cmd',
        'cmd = "cmd.exe /C " & Chr(34) & "$cmdPath" & Chr(34)',
        'WshShell.Run cmd, 0, False',
      ].join('\r\n');
      File(vbsPath).writeAsStringSync(vbsContent);

      // Étape 3 : lancer le .vbs via wscript.exe en mode détaché.
      // ProcessStartMode.detached = aucun handle stdin/stdout hérité de Flutter.
      await Process.start(
        'wscript.exe',
        [vbsPath],
        workingDirectory: backendDir,
        mode: ProcessStartMode.detached,
        runInShell: false,
      );

      debugPrint('   wscript lancé, attente health check...');
      _isRunning = await _poll(maxSeconds: 60);

      if (_isRunning) {
        debugPrint('✅ Backend prêt sur $baseUrl');
        _markBackendUp();
        _startWatchdog();
      } else {
        debugPrint('❌ Backend non disponible après 60s');
      }
      return _isRunning;
    } catch (e) {
      debugPrint('❌ Erreur démarrage backend: $e');
      return false;
    }
  }

  Future<bool> _poll({int maxSeconds = 60}) async {
    final deadline = DateTime.now().add(Duration(seconds: maxSeconds));
    int attempt = 0;
    while (DateTime.now().isBefore(deadline)) {
      // Polling très rapide les 5 premières secondes (200ms),
      // puis 500ms, puis 1s après 20 tentatives
      final Duration delay;
      if (attempt < 25) {
        delay = const Duration(milliseconds: 200);
      } else if (attempt < 50) {
        delay = const Duration(milliseconds: 500);
      } else {
        delay = const Duration(seconds: 1);
      }
      await Future.delayed(delay);
      if (await checkHealth()) {
        debugPrint('   → Backend prêt après ~${attempt ~/ 5}s');
        return true;
      }
      attempt++;
    }
    return false;
  }

  Future<void> dispose() => stop();
}
