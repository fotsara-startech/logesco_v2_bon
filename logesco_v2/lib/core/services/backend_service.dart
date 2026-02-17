import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

/// Service pour gérer le backend Node.js embarqué
/// Lance automatiquement le serveur backend au démarrage de l'application
class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  Process? _backendProcess;
  bool _isRunning = false;
  int _port = 8080;
  String? _backendPath;

  bool get isRunning => _isRunning;
  int get port => _port;
  String get baseUrl => 'http://localhost:$_port';

  /// Initialise et démarre le backend
  Future<bool> initialize() async {
    try {
      debugPrint('🚀 Initialisation du backend LOGESCO...');

      // Obtenir le chemin d'installation
      _backendPath = await _getBackendPath();
      debugPrint('📁 Chemin backend: $_backendPath');

      // Vérifier si le backend existe
      if (!await _backendExists()) {
        debugPrint('❌ Backend non trouvé à: $_backendPath');
        debugPrint('⚠️ Le backend devrait être installé par l\'installeur.');
        debugPrint('⚠️ Réinstallez l\'application si le problème persiste.');
        return false;
      }

      // Démarrer le backend
      return await start();
    } catch (e) {
      debugPrint('❌ Erreur initialisation backend: $e');
      return false;
    }
  }

  /// Démarre le serveur backend
  Future<bool> start() async {
    if (_isRunning) {
      debugPrint('ℹ️ Backend déjà en cours d\'exécution');
      return true;
    }

    try {
      debugPrint('🔄 Démarrage du backend...');

      final backendExe = path.join(_backendPath!, 'logesco-backend.exe');

      // Vérifier que l'exécutable existe
      if (!await File(backendExe).exists()) {
        debugPrint('❌ Exécutable backend non trouvé: $backendExe');
        return false;
      }

      // Créer le fichier .env s'il n'existe pas
      await _ensureEnvFile();

      // Démarrer le processus
      _backendProcess = await Process.start(
        backendExe,
        [],
        workingDirectory: _backendPath,
        mode: ProcessStartMode.detached,
      );

      // Écouter les logs (optionnel)
      _backendProcess!.stdout.listen((data) {
        debugPrint('Backend: ${String.fromCharCodes(data)}');
      });

      _backendProcess!.stderr.listen((data) {
        debugPrint('Backend Error: ${String.fromCharCodes(data)}');
      });

      // Attendre que le serveur soit prêt
      _isRunning = await _waitForBackend();

      if (_isRunning) {
        debugPrint('✅ Backend démarré avec succès sur $baseUrl');
      } else {
        debugPrint('❌ Le backend n\'a pas pu démarrer');
      }

      return _isRunning;
    } catch (e) {
      debugPrint('❌ Erreur démarrage backend: $e');
      return false;
    }
  }

  /// Arrête le serveur backend
  Future<void> stop() async {
    if (!_isRunning || _backendProcess == null) {
      return;
    }

    try {
      debugPrint('🛑 Arrêt du backend...');
      _backendProcess!.kill();
      _isRunning = false;
      _backendProcess = null;
      debugPrint('✅ Backend arrêté');
    } catch (e) {
      debugPrint('❌ Erreur arrêt backend: $e');
    }
  }

  /// Redémarre le backend
  Future<bool> restart() async {
    await stop();
    await Future.delayed(const Duration(seconds: 2));
    return await start();
  }

  /// Vérifie si le backend répond
  Future<bool> checkHealth() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$baseUrl/'));
      final response = await request.close();
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Méthodes privées

  Future<String> _getBackendPath() async {
    if (Platform.isWindows) {
      // Utiliser AppData\Local\LOGESCO\backend pour éviter les problèmes de permissions
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? path.join(Platform.environment['USERPROFILE']!, 'AppData', 'Local');
      return path.join(localAppData, 'LOGESCO', 'backend');
    } else {
      throw UnsupportedError('Plateforme non supportée');
    }
  }

  Future<bool> _backendExists() async {
    final backendExe = path.join(_backendPath!, 'logesco-backend.exe');
    return await File(backendExe).exists();
  }

  Future<void> _extractBackend() async {
    try {
      debugPrint('📦 Extraction du backend depuis les assets...');

      // Créer le dossier de destination
      final backendDir = Directory(_backendPath!);
      if (!await backendDir.exists()) {
        await backendDir.create(recursive: true);
      }

      // Copier l'exécutable et les fichiers de config
      final filesToCopy = [
        'logesco-backend.exe',
        '.env.example',
        'schema.prisma',
        'README.txt',
      ];

      // Copier aussi le dossier node_modules (requis pour Prisma)
      final nodeModulesSource = path.join('assets', 'backend', 'node_modules');
      final nodeModulesTarget = path.join(_backendPath!, 'node_modules');

      // Vérifier si node_modules existe dans les assets
      debugPrint('📦 Vérification de node_modules...');

      // Copier chaque fichier depuis les assets
      for (final file in filesToCopy) {
        try {
          final assetPath = 'assets/backend/$file';
          final targetPath = path.join(_backendPath!, file);

          // Lire depuis les assets
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();

          // Écrire dans le dossier de destination
          await File(targetPath).writeAsBytes(bytes);
          debugPrint('✓ Copié: $file');
        } catch (e) {
          debugPrint('⚠️ Erreur copie $file: $e');
        }
      }

      // Créer les dossiers nécessaires
      final foldersToCreate = ['database', 'logs', 'uploads'];
      for (final folder in foldersToCreate) {
        final folderPath = path.join(_backendPath!, folder);
        final dir = Directory(folderPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          debugPrint('✓ Dossier créé: $folder');
        }
      }

      debugPrint('✅ Backend extrait avec succès');
    } catch (e) {
      debugPrint('❌ Erreur extraction backend: $e');
      rethrow;
    }
  }

  Future<void> _ensureEnvFile() async {
    final envFile = File(path.join(_backendPath!, '.env'));

    if (!await envFile.exists()) {
      debugPrint('📝 Création du fichier .env...');

      final dbPath = path.join(_backendPath!, 'database', 'logesco.db');
      final envContent = '''
NODE_ENV=production
PORT=$_port
DATABASE_URL=file:$dbPath
JWT_SECRET=${_generateSecret()}
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
API_VERSION=v1
CORS_ORIGIN=*
LOG_LEVEL=info
''';

      await envFile.writeAsString(envContent);
      debugPrint('✅ Fichier .env créé');
    }
  }

  String _generateSecret() {
    // Générer une clé secrète aléatoire
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.padRight(32, '0');
  }

  Future<bool> _waitForBackend({int maxAttempts = 30}) async {
    debugPrint('⏳ Attente du démarrage du backend...');

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 1));

      if (await checkHealth()) {
        debugPrint('✅ Backend prêt après ${i + 1} secondes');
        return true;
      }

      debugPrint('⏳ Tentative ${i + 1}/$maxAttempts...');
    }

    debugPrint('❌ Timeout: le backend n\'a pas démarré');
    return false;
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    await stop();
  }
}
