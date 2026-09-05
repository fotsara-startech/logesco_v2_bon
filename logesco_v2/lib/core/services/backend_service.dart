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
///
/// IMPORTANT — Gestion des noms d'utilisateur Windows avec caractères
/// spéciaux (accents, apostrophes, espaces, ex: "André jean d'arc") :
/// Ces chemins passent sous %LOCALAPPDATA%\...\backend. Si on les écrit
/// tels quels (texte) dans le CONTENU des .cmd/.vbs générés, cmd.exe et
/// wscript.exe les relisent avec la page de code OEM/ANSI du système —
/// jamais l'UTF-8 utilisé par Dart pour écrire le fichier — et tout
/// caractère accentué est silencieusement corrompu à la lecture : le
/// "cd /d" échoue et node.exe ne démarre jamais (ou dans le mauvais
/// dossier), sans erreur visible. C'est reproductible même avec la page
/// de code active réglée sur UTF-8 (65001) : le parseur de fichiers .bat
/// de cmd.exe ne respecte pas cette page de code pour son propre texte.
///
/// Une première tentative de correctif convertissait ces chemins en
/// "chemins courts" Windows 8.3 (ex: ANDR~1), garantis ASCII pur. Elle
/// s'est révélée insuffisante : la génération des noms courts 8.3 est
/// désactivée par défaut sur de nombreuses machines (clé de registre
/// NtfsDisable8dot3NameCreation=1, réglage courant sur images
/// d'entreprise/SSD) — auquel cas aucun nom court n'existe et le bug
/// d'origine revient tel quel.
///
/// La solution retenue : ne plus jamais écrire de chemin dynamique
/// (potentiellement accentué) comme texte DANS le contenu d'un .cmd/.vbs.
/// Les scripts _logesco_start.cmd/.vbs sont désormais 100% statiques et
/// ASCII pur (aucune interpolation), et lisent les chemins depuis les
/// variables d'environnement du processus enfant — transmises via
/// Process.start(environment: {...}), donc via CreateProcessW en
/// UTF-16 natif, sans jamais passer par un décodage texte/page de code.
/// Ce mécanisme fonctionne quel que soit le nom Windows de l'utilisateur
/// et indépendamment du réglage 8.3 de la machine (vérifié manuellement
/// sur un dossier "André jean d'arc" avec noms courts désactivés).
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

  /// Contenu statique du lanceur .cmd — jamais d'interpolation de chemin ici.
  /// Tous les chemins dynamiques sont lus depuis l'environnement du process,
  /// hérité via Process.start(environment: {...}) (Unicode natif).
  static const String _startCmdTemplate =
      '@echo off\r\n'
      'cd /d "%LOGESCO_BACKEND_DIR%"\r\n'
      'set "LOGESCO_DATA_DIR=%LOGESCO_BACKEND_DIR%"\r\n'
      'set "PORT=%LOGESCO_PORT%"\r\n'
      'set "NODE_ENV=production"\r\n'
      'set "DATABASE_URL=%LOGESCO_DB_URL%"\r\n'
      '"%LOGESCO_NODE_EXE%" "%LOGESCO_SERVER_JS%"\r\n';

  /// Contenu statique du lanceur .vbs — lit le chemin du .cmd depuis
  /// l'environnement (clé LOGESCO_CMD_FILE) plutôt que de l'interpoler.
  static const String _startVbsTemplate =
      'Set WshShell = CreateObject("WScript.Shell")\r\n'
      'Set WshEnv = WshShell.Environment("PROCESS")\r\n'
      'cmdFile = WshEnv("LOGESCO_CMD_FILE")\r\n'
      'WshShell.Run "cmd.exe /C " & Chr(34) & cmdFile & Chr(34), 0, False\r\n';

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

  // Nombre d'échecs de /health consécutifs avant de considérer le backend
  // vraiment mort. Une requête lourde (ex: calcul d'alertes de stock sur un
  // gros catalogue) peut bloquer la boucle d'événements Node quelques
  // secondes sans que le process soit mort pour autant — le tuer dans ce
  // cas coupe la connexion de la requête en cours (voir _healthTimeout).
  int _consecutiveHealthFailures = 0;
  static const int _maxConsecutiveHealthFailures = 3;
  static const Duration _healthTimeout = Duration(seconds: 5);

  /// Watchdog de fond — vérifie le health toutes les 15s et relance si mort
  void _startWatchdog() {
    if (_watchdogActive) return;
    _watchdogActive = true;
    _consecutiveHealthFailures = 0;
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_isRestarting) return;
      final alive = await checkHealth();
      if (!alive) {
        _consecutiveHealthFailures++;
        if (_isRunning) {
          // Premier échec détecté → ouvrir le circuit breaker immédiatement
          // (retire les erreurs visibles côté UI), mais on ne relance PAS
          // encore : ça peut être une requête lente, pas un backend mort.
          _isRunning = false;
          _markBackendDown();
          debugPrint('⚠️ Watchdog: /health ne répond pas ($_consecutiveHealthFailures/$_maxConsecutiveHealthFailures)...');
        }
        if (_consecutiveHealthFailures >= _maxConsecutiveHealthFailures && !_isRestarting) {
          _watchdogActive = false;
          _watchdogTimer?.cancel();
          debugPrint('🔴 Watchdog: backend considéré mort — relance...');
          await restart();
        }
      } else {
        _consecutiveHealthFailures = 0;
        if (!_isRunning) {
          // Backend répond de nouveau sans qu'on l'ait relancé (cas rare)
          _isRunning = true;
          _markBackendUp();
        }
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
      final client = HttpClient()..connectionTimeout = _healthTimeout;
      final req = await client.getUrl(Uri.parse('$baseUrl/health'));
      final res = await req.close().timeout(_healthTimeout);
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
      debugPrint('📁 Création du dossier database...');
      dbDir.createSync(recursive: true);
    }

    // Créer le dossier logs s'il n'existe pas
    final logsDir = Directory(p.join(_backendDir, 'logs'));
    if (!logsDir.existsSync()) {
      debugPrint('📁 Création du dossier logs...');
      logsDir.createSync(recursive: true);
    }

    // Copier la base template si la base n'existe pas
    final dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      final templateDb = File(p.join(_backendDir, 'database', 'logesco_template.db'));
      if (templateDb.existsSync()) {
        debugPrint('📋 Copie de la base de données template...');
        try {
          templateDb.copySync(dbPath);
          debugPrint('✅ Base de données initialisée depuis le template');
        } catch (e) {
          debugPrint('⚠️ Échec copie template: $e');
        }
      } else {
        debugPrint('⚠️ Template de base de données introuvable, sera créé au démarrage');
      }
    }

    // Toujours recréer le fichier .env avec le bon chemin absolu
    // pour éviter les problèmes de chemins relatifs.
    // NOTE: ce fichier est lu par Node.js (dotenv), qui gère nativement
    // l'UTF-8 et les chemins Unicode sous Windows — pas de risque ici.
    try {
      envFile.writeAsStringSync(
        'NODE_ENV=production\n'
        'PORT=8080\n'
        'DATABASE_URL=$dbUrl\n'
        'JWT_SECRET=logesco-secret-${DateTime.now().millisecondsSinceEpoch}\n'
        'JWT_EXPIRES_IN=365d\n'
        'CORS_ORIGIN=*\n'
        'LOG_LEVEL=info\n'
        'LOGESCO_DATA_DIR=$_backendDir\n',
      );
      debugPrint('✅ Fichier .env créé/mis à jour');
    } catch (e) {
      debugPrint('⚠️ Échec création .env: $e');
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
      debugPrint('   backend dir: $backendDir');
      debugPrint('   node: $nodeExe');
      debugPrint('   server: $serverJs');
      debugPrint('   database: $dbPath');

      // Vérifier que node.exe existe
      if (!File(nodeExe).existsSync() && nodeExe != 'node') {
        debugPrint('❌ Node.exe introuvable: $nodeExe');
        return false;
      }

      // Vérifier que le client Prisma est généré
      final prismaClient = p.join(backendDir, 'node_modules', '.prisma', 'client', 'index.js');
      if (!File(prismaClient).existsSync()) {
        debugPrint('⚠️ Client Prisma non généré, génération en cours...');
        try {
          final result = await Process.run(
            nodeExe,
            [p.join(backendDir, 'node_modules', 'prisma', 'build', 'index.js'), 'generate'],
            workingDirectory: backendDir,
            runInShell: false,
          );
          if (result.exitCode == 0) {
            debugPrint('✅ Client Prisma généré');
          } else {
            debugPrint('⚠️ Génération Prisma échouée: ${result.stderr}');
          }
        } catch (e) {
          debugPrint('⚠️ Impossible de générer Prisma: $e');
        }
      }

      // Créer le dossier database s'il n'existe pas
      final dbDir = Directory(p.join(backendDir, 'database'));
      if (!dbDir.existsSync()) {
        debugPrint('📁 Création du dossier database...');
        dbDir.createSync(recursive: true);
      }

      // Copier le template si la base n'existe pas
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        final templateDb = File(p.join(backendDir, 'database', 'logesco_template.db'));
        if (templateDb.existsSync()) {
          debugPrint('📋 Copie du template de base de données...');
          templateDb.copySync(dbPath);
        } else {
          debugPrint('ℹ️ Template absent, la base sera créée au démarrage');
        }
      }

      // ─── Écriture des lanceurs (contenu 100% statique, voir doc de classe) ──
      final dbUrl = 'file:$dbPath';
      final cmdPath = p.join(backendDir, '_logesco_start.cmd');
      final vbsPath = p.join(backendDir, '_logesco_start.vbs');
      File(cmdPath).writeAsStringSync(_startCmdTemplate);
      File(vbsPath).writeAsStringSync(_startVbsTemplate);
      debugPrint('📝 Scripts CMD/VBS (statiques) écrits dans $backendDir');

      // Lancer le .vbs via wscript.exe en mode détaché ; tous les chemins
      // dynamiques (potentiellement accentués) passent par l'environnement
      // du processus enfant, jamais par le contenu texte des scripts.
      // ProcessStartMode.detached = aucun handle stdin/stdout hérité de Flutter.
      await Process.start(
        'wscript.exe',
        [vbsPath],
        workingDirectory: backendDir,
        mode: ProcessStartMode.detached,
        runInShell: false,
        environment: {
          'LOGESCO_CMD_FILE': cmdPath,
          'LOGESCO_BACKEND_DIR': backendDir,
          'LOGESCO_NODE_EXE': nodeExe,
          'LOGESCO_SERVER_JS': serverJs,
          'LOGESCO_DB_URL': dbUrl,
          'LOGESCO_PORT': '$_port',
        },
      );

      debugPrint('🚀 wscript lancé, attente health check...');
      _isRunning = await _poll(maxSeconds: 60);

      if (_isRunning) {
        debugPrint('✅ Backend prêt sur $baseUrl');
        _markBackendUp();
        _startWatchdog();
      } else {
        debugPrint('❌ Backend non disponible après 60s');
        // Lire les logs pour diagnostiquer
        await _readStartupLogs(backendDir);
      }
      return _isRunning;
    } catch (e, stack) {
      debugPrint('❌ Erreur démarrage backend: $e');
      debugPrint('   Stack: $stack');
      return false;
    }
  }

  /// Lit et affiche les derniers logs de démarrage pour diagnostic
  Future<void> _readStartupLogs(String backendDir) async {
    try {
      final logFile = File(p.join(backendDir, 'logs', 'backend-startup.log'));
      if (logFile.existsSync()) {
        final content = await logFile.readAsString();
        final lines = content.split('\n');
        final lastLines = lines.length > 30 ? lines.sublist(lines.length - 30) : lines;
        debugPrint('📋 Derniers logs du backend:');
        for (final line in lastLines) {
          if (line.trim().isNotEmpty) {
            debugPrint('   $line');
          }
        }
      } else {
        debugPrint('⚠️ Fichier de log introuvable');
      }
    } catch (e) {
      debugPrint('⚠️ Impossible de lire les logs: $e');
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
