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

  /// Vue principale avec les options d'import/export
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
                      Icon(Icons.file_download, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'excel_export_section'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'excel_export_description'.tr,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => controller.isExporting.value
                      ? Column(
                          children: [
                            LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(controller.exportStatus.value),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: controller.exportAllProducts,
                          icon: Icon(Icons.download),
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
                      Icon(Icons.file_upload, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'excel_import_section'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'excel_import_description'.tr,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => controller.isImporting.value
                      ? Column(
                          children: [
                            LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(controller.importStatus.value),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: controller.importProductsFromExcel,
                                    icon: Icon(Icons.upload_file),
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
                                  icon: Icon(Icons.download),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${'excel_instructions_line1'.tr}\n'
                    '• ${'excel_instructions_line2'.tr}\n'
                    '• ${'excel_instructions_line3'.tr}\n'
                    '• ${'excel_instructions_line4'.tr}\n'
                    '• ${'excel_instructions_line5'.tr}\n'
                    '• ${'excel_instructions_line6'.tr}',
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

  /// Vue d'aperçu des produits à importer
  Widget _buildImportPreview(ExcelController controller) {
    return Column(
      children: [
        // En-tête de l'aperçu
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                        )),
                  ],
                ),
              ),
              TextButton(
                onPressed: controller.cancelImport,
                child: Text('excel_preview_cancel'.tr),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: controller.confirmImport,
                child: Text('excel_preview_confirm'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Liste des produits à importer
        Expanded(
          child: Obx(() => ListView.builder(
                itemCount: controller.importPreview.length,
                itemBuilder: (context, index) {
                  final product = controller.importPreview[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          product.reference.substring(0, 1).toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(product.nom),
                      subtitle: Obx(() {
                        // Trouver le stock initial correspondant
                        final initialStock = controller.initialStocksPreview.where((stock) => stock.productReference == product.reference).firstOrNull;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${'excel_reference_label'.tr}: ${product.reference}'),
                            Text('${'excel_price_label'.tr}: ${CurrencyFormatter.formatCurrency(product.prixUnitaire)}'),
                            if (product.categorie != null) Text('${'excel_category_label'.tr}: ${product.categorie}'),
                            if (initialStock != null)
                              Text(
                                '${'excel_initial_stock_label'.tr}: ${initialStock.quantite}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        );
                      }),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (product.estService)
                            Chip(
                              label: Text('excel_service_chip'.tr),
                              backgroundColor: Colors.orange[100],
                            ),
                          if (!product.estActif)
                            Chip(
                              label: Text('excel_inactive_chip'.tr),
                              backgroundColor: Colors.red[100],
                            ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => controller.removeFromImportPreview(index),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              )),
        ),
      ],
    );
  }
}
