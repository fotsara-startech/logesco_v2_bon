import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../models/client.dart';
import '../../core/services/database_service.dart';

class PaymentFormPage extends StatefulWidget {
  final String? clientId;
  final String? paymentId;

  const PaymentFormPage({
    super.key,
    this.clientId,
    this.paymentId,
  });

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;

  Client? _selectedClient;
  List<Client> _clients = [];
  DateTime _paymentDate = DateTime.now();

  // Suggestions de services fréquents (texte libre, non contraignant)
  static const List<String> _descriptionSuggestions = [
    'Dépannage machine',
    'Formation',
    'Installation réseau',
    'Maintenance',
    'Configuration initiale',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _clients = await DatabaseService.instance.getClients(isActive: true);

      if (widget.clientId != null) {
        _selectedClient = _clients.firstWhere(
          (c) => c.id == widget.clientId,
          orElse: () => _clients.first,
        );
      }

      if (widget.paymentId != null) {
        _isEditMode = true;
        final payment = await DatabaseService.instance.getPayment(widget.paymentId!);
        if (payment != null) {
          _loadPaymentData(payment);
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

  void _loadPaymentData(Payment payment) {
    setState(() {
      _selectedClient = _clients.firstWhere((c) => c.id == payment.clientId);
      _descriptionController.text = payment.description;
      _amountController.text = payment.amount.toString();
      _paymentDate = payment.paymentDate;
      _notesController.text = payment.notes ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier le paiement' : 'Nouveau paiement de service'),
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
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucun client disponible', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Créez d\'abord un client avant d\'enregistrer un paiement',
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
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildClientField(),
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
                  Text('Service rendu', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description du service',
                      prefixIcon: Icon(Icons.build_outlined),
                      hintText: 'Ex: Dépannage machine, formation, installation réseau...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Décrivez le service rendu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _descriptionSuggestions.map((suggestion) {
                      return ActionChip(
                        label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => _descriptionController.text = suggestion),
                      );
                    }).toList(),
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
                  Text('Montant et date', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Montant',
                            prefixIcon: Icon(Icons.payments_outlined),
                            suffixText: 'XAF',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Saisissez un montant';
                            if (double.tryParse(value) == null) return 'Montant invalide';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date du paiement'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_paymentDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: _selectPaymentDate,
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
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes additionnelles',
                      prefixIcon: Icon(Icons.note),
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
                onPressed: _savePayment,
                icon: const Icon(Icons.save),
                label: Text(_isEditMode ? 'Mettre à jour' : 'Enregistrer le paiement'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _clientLabel(Client client) => '${client.name} (${client.company})';

  Widget _buildClientField() {
    return Autocomplete<Client>(
      key: ValueKey(_selectedClient?.id),
      initialValue: TextEditingValue(text: _selectedClient != null ? _clientLabel(_selectedClient!) : ''),
      displayStringForOption: _clientLabel,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return _clients;
        final q = textEditingValue.text.toLowerCase();
        return _clients.where((c) => c.name.toLowerCase().contains(q) || c.company.toLowerCase().contains(q));
      },
      onSelected: (client) => setState(() => _selectedClient = client),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Client',
            hintText: 'Rechercher un client par nom ou entreprise...',
            prefixIcon: Icon(Icons.person),
            suffixIcon: Icon(Icons.search),
          ),
          validator: (value) => _selectedClient == null ? 'Sélectionnez un client' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 500),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final client = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(client.name),
                    subtitle: Text(client.company),
                    onTap: () => onSelected(client),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final payment = Payment(
        id: widget.paymentId ?? const Uuid().v4(),
        clientId: _selectedClient!.id,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        paymentDate: _paymentDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await DatabaseService.instance.updatePayment(payment);
      } else {
        await DatabaseService.instance.insertPayment(payment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Paiement mis à jour' : 'Paiement enregistré avec succès'),
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
