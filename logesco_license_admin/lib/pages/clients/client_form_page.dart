import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/database_service.dart';
import '../../models/client.dart';

class ClientFormPage extends StatefulWidget {
  final String? clientId;

  const ClientFormPage({
    super.key,
    this.clientId,
  });

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  Client? _existingClient;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.clientId != null;
    if (_isEditing) {
      _loadClient();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);

    try {
      final client = await DatabaseService.instance.getClient(widget.clientId!);
      if (client != null) {
        setState(() {
          _existingClient = client;
          _nameController.text = client.name;
          _emailController.text = client.email;
          _companyController.text = client.company;
          _phoneController.text = client.phone ?? '';
          _addressController.text = client.address ?? '';
          _notesController.text = client.notes ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final client = Client(
        id: _existingClient?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        company: _companyController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: _existingClient?.createdAt ?? now,
        updatedAt: now,
        isActive: true,
      );

      if (_isEditing) {
        await DatabaseService.instance.updateClient(client);
      } else {
        await DatabaseService.instance.insertClient(client);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Client modifié avec succès' : 'Client créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/clients');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le client' : 'Nouveau client'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/clients'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations du client',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Nom
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet *',
                            hintText: 'Jean Dupont',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le nom est obligatoire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            hintText: 'jean.dupont@entreprise.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'L\'email est obligatoire';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Format d\'email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Entreprise
                        TextFormField(
                          controller: _companyController,
                          decoration: const InputDecoration(
                            labelText: 'Entreprise *',
                            hintText: 'Nom de l\'entreprise',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le nom de l\'entreprise est obligatoire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Téléphone
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            hintText: '+33 1 23 45 67 89',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Adresse
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse',
                            hintText: '123 Rue de la Paix, 75001 Paris',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            hintText: 'Notes internes sur le client...',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        // Boutons d'action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/clients'),
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveClient,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(_isEditing ? 'Modifier' : 'Créer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
