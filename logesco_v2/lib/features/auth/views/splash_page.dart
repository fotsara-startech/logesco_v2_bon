import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/backend_service.dart';

/// Page de démarrage — attend le backend puis vérifie l'authentification.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthController _authController = Get.put(AuthController());
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _startupSequence();
  }

  Future<void> _startupSequence() async {
    _setStatus('Démarrage du serveur...');

    // Attendre que le backend soit prêt (max 120s — migration incluse)
    final backend = BackendService();
    if (!backend.isRunning && !await backend.checkHealth()) {
      // Afficher un message d'attente progressif
      int elapsed = 0;
      final timer = Stream.periodic(const Duration(seconds: 5)).listen((_) {
        elapsed += 5;
        if (elapsed < 30) {
          _setStatus('Démarrage du serveur...');
        } else if (elapsed < 60) {
          _setStatus('Initialisation de la base de données...');
        } else {
          _setStatus('Première installation, veuillez patienter...');
        }
      });

      final ready = await backend.waitUntilReady(maxSeconds: 120);
      timer.cancel();

      if (!ready) {
        // Backend indisponible — aller au login qui affichera le bouton Réessayer
        Get.offAllNamed(AppRoutes.login);
        return;
      }
    }

    _setStatus('Vérification de la session...');
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final isAuthenticated = await _authController.checkAuthentication();
      if (isAuthenticated) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (_) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusMessage = msg);
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
                    color: Colors.black.withOpacity(0.1),
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
          ],
        ),
      ),
    );
  }
}
