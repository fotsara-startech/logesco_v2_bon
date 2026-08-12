import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/client.dart';
import '../../models/license.dart';
import '../../models/payment.dart';
import '../../core/services/database_service.dart';
import '../../widgets/stats_card.dart';

class ClientDetailPage extends StatefulWidget {
  final String clientId;

  const ClientDetailPage({super.key, required this.clientId});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  Client? _client;
  List<License> _licenses = [];
  List<Payment> _payments = [];
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'XAF', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final client = await DatabaseService.instance.getClient(widget.clientId);
      final licenses = await DatabaseService.instance.getLicenses(clientId: widget.clientId);
      final payments = await DatabaseService.instance.getPayments(clientId: widget.clientId);
      setState(() {
        _client = client;
        _licenses = licenses;
        _payments = payments;
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

  double get _licenseRevenue => _licenses.fold(0.0, (s, l) => s + (l.price ?? 0));
  double get _serviceRevenue => _payments.fold(0.0, (s, p) => s + p.amount);
  double get _totalRevenue => _licenseRevenue + _serviceRevenue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_client?.name ?? 'Fiche client'),
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
          : _client == null
              ? const Center(child: Text('Client introuvable'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildRevenueCard(),
                        const SizedBox(height: 24),
                        _buildLicensesSection(),
                        const SizedBox(height: 24),
                        _buildPaymentsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    final client = _client!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(client.company, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  if (client.email != null) _buildInfoRow(Icons.email_outlined, client.email!),
                  if (client.phone != null) _buildInfoRow(Icons.phone_outlined, client.phone!),
                  if (client.address != null) _buildInfoRow(Icons.location_on_outlined, client.address!),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier le client',
              onPressed: () => context.go('/clients/edit/${client.id}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final cards = [
          StatsCard(title: 'Chiffre d\'affaires total', value: _currencyFormat.format(_totalRevenue), icon: Icons.account_balance_wallet, color: Colors.green),
          StatsCard(title: 'Revenus licences', value: _currencyFormat.format(_licenseRevenue), icon: Icons.key, color: Colors.blue),
          StatsCard(title: 'Revenus services', value: _currencyFormat.format(_serviceRevenue), icon: Icons.build_outlined, color: Colors.orange),
        ];
        if (isNarrow) {
          return Column(
            children: [
              for (final card in cards) ...[card, const SizedBox(height: 12)],
            ],
          );
        }
        return Row(
          children: [
            for (final card in cards) ...[Expanded(child: card), const SizedBox(width: 16)],
          ],
        );
      },
    );
  }

  Widget _buildLicensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Licences (${_licenses.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => context.go('/licenses/new?clientId=${widget.clientId}'),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle licence'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_licenses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune licence pour ce client'),
            ),
          )
        else
          ..._licenses.map((license) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(license.status),
                    child: const Icon(Icons.key, color: Colors.white, size: 20),
                  ),
                  title: Text(license.typeLabel),
                  subtitle: Text('Expire le ${DateFormat('dd/MM/yyyy').format(license.expiresAt)}'),
                  trailing: Text(
                    license.price != null ? _currencyFormat.format(license.price) : '—',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => context.go('/licenses/edit/${license.id}'),
                ),
              )),
      ],
    );
  }

  Widget _buildPaymentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Paiements de services (${_payments.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => context.go('/payments/new?clientId=${widget.clientId}'),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau paiement'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_payments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun paiement de service pour ce client'),
            ),
          )
        else
          ..._payments.map((payment) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.payments, color: Colors.white, size: 20),
                  ),
                  title: Text(payment.description),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(payment.paymentDate)),
                  trailing: Text(
                    _currencyFormat.format(payment.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  onTap: () => context.go('/payments/edit/${payment.id}'),
                ),
              )),
      ],
    );
  }

  Color _statusColor(LicenseStatus status) {
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
}
