import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/license.dart';
import '../../models/client.dart';
import '../../core/services/database_service.dart';

class LicensesPage extends ConsumerStatefulWidget {
  const LicensesPage({super.key});

  @override
  ConsumerState<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends ConsumerState<LicensesPage> {
  List<License> _licenses = [];
  Map<String, Client> _clientsMap = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final licenses = await DatabaseService.instance.getLicenses();
      final clients = await DatabaseService.instance.getClients();
      setState(() {
        _licenses = licenses;
        _clientsMap = {for (final c in clients) c.id: c};
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

  List<License> get _filteredLicenses {
    if (_searchQuery.isEmpty) return _licenses;
    final q = _searchQuery.toLowerCase();
    return _licenses.where((l) {
      final client = _clientsMap[l.clientId];
      final clientName = client?.name.toLowerCase() ?? '';
      final company = client?.company.toLowerCase() ?? '';
      return clientName.contains(q) || company.contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(License license, Client? client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la licence'),
        content: Text(
          'Voulez-vous vraiment supprimer la licence de ${client?.name ?? license.clientId} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseService.instance.deleteLicense(license.id);
      setState(() => _licenses.removeWhere((l) => l.id == license.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Licence supprimée'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLicenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Licences'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher par nom de client...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.key_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty ? 'Aucune licence' : 'Aucun résultat',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              if (_searchQuery.isEmpty) ...[
                                Text(
                                  'Commencez par générer une licence',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => context.go('/licenses/new'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Générer une licence'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final license = filtered[index];
                            final client = _clientsMap[license.clientId];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(license.status),
                                  child: Icon(_getStatusIcon(license.status), color: Colors.white),
                                ),
                                title: Text(client?.name ?? license.clientId),
                                subtitle: Text(
                                  '${license.typeLabel} · Expire: ${license.expiresAt.day}/${license.expiresAt.month}/${license.expiresAt.year}',
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
                                      tooltip: 'Voir les détails',
                                      onPressed: () => _viewLicense(license, client),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Supprimer',
                                      onPressed: () => _confirmDelete(license, client),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
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

  void _viewLicense(License license, Client? client) {
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
                _buildDetailRow('Client', client != null ? '${client.name} (${client.company})' : license.clientId),
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
                _buildCopyableBlock('Clé de licence', license.licenseKey, context),
                const SizedBox(height: 16),
                _buildCopyableBlock('Empreinte appareil', license.deviceFingerprint, context),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(license, client);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableBlock(String label, String value, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copié'), duration: const Duration(seconds: 2)),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copier'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueGrey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueGrey[700]!, width: 1),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white, height: 1.5),
          ),
        ),
      ],
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
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
