import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Widget pour les actions rapides des rapports
class ReportActionsWidget extends StatelessWidget {
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const ReportActionsWidget({
    super.key,
    this.onExportPdf,
    this.onExportExcel,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'financial_movements_reports_quick_actions'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.refresh,
                  label: 'refresh'.tr,
                  onPressed: isLoading ? null : onRefresh,
                  color: Colors.blue,
                ),
                _buildActionButton(
                  icon: Icons.picture_as_pdf,
                  label: 'financial_movements_reports_export_pdf'.tr,
                  onPressed: isLoading ? null : onExportPdf,
                  color: Colors.red,
                ),
                _buildActionButton(
                  icon: Icons.table_chart,
                  label: 'financial_movements_reports_export_excel'.tr,
                  onPressed: isLoading ? null : onExportExcel,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
