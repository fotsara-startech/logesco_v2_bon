import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/excel_controller.dart';
import '../../../core/utils/currency_formatter.dart';

/// Page pour l'import/export Excel des produits
class ExcelImportExportPage extends StatelessWidget {
  const ExcelImportExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ExcelController controller = Get.put(ExcelController());

    return Scaffold(
      appBar: AppBar(
        title: Text('excel_import_export_title'.tr),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.showImportPreview.value) {
          return _buildImportPreview(controller);
        }
        return _buildMainView(controller);
      }),
    );
  }

  Widget _buildMainView(ExcelController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Export
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.file_download, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'excel_export_section'.tr,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('excel_export_description'.tr, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  Obx(() => controller.isExporting.value
                      ? Column(
                          children: [
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(controller.exportStatus.value),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: controller.exportAllProducts,
                          icon: const Icon(Icons.download),
                          label: Text('excel_export_button'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section Import
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.file_upload, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'excel_import_section'.tr,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('excel_import_description'.tr, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  Obx(() => controller.isImporting.value
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    controller.importStatus.value,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: controller.importProductsFromExcel,
                                    icon: const Icon(Icons.upload_file),
                                    label: Text('excel_import_button'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: controller.downloadImportTemplate,
                                  icon: const Icon(Icons.download),
                                  label: Text('excel_template_button'.tr),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (controller.importStatus.value.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  controller.importStatus.value,
                                  style: TextStyle(
                                    color: controller.importStatus.value.contains('Erreur') ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'excel_instructions_title'.tr,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'À ${'excel_instructions_line1'.tr}\n'
                    'À ${'excel_instructions_line2'.tr}\n'
                    'À ${'excel_instructions_line3'.tr}\n'
                    'À ${'excel_instructions_line4'.tr}\n'
                    'À ${'excel_instructions_line5'.tr}\n'
                    'À ${'excel_instructions_line6'.tr}',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportPreview(ExcelController controller) {
    return Obx(() {
      final importing = controller.isImporting.value;

      return Stack(
        children: [
          Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'excel_preview_title'.tr,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'excel_preview_products'.tr.replaceAll('@count', controller.importPreview.length.toString()),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          if (controller.initialStocksPreview.isNotEmpty)
                            Text(
                              'excel_preview_stocks'.tr.replaceAll('@count', controller.initialStocksPreview.length.toString()),
                              style: TextStyle(color: Colors.green[600], fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: importing ? null : controller.cancelImport,
                      child: Text('excel_preview_cancel'.tr),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: importing ? null : controller.confirmImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: importing ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('excel_preview_confirm'.tr),
                    ),
                  ],
                ),
              ),

              // Barre de progression + statut pendant la confirmation
              if (importing) ...[
                LinearProgressIndicator(
                  backgroundColor: Colors.green[100],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.green[50],
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        controller.importStatus.value,
                        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],

              // Liste des produits
              Expanded(
                child: ListView.builder(
                  itemCount: controller.importPreview.length,
                  itemBuilder: (context, index) {
                    final product = controller.importPreview[index];
                    final initialStock = controller.initialStocksPreview.where((s) => s.productReference == product.reference).firstOrNull;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            product.reference.isNotEmpty ? product.reference.substring(0, 1).toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(product.nom),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${'excel_reference_label'.tr}: ${product.reference}'),
                            Text('${'excel_price_label'.tr}: ${CurrencyFormatter.formatCurrency(product.prixUnitaire)}'),
                            if (product.categorie != null && product.categorie!.isNotEmpty) Text('${'excel_category_label'.tr}: ${product.categorie}'),
                            if (initialStock != null)
                              Text(
                                '${'excel_initial_stock_label'.tr}: ${initialStock.quantite}',
                                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.estService) Chip(label: Text('excel_service_chip'.tr), backgroundColor: Colors.orange[100]),
                            if (!product.estActif) Chip(label: Text('excel_inactive_chip'.tr), backgroundColor: Colors.red[100]),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: importing ? null : () => controller.removeFromImportPreview(index),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Overlay semi-transparent pendant l'import
          if (importing)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.12)),
            ),
        ],
      );
    });
  }
}
