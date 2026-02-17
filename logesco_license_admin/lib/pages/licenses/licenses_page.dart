import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/license.dart';
import '../../core/services/database_service.dart';

class LicensesPage extends ConsumerStatefulWidget {
  const LicensesPage({super.key});

  @override
  ConsumerState<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends ConsumerState<LicensesPage> {
  List<License> _licenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    setState(() => _isLoading = true);
    try {
      final licenses = await DatabaseService.instance.getLicenses();
      setState(() {
        _licenses = licenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licences'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLicenses,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _licenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.key_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune licence',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Commencez par générer une licence',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/licenses/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Générer une licence'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _licenses.length,
                  itemBuilder: (context, index) {
                    final license = _licenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(license.status),
                          child: Icon(
                            _getStatusIcon(license.status),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(license.typeLabel),
                        subtitle: Text(
                          'Expire: ${license.expiresAt.day}/${license.expiresAt.month}/${license.expiresAt.year}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(license.statusLabel),
                              backgroundColor: _getStatusColor(license.status).withOpacity(0.2),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _viewLicense(license),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/licenses/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return Colors.green;
      case LicenseStatus.expired:
        return Colors.orange;
      case LicenseStatus.revoked:
        return Colors.red;
      case LicenseStatus.suspended:
        return Colors.yellow;
    }
  }

  IconData _getStatusIcon(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.active:
        return Icons.check_circle;
      case LicenseStatus.expired:
        return Icons.warning;
      case LicenseStatus.revoked:
        return Icons.block;
      case LicenseStatus.suspended:
        return Icons.pause_circle;
    }
  }

  void _viewLicense(License license) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de la licence'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', license.typeLabel),
                _buildDetailRow('Statut', license.statusLabel),
                _buildDetailRow('Client ID', license.clientId),
                _buildDetailRow(
                  'Émise le',
                  '${license.issuedAt.day}/${license.issuedAt.month}/${license.issuedAt.year}',
                ),
                _buildDetailRow(
                  'Expire le',
                  '${license.expiresAt.day}/${license.expiresAt.month}/${license.expiresAt.year}',
                ),
                if (license.price != null) _buildDetailRow('Prix', '${license.price!.toStringAsFixed(2)} ${license.currency}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Clé de licence:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: license.licenseKey));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clé copiée dans le presse-papiers'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copier'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueGrey[700]!, width: 1),
                  ),
                  child: SelectableText(
                    license.licenseKey,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
