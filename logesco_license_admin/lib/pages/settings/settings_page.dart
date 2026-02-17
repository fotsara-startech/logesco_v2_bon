import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Sécurité
            _buildSectionCard(
              'Sécurité',
              Icons.security,
              [
                _buildPasswordChangeForm(),
                const SizedBox(height: 16),
                _buildSecurityInfo(),
              ],
            ),
            const SizedBox(height: 24),

            // Section Base de données
            _buildSectionCard(
              'Base de données',
              Icons.storage,
              [
                _buildDatabaseInfo(),
                const SizedBox(height: 16),
                _buildDatabaseActions(),
              ],
            ),
            const SizedBox(height: 24),

            // Section Application
            _buildSectionCard(
              'Application',
              Icons.settings,
              [
                _buildAppInfo(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordChangeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Changer le mot de passe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _currentPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe actuel',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nouveau mot de passe',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirmer le nouveau mot de passe',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isChangingPassword ? null : _changePassword,
          child: _isChangingPassword
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Changer le mot de passe'),
        ),
      ],
    );
  }

  Widget _buildSecurityInfo() {
    final securityStats = AuthService.instance.getSecurityStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations de sécurité',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Statut de connexion', securityStats['isLoggedIn'] ? 'Connecté' : 'Déconnecté'),
        _buildInfoRow('Dernière connexion', securityStats['lastLogin'] ?? 'Jamais'),
        _buildInfoRow('Mot de passe modifié', securityStats['passwordChanged'] ? 'Oui' : 'Non (par défaut)'),
      ],
    );
  }

  Widget _buildDatabaseInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations de la base de données',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<Map<String, int>>(
          future: DatabaseService.instance.getStatistics(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stats = snapshot.data!;
              return Column(
                children: [
                  _buildInfoRow('Clients totaux', stats['totalClients'].toString()),
                  _buildInfoRow('Licences totales', stats['totalLicenses'].toString()),
                  _buildInfoRow('Licences actives', stats['activeLicenses'].toString()),
                  _buildInfoRow('Licences expirées', stats['expiredLicenses'].toString()),
                ],
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      ],
    );
  }

  Widget _buildDatabaseActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions de maintenance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _exportDatabase,
              icon: const Icon(Icons.download),
              label: const Text('Exporter'),
            ),
            OutlinedButton.icon(
              onPressed: _showResetDialog,
              icon: const Icon(Icons.warning),
              label: const Text('Réinitialiser'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations de l\'application',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Version', '1.0.0'),
        _buildInfoRow('Plateforme', 'Flutter'),
        _buildInfoRow('Base de données', 'SQLite'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final success = await AuthService.instance.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSuccessSnackBar('Mot de passe modifié avec succès');
      } else {
        _showErrorSnackBar('Mot de passe actuel incorrect');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du changement de mot de passe: $e');
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  void _exportDatabase() {
    // TODO: Implémenter l'export de la base de données
    _showInfoSnackBar('Fonctionnalité d\'export en cours de développement');
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser la base de données'),
        content: const Text(
          'Cette action supprimera toutes les données (clients et licences). '
          'Cette action est irréversible. Êtes-vous sûr de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetDatabase();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _resetDatabase() {
    // TODO: Implémenter la réinitialisation de la base de données
    _showInfoSnackBar('Fonctionnalité de réinitialisation en cours de développement');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
