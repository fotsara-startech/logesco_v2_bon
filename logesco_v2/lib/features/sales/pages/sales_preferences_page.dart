import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:logesco_client_ultimate/core/models/print_format.dart';
// import 'package:logesco_client_ultimate/features/sales/controllers/sales_controller.dart';
import 'package:logesco_v2/features/printing/models/print_format.dart';
import 'package:logesco_v2/features/sales/controllers/sales_controller.dart';

/// Page de paramètres des ventes
/// Configure les préférences par défaut (format d'impression, etc.)
class SalesPreferencesPage extends StatefulWidget {
  const SalesPreferencesPage({Key? key}) : super(key: key);

  @override
  State<SalesPreferencesPage> createState() => _SalesPreferencesPageState();
}

class _SalesPreferencesPageState extends State<SalesPreferencesPage> {
  late final SalesController _salesController;
  late PrintFormat _selectedFormat;

  @override
  void initState() {
    super.initState();
    _salesController = Get.find<SalesController>();
    // Récupérer le format actuellement sélectionné
    _selectedFormat = _salesController.selectedReceiptFormat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres des ventes'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Format d\'impression',
            description: 'Sélectionner le format par défaut pour tous les reçus',
            child: _buildFormatSelection(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'À propos',
            description: 'Ces paramètres s\'appliquent à toutes les ventes',
            child: _buildInfoBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<PrintFormat>(
              title: const Text('Imprimante thermique 80mm'),
              subtitle: const Text('Recommandé pour les reçus rapides'),
              value: PrintFormat.thermal,
              groupValue: _selectedFormat,
              onChanged: _updateFormat,
            ),
            RadioListTile<PrintFormat>(
              title: const Text('Format A5'),
              subtitle: const Text('14.8 x 21 cm'),
              value: PrintFormat.a5,
              groupValue: _selectedFormat,
              onChanged: _updateFormat,
            ),
            RadioListTile<PrintFormat>(
              title: const Text('Format A4'),
              subtitle: const Text('21 x 29.7 cm'),
              value: PrintFormat.a4,
              groupValue: _selectedFormat,
              onChanged: _updateFormat,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Format sélectionné: ${_selectedFormat.displayName}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Les paramètres sont appliqués automatiquement',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Le format d\'impression sélectionné sera utilisé pour tous les reçus jusqu\'à ce que vous le changiez à nouveau.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  void _updateFormat(PrintFormat? format) {
    if (format != null) {
      setState(() {
        _selectedFormat = format;
      });
      // Persister la sélection dans le controller
      _salesController.setSelectedReceiptFormat(format);

      Get.snackbar(
        'Paramètre sauvegardé',
        'Format d\'impression changé en ${format.displayName}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
