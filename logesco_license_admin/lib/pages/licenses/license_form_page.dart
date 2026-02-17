import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/license.dart';
import '../../models/client.dart';
import '../../core/services/database_service.dart';
import '../../core/services/license_generator_service.dart';

class LicenseFormPage extends StatefulWidget {
  final String? clientId;
  final String? licenseId;

  const LicenseFormPage({
    super.key,
    this.clientId,
    this.licenseId,
  });

  @override
  State<LicenseFormPage> createState() => _LicenseFormPageState();
}

class _LicenseFormPageState extends State<LicenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _deviceFingerprintController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;

  Client? _selectedClient;
  List<Client> _clients = [];
  SubscriptionType _selectedType = SubscriptionType.trial;
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));
  // Les fonctionnalités sont automatiquement toutes incluses selon les spécifications
  String _currency = 'EUR';

  // Fonctionnalités selon les spécifications LOGESCO
  final Map<String, String> _availableFeatures = {
    'full_inventory': 'Gestion complète de l\'inventaire',
    'sales': 'Module de ventes complet',
    'reports': 'Rapports et statistiques',
    'advanced_analytics': 'Analyses avancées et tableaux de bord',
    'cash_register': 'Gestion de caisse',
    'expense_management': 'Gestion des dépenses',
    'user_management': 'Gestion des utilisateurs',
    'role_management': 'Gestion des rôles et permissions',
    'backup_restore': 'Sauvegarde et restauration',
    'multi_device_sync': 'Synchronisation multi-appareils',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _deviceFingerprintController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les clients
      _clients = await DatabaseService.instance.getClients(isActive: true);

      // Si un clientId est fourni, le sélectionner
      if (widget.clientId != null) {
        _selectedClient = _clients.firstWhere(
          (c) => c.id == widget.clientId,
          orElse: () => _clients.first,
        );
      }

      // Si c'est une édition, charger la licence
      if (widget.licenseId != null) {
        _isEditMode = true;
        final license = await DatabaseService.instance.getLicense(widget.licenseId!);
        if (license != null) {
          _loadLicenseData(license);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadLicenseData(License license) {
    setState(() {
      _selectedClient = _clients.firstWhere((c) => c.id == license.clientId);
      _selectedType = license.type;
      _expiresAt = license.expiresAt;
      _deviceFingerprintController.text = license.deviceFingerprint;
      // Les fonctionnalités sont automatiquement toutes incluses
      _priceController.text = license.price?.toString() ?? '';
      _currency = license.currency ?? 'EUR';
      _notesController.text = license.notes ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier la licence' : 'Nouvelle licence'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? _buildEmptyState()
              : _buildForm(),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun client disponible',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Créez d\'abord un client avant de générer une licence',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/clients/new'),
            icon: const Icon(Icons.add),
            label: const Text('Créer un client'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations du client',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Client>(
                    value: _selectedClient,
                    decoration: const InputDecoration(
                      labelText: 'Client',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _clients.map((client) {
                      return DropdownMenuItem(
                        value: client,
                        child: Text('${client.name} (${client.company})'),
                      );
                    }).toList(),
                    onChanged: (client) {
                      setState(() => _selectedClient = client);
                    },
                    validator: (value) {
                      if (value == null) return 'Sélectionnez un client';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type de licence',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SubscriptionType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type d\'abonnement',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: SubscriptionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (type) {
                      setState(() {
                        _selectedType = type!;
                        _updateDefaultDuration();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durée et appareil',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date d\'expiration'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_expiresAt)),
                    trailing: const Icon(Icons.edit),
                    onTap: _selectExpirationDate,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _deviceFingerprintController,
                    decoration: InputDecoration(
                      labelText: 'Empreinte de l\'appareil',
                      prefixIcon: const Icon(Icons.fingerprint),
                      helperText: 'Identifiant unique de l\'appareil du client',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Générer une empreinte de test',
                            onPressed: () {
                              setState(() {
                                _deviceFingerprintController.text = LicenseGeneratorService.generateTempDeviceFingerprint();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copier l\'empreinte',
                            onPressed: _deviceFingerprintController.text.isEmpty
                                ? null
                                : () {
                                    Clipboard.setData(
                                      ClipboardData(text: _deviceFingerprintController.text),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Empreinte copiée'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Saisissez l\'empreinte de l\'appareil';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'IMPORTANT: L\'empreinte doit correspondre EXACTEMENT à celle de l\'appareil du client. Demandez au client de vous fournir son empreinte depuis l\'application LOGESCO.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Fonctionnalités',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Toutes les licences donnent accès à toutes les fonctionnalités',
                        child: Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Accès complet à toutes les fonctionnalités',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableFeatures.entries.map((entry) {
                            return Chip(
                              avatar: const Icon(Icons.check, size: 16, color: Colors.green),
                              label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.white,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarification',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Prix',
                            prefixIcon: Icon(Icons.euro),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: const InputDecoration(
                            labelText: 'Devise',
                          ),
                          items: ['EUR', 'USD', 'GBP', 'XAF'].map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _currency = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes additionnelles',
                      prefixIcon: Icon(Icons.note),
                      hintText: 'Informations supplémentaires...',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _saveLicense,
                icon: const Icon(Icons.save),
                label: Text(_isEditMode ? 'Mettre à jour' : 'Générer la licence'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return 'Essai (7 jours) - Accès complet';
      case SubscriptionType.monthly:
        return 'Mensuel (30 jours) - Accès complet';
      case SubscriptionType.annual:
        return 'Annuel (365 jours) - Accès complet';
      case SubscriptionType.lifetime:
        return 'À vie - Accès complet permanent';
    }
  }

  void _updateDefaultDuration() {
    _expiresAt = LicenseGeneratorService.calculateExpirationDate(_selectedType);
  }

  Future<void> _selectExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _saveLicense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      // Générer la clé de licence selon les spécifications LOGESCO V1
      // DEBUG: Afficher l'empreinte utilisée
      print('🔑 Génération de clé avec:');
      print('   Client ID: ${_selectedClient!.id}');
      print('   Type: $_selectedType');
      print('   Expire: $_expiresAt');
      print('   Empreinte: "${_deviceFingerprintController.text}"');

      final licenseKey = LicenseGeneratorService.generateLicenseKey(
        clientId: _selectedClient!.id,
        type: _selectedType,
        expiresAt: _expiresAt,
        deviceFingerprint: _deviceFingerprintController.text,
      );

      print('   Clé générée: $licenseKey');
      print('');

      // Toutes les fonctionnalités sont incluses automatiquement
      final features = LicenseGeneratorService.allFeatures;

      final license = License(
        id: widget.licenseId ?? const Uuid().v4(),
        clientId: _selectedClient!.id,
        licenseKey: licenseKey,
        type: _selectedType,
        status: LicenseStatus.active,
        issuedAt: now,
        expiresAt: _expiresAt,
        deviceFingerprint: _deviceFingerprintController.text,
        features: features,
        price: _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) : null,
        currency: _currency,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await DatabaseService.instance.updateLicense(license);
      } else {
        await DatabaseService.instance.insertLicense(license);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Licence mise à jour' : 'Licence générée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
