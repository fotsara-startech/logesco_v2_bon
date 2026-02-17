import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/loading_widget.dart';

/// Page de démarrage avec vérification de l'authentification
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthController _authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Attendre un peu pour l'effet splash
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Vérifier l'authentification avec validation du token
      final isAuthenticated = await _authController.checkAuthentication();

      if (isAuthenticated) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      // En cas d'erreur, aller vers la page de login
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de l'application
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
              child: const Icon(
                Icons.store,
                size: 60,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 32),

            // Nom de l'application
            const Text(
              'LOGESCO v2',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Sous-titre
            const Text(
              'Système de gestion commerciale',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 48),

            // Indicateur de chargement
            const LoadingWidget(
              color: Colors.white,
              message: 'Initialisation...',
            ),
          ],
        ),
      ),
    );
  }
}
