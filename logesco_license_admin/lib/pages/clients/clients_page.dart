import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../core/services/database_service.dart';
import '../../models/client.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  List<Client> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);

    try {
      final clients = await DatabaseService.instance.getClients(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: true,
      );

      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteClient(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le client'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le client "${client.name}" ?\n\n'
          'Cette action supprimera également toutes ses licences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.instance.deleteClient(client.id);
        await _loadClients();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des clients'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un client...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _loadClients();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/clients/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau client'),
                ),
              ],
            ),
          ),

          // Liste des clients
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clients.isEmpty
                    ? _buildEmptyState()
                    : _buildClientsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Aucun client enregistré' : 'Aucun client trouvé',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? 'Commencez par ajouter votre premier client' : 'Essayez avec d\'autres termes de recherche',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () => context.go('/clients/new'),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un client'),
            ),
        ],
      ),
    );
  }

  Widget _buildClientsTable() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 800,
        columns: const [
          DataColumn2(
            label: Text('Nom'),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text('Entreprise'),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text('Email'),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: Text('Créé le'),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: Text('Actions'),
            size: ColumnSize.S,
          ),
        ],
        rows: _clients
            .map((client) => DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        client.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(Text(client.company)),
                    DataCell(Text(client.email)),
                    DataCell(
                      Text(DateFormat('dd/MM/yyyy').format(client.createdAt)),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.key),
                            onPressed: () => context.go('/licenses/new?clientId=${client.id}'),
                            tooltip: 'Générer une licence',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.go('/clients/edit/${client.id}'),
                            tooltip: 'Modifier',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteClient(client),
                            tooltip: 'Supprimer',
                          ),
                        ],
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
