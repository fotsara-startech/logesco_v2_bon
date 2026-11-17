import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/utils/snackbar_helper.dart';
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
  late PrintMode _selectedPrintMode;

  @override
  void initState() {
    super.initState();
    _salesController = Get.find<SalesController>();
    // Récupérer le format actuellement sélectionné
    _selectedFormat = _salesController.selectedReceiptFormat;
    _selectedPrintMode = _salesController.printMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('sales_prefs_title'.tr),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'sales_prefs_print_mode_title'.tr,
            description: 'sales_prefs_print_mode_desc'.tr,
            child: _buildPrintModeSelection(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'sales_prefs_format_title'.tr,
            description: 'sales_prefs_format_desc'.tr,
            child: _buildFormatSelection(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'sales_prefs_about_title'.tr,
            description: 'sales_prefs_about_desc'.tr,
            child: _buildInfoBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintModeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RadioListTile<PrintMode>(
              title: Text(PrintMode.direct.displayName),
              subtitle: Text(PrintMode.direct.description),
              value: PrintMode.direct,
              groupValue: _selectedPrintMode,
              onChanged: _updatePrintMode,
            ),
            RadioListTile<PrintMode>(
              title: Text(PrintMode.preview.displayName),
              subtitle: Text(PrintMode.preview.description),
              value: PrintMode.preview,
              groupValue: _selectedPrintMode,
              onChanged: _updatePrintMode,
            ),
            RadioListTile<PrintMode>(
              title: Text(PrintMode.none.displayName),
              subtitle: Text(PrintMode.none.description),
              value: PrintMode.none,
              groupValue: _selectedPrintMode,
              onChanged: _updatePrintMode,
            ),
          ],
        ),
      ),
    );
  }

  void _updatePrintMode(PrintMode? mode) {
    if (mode != null) {
      setState(() {
        _selectedPrintMode = mode;
      });
      _salesController.setPrintMode(mode);

      SnackbarHelper.success(
        'sales_prefs_print_mode_changed'.trParams({'mode': mode.displayName}),
        title: 'sales_prefs_setting_saved'.tr,
        duration: const Duration(seconds: 2),
      );
    }
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
              title: Text('sales_prefs_thermal_title'.tr),
              subtitle: Text('sales_prefs_thermal_desc'.tr),
              value: PrintFormat.thermal,
              groupValue: _selectedFormat,
              onChanged: _updateFormat,
            ),
            RadioListTile<PrintFormat>(
              title: Text('sales_prefs_a5_title'.tr),
              subtitle: Text('sales_prefs_a5_desc'.tr),
              value: PrintFormat.a5,
              groupValue: _selectedFormat,
              onChanged: _updateFormat,
            ),
            RadioListTile<PrintFormat>(
              title: Text('sales_prefs_a4_title'.tr),
              subtitle: Text('sales_prefs_a4_desc'.tr),
              value: PrintFormat.a4,
              groupValue: _selectedFormat,
              onChanged: _updateFormat,
            ),
            RadioListTile<PrintFormat>(
              title: Text('sales_prefs_matrix_title'.tr),
              subtitle: Text('sales_prefs_matrix_desc'.tr),
              value: PrintFormat.matriciel,
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
                      'sales_prefs_format_selected'.trParams({'format': _selectedFormat.displayName}),
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
                  'sales_prefs_auto_applied'.tr,
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
            'sales_prefs_format_note'.tr,
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

      SnackbarHelper.success(
        'sales_prefs_format_changed'.trParams({'format': format.displayName}),
        title: 'sales_prefs_setting_saved'.tr,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
