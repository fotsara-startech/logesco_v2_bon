import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/widgets/loading_widget.dart';

/// Page de connexion
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // En mode client, le backend est toujours "prêt" (c'est le serveur distant)
  bool _backendReady = AppConfig.isClientMode;
  String _backendStatus = AppConfig.isClientMode ? '' : 'Démarrage du serveur...';

  @override
  void initState() {
    super.initState();
    if (!AppConfig.isClientMode) {
      _waitForBackend();
    }
  }

  Future<void> _waitForBackend() async {
    final backend = BackendService();
    if (backend.isRunning || await backend.checkHealth()) {
      if (mounted) setState(() => _backendReady = true);
      return;
    }
    final ready = await backend.waitUntilReady(maxSeconds: 60);
    if (mounted) {
      setState(() {
        _backendReady = ready;
        _backendStatus = ready ? '' : 'Serveur indisponible.';
      });
    }
  }

  Future<void> _restartBackend() async {
    setState(() {
      _backendReady = false;
      _backendStatus = 'Redémarrage du serveur...';
    });
    final backend = BackendService();
    await backend.stop();
    await backend.initialize();
    final ready = await backend.waitUntilReady(maxSeconds: 60);
    if (mounted) {
      setState(() {
        _backendReady = ready;
        _backendStatus = ready ? '' : 'Échec du démarrage. Vérifiez l\'installation.';
      });
    }
  }

  Future<void> _diagnose() async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final serverBase = AppConfig.currentBaseUrl.replaceAll('/api/v1', '');
      final req = await client.getUrl(Uri.parse('$serverBase/debug'));
      final res = await req.close().timeout(const Duration(seconds: 5));
      final body = await res.transform(const Utf8Decoder()).join();
      client.close();
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Diagnostic Backend'),
            content: SingleChildScrollView(
              child: SelectableText(body, style: const TextStyle(fontSize: 11)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Backend inaccessible'),
            content: SelectableText('Erreur: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authController.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (success) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() => LoadingOverlay(
              isLoading: _authController.isLoading.value,
              loadingMessage: 'auth_logging_in'.tr,
              child: Stack(
                children: [
                  _buildLoginForm(context),
                  // Bannière de statut backend — uniquement en mode serveur
                  if (!AppConfig.isClientMode && !_backendReady)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: (_backendStatus.contains('Échec') || _backendStatus.contains('indisponible')) ? Colors.red.shade700 : Theme.of(context).primaryColor.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_backendStatus.contains('Échec') && !_backendStatus.contains('indisponible')) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                _backendStatus,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (_backendStatus.contains('Échec') || _backendStatus.contains('indisponible'))
                              TextButton.icon(
                                onPressed: _restartBackend,
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                                label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'auth_username_label'.tr,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'auth_username_required'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'auth_password_label'.tr,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth_password_required'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Obx(() {
                  if (_authController.errorMessage.value.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _authController.errorMessage.value,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                ElevatedButton(
                  onPressed: _backendReady ? _handleLogin : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _backendReady ? 'auth_login_button'.tr : 'Démarrage...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildVersionInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/img/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.store, size: 40, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'LOGESCO v2',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'auth_login_subtitle'.tr,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Column(
      children: [
        Center(
          child: Text(
            '${'auth_version'.tr} 2.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
        ),
        if (!AppConfig.isClientMode)
          TextButton(
            onPressed: _diagnose,
            child: const Text('Diagnostiquer', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
      ],
    );
  }
}
