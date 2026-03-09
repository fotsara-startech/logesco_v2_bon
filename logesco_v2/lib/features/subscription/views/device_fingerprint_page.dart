import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/implementations/device_service.dart';
import '../models/device_fingerprint.dart';

/// Page pour afficher et copier l'empreinte de l'appareil
class DeviceFingerprintPage extends StatefulWidget {
  const DeviceFingerprintPage({super.key});

  @override
  State<DeviceFingerprintPage> createState() => _DeviceFingerprintPageState();
}

class _DeviceFingerprintPageState extends State<DeviceFingerprintPage> {
  final DeviceService _deviceService = DeviceService();
  DeviceFingerprint? _fingerprint;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFingerprint();
  }

  Future<void> _loadFingerprint() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Essayer de récupérer l'empreinte stockée
      var fingerprint = await _deviceService.getStoredFingerprint();

      // Si pas d'empreinte stockée, en créer une nouvelle
      if (fingerprint == null) {
        fingerprint = await _deviceService.createDeviceFingerprint();
        await _deviceService.storeDeviceFingerprint(fingerprint);
      }

      setState(() {
        _fingerprint = fingerprint;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '${'error'.tr}: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyFingerprint() async {
    if (_fingerprint == null) return;

    await Clipboard.setData(ClipboardData(text: _fingerprint!.combinedHash));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('subscription_fingerprint_copied'.tr),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('subscription_device_fingerprint_title'.tr),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFingerprint,
            tooltip: 'refresh'.tr,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildFingerprintView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'error'.tr,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFingerprint,
              icon: const Icon(Icons.refresh),
              label: Text('subscription_retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintView() {
    if (_fingerprint == null) {
      return Center(child: Text('subscription_key_not_available'.tr));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête avec icône
          _buildHeader(),

          const SizedBox(height: 32),

          // Instructions
          _buildInstructions(),

          const SizedBox(height: 24),

          // Empreinte principale
          _buildFingerprintCard(),

          const SizedBox(height: 24),

          // Informations détaillées
          _buildDeviceInfoCard(),

          const SizedBox(height: 24),

          // Avertissement
          _buildWarningCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.fingerprint,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'subscription_device_fingerprint'.tr,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'subscription_device_fingerprint_description'.tr,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'subscription_device_fingerprint_how_to_use'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '1. ${'subscription_device_fingerprint_step_1'.tr}\n'
              '2. ${'subscription_device_fingerprint_step_2'.tr}\n'
              '3. ${'subscription_device_fingerprint_step_3'.tr}\n'
              '4. ${'subscription_device_fingerprint_step_4'.tr}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.vpn_key,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'subscription_your_unique_fingerprint'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: SelectableText(
                _fingerprint!.combinedHash,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyFingerprint,
                icon: const Icon(Icons.copy),
                label: Text('subscription_copy_fingerprint'.tr),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.devices,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'subscription_device_info'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('subscription_platform'.tr, _fingerprint!.platform.toUpperCase()),
            const Divider(),
            _buildInfoRow('subscription_os_version'.tr, _fingerprint!.osVersion),
            const Divider(),
            _buildInfoRow('subscription_app_version'.tr, _fingerprint!.appVersion),
            const Divider(),
            _buildInfoRow(
              'subscription_generated_on'.tr,
              _formatDate(_fingerprint!.generatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'subscription_important'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• ${'subscription_warning_unique'.tr}\n'
              '• ${'subscription_warning_device_bound'.tr}\n'
              '• ${'subscription_warning_no_sharing'.tr}\n'
              '• ${'subscription_warning_device_change'.tr}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
