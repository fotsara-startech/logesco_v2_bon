import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/supplier_controller.dart';
import '../widgets/supplier_card.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/widgets/permission_widget.dart';
import '../../../core/services/permission_service.dart';

/// Vue de la liste des fournisseurs avec contrôle des permissions
class SupplierListView extends StatelessWidget {
  const SupplierListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierController());

    return PermissionWidget(
      module: 'suppliers',
      privilege: 'READ',
      fallback: Scaffold(
        appBar: AppBar(
          title: Text('suppliers_access_denied'.tr),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'suppliers_access_denied'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'suppliers_access_denied_message'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back),
                label: Text('suppliers_back'.tr),
              ),
            ],
          ),
        ),
      ),
      showFallback: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text('suppliers_title'.tr),
          elevation: 0,
          actions: [
            // Bouton Import/Export
            PopupMenuButton<String>(
              icon: const Icon(Icons.import_export),
              tooltip: 'suppliers_import_export'.tr,
              onSelected: (value) {
                if (value == 'export') {
                  controller.exportToExcel();
                } else if (value == 'import') {
                  controller.importFromExcel();
                } else if (value == 'template') {
                  controller.downloadTemplate();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: const Icon(Icons.download),
                    title: Text('suppliers_export_excel'.tr),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: const Icon(Icons.upload),
                    title: Text('suppliers_import_excel'.tr),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'template',
                  child: ListTile(
                    leading: const Icon(Icons.file_download),
                    title: Text('suppliers_download_template'.tr),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            // Bouton d'ajout visible seulement si l'utilisateur peut créer
            PermissionWidget(
              module: 'suppliers',
              privilege: 'CREATE',
              child: IconButton(
                onPressed: controller.goToCreateSupplier,
                icon: const Icon(Icons.add),
                tooltip: 'suppliers_add'.tr,
              ),
            ),
            IconButton(
              onPressed: controller.refreshSuppliers,
              icon: const Icon(Icons.refresh),
              tooltip: 'suppliers_refresh'.tr,
            ),
          ],
        ),
        body: Column(
          children: [
            // Barre de recherche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                onChanged: controller.updateSearchQuery,
                decoration: InputDecoration(
                  hintText: 'suppliers_search_hint'.tr,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          onPressed: controller.clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : const SizedBox.shrink()),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            // Liste des fournisseurs
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.suppliers.isEmpty) {
                  return LoadingWidget(message: 'suppliers_loading'.tr);
                }

                if (controller.hasError.value && controller.suppliers.isEmpty) {
                  return ErrorDisplayWidget(
                    message: controller.errorMessage.value,
                    onRetry: controller.refreshSuppliers,
                  );
                }

                if (controller.suppliers.isEmpty) {
                  return _buildEmptyState(controller);
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshSuppliers,
                  child: _buildSupplierList(controller),
                );
              }),
            ),
          ],
        ),
        floatingActionButton: PermissionWidget(
          module: 'suppliers',
          privilege: 'CREATE',
          child: FloatingActionButton(
            onPressed: controller.goToCreateSupplier,
            tooltip: 'suppliers_add'.tr,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  /// Construit l'état vide
  Widget _buildEmptyState(SupplierController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.value.isNotEmpty ? 'suppliers_no_results'.tr : 'suppliers_no_suppliers'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchQuery.value.isNotEmpty ? 'suppliers_no_results_hint'.tr : 'suppliers_no_suppliers_hint'.tr,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (controller.searchQuery.value.isNotEmpty)
            ElevatedButton.icon(
              onPressed: controller.clearSearch,
              icon: const Icon(Icons.clear),
              label: Text('suppliers_clear_search'.tr),
            )
          else
            PermissionWidget(
              module: 'suppliers',
              privilege: 'CREATE',
              child: ElevatedButton.icon(
                onPressed: controller.goToCreateSupplier,
                icon: const Icon(Icons.add),
                label: Text('suppliers_add'.tr),
              ),
            ),
        ],
      ),
    );
  }

  /// Construit la liste des fournisseurs
  Widget _buildSupplierList(SupplierController controller) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Pagination infinie
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && controller.hasMoreData.value && !controller.isLoadingMore.value) {
          controller.loadMoreSuppliers();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.suppliers.length + (controller.hasMoreData.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Indicateur de chargement pour pagination
          if (index == controller.suppliers.length) {
            return Obx(() => controller.isLoadingMore.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink());
          }

          final supplier = controller.suppliers[index];
          return SupplierCard(
            supplier: supplier,
            onTap: () => controller.goToSupplierDetail(supplier),
            onEdit: _hasUpdatePermission() ? () => controller.goToEditSupplier(supplier) : null,
            onDelete: _hasDeletePermission() ? () => controller.deleteSupplier(supplier) : null,
            onCall: supplier.telephone != null ? () => _callSupplier(supplier.telephone!) : null,
            onEmail: supplier.email != null ? () => _emailSupplier(supplier.email!) : null,
          );
        },
      ),
    );
  }

  /// Appelle un fournisseur
  Future<void> _callSupplier(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        'suppliers_error'.tr,
        'suppliers_call_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Envoie un email à un fournisseur
  Future<void> _emailSupplier(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar(
        'suppliers_error'.tr,
        'suppliers_email_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Vérifie si l'utilisateur a les permissions de modification
  bool _hasUpdatePermission() {
    final permissionService = Get.find<PermissionService>();
    return permissionService.hasPermission('suppliers', 'UPDATE');
  }

  /// Vérifie si l'utilisateur a les permissions de suppression
  bool _hasDeletePermission() {
    final permissionService = Get.find<PermissionService>();
    return permissionService.hasPermission('suppliers', 'DELETE');
  }
}
