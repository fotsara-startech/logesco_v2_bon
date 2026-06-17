import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/backend_service.dart' if (dart.library.html) '../../../core/services/backend_service_stub.dart';
import '../../../core/config/app_config.dart';
import '../../boutiques/controllers/boutique_controller.dart';

/// Page de démarrage — attend le backend (mode serveur) ou va directement au login (mode client)
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthController _authController = Get.put(AuthController());
  String _statusMessage = '';
  double _progress = 0.0; // 0.0 → 1.0

  @override
  void initState() {
    super.initState();
    _startupSequence();
  }

  Future<void> _startupSequence() async {
    // MODE CLIENT ou WEB — pas de backend local, connexion directe au serveur distant
    if (AppConfig.isClientMode || kIsWeb) {
      _setStatus('Connexion au serveur...');
      _setProgress(0.5);
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final isAuthenticated = await _authController.checkAuthentication();
        _setProgress(1.0);
        if (isAuthenticated) {
          _loadBoutiquesAfterAuth();
          Get.offAllNamed(AppRoutes.dashboard);
        } else {
          Get.offAllNamed(AppRoutes.login);
        }
      } catch (_) {
        Get.offAllNamed(AppRoutes.login);
      }
      return;
    }

    // MODE SERVEUR — attendre que le backend local soit prêt
    _setStatus('Démarrage du serveur...');
    _setProgress(0.1);

    final backend = BackendService();
    if (!backend.isRunning && !await backend.checkHealth()) {
      final ready = await _waitBackendWithProgress(backend);
      if (!ready) {
        Get.offAllNamed(AppRoutes.login);
        return;
      }
    }

    _setProgress(0.9);
    _setStatus('Vérification de la session...');
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final isAuthenticated = await _authController.checkAuthentication();
      _setProgress(1.0);
      if (isAuthenticated) {
        _loadBoutiquesAfterAuth();
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (_) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  /// Charge les boutiques après authentification réussie
  void _loadBoutiquesAfterAuth() {
    try {
      Get.find<BoutiqueController>().loadBoutiques();
    } catch (_) {}
  }

  /// Attend le backend avec messages progressifs et polling adaptatif
  Future<bool> _waitBackendWithProgress(BackendService backend) async {
    const maxSeconds = 120;
    final deadline = DateTime.now().add(const Duration(seconds: maxSeconds));
    int elapsed = 0;

    while (DateTime.now().isBefore(deadline)) {
      // Messages progressifs selon le temps écoulé
      if (elapsed < 5) {
        _setStatus('Démarrage du serveur...');
      } else if (elapsed < 20) {
        _setStatus('Chargement en cours...');
      } else if (elapsed < 50) {
        _setStatus('Initialisation de la base de données...');
      } else if (elapsed < 80) {
        _setStatus('Première installation — préparation des données...');
      } else {
        _setStatus('Finalisation, encore quelques instants...');
      }

      // Barre de progression simulée (0.1 → 0.85 sur 120s)
      _setProgress(0.1 + (elapsed / maxSeconds) * 0.75);

      // Polling adaptatif : rapide au début, espacé ensuite
      final delay = elapsed < 10 ? const Duration(milliseconds: 500) : const Duration(seconds: 1);

      await Future.delayed(delay);
      elapsed += (delay.inMilliseconds / 1000).round();

      if (backend.isRunning || await backend.checkHealth()) {
        return true;
      }
    }
    return false;
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
  }

  void _setProgress(double value) {
    if (mounted) setState(() => _progress = value.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/img/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.store, size: 60, color: Color(0xFF1976D2)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'LOGESCO v2',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  color: Colors.white,
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
