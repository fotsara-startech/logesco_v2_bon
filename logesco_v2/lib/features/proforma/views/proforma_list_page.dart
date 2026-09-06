import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/proforma_controller.dart';
import '../models/proforma_invoice.dart';
import '../widgets/proforma_filters.dart';
import 'proforma_detail_page.dart';
import 'validate_proforma_dialog.dart';
import 'create_proforma_page.dart';

class ProformaListPage extends StatefulWidget {
  const ProformaListPage({super.key});

  @override
  State<ProformaListPage> createState() => _ProformaListPageState();
}

class _ProformaListPageState extends State<ProformaListPage> {
  late ProformaController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ProformaController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        title: Text('proforma_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _ctrl.loadProformas(refresh: true),
            tooltip: 'Actualiser',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => Get.to(() => const CreateProformaPage()),
              icon: const Icon(Icons.add, size: 18),
              label: Text('proforma_new'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres statut
          _buildStatusFilter(),
          // Filtres vendeur/période — mêmes filtres que la page de vente
          const ProformaFilters(),
          // Liste
          Expanded(
            child: GetBuilder<ProformaController>(
              builder: (ctrl) {
                if (ctrl.isLoading && ctrl.proformas.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ctrl.proformas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('proforma_empty'.tr, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('proforma_empty_hint'.tr, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ctrl.loadProformas(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: ctrl.proformas.length,
                    itemBuilder: (context, index) {
                      return _ProformaCard(proforma: ctrl.proformas[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return GetBuilder<ProformaController>(
      builder: (ctrl) => Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(ctrl, 'proforma_all'.tr, ''),
              const SizedBox(width: 8),
              _chip(ctrl, 'proforma_status_draft'.tr, ProformaStatut.brouillon),
              const SizedBox(width: 8),
              _chip(ctrl, 'proforma_status_validated'.tr, ProformaStatut.validee),
              const SizedBox(width: 8),
              _chip(ctrl, 'proforma_status_cancelled'.tr, ProformaStatut.annulee),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(ProformaController ctrl, String label, String value) {
    final isSelected = ctrl.statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ctrl.setStatusFilter(value),
      selectedColor: Colors.orange[100],
      checkmarkColor: Colors.orange[800],
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange[800] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

// ─── Card proforma ────────────────────────────────────────────────────────────

class _ProformaCard extends StatelessWidget {
  final ProformaInvoice proforma;

  const _ProformaCard({required this.proforma});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (proforma.statut) {
      case ProformaStatut.validee:
        statusColor = Colors.green;
        statusLabel = 'proforma_status_validated'.tr;
        statusIcon = Icons.check_circle;
        break;
      case ProformaStatut.annulee:
        statusColor = Colors.red;
        statusLabel = 'proforma_status_cancelled'.tr;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'proforma_status_draft'.tr;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Get.to(() => ProformaDetailPage(proforma: proforma)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numéro + statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      proforma.numeroProforma,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Client
              if (proforma.client != null)
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(proforma.client!.nom, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ],
                ),
              const SizedBox(height: 4),
              // Date + montant
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(dateFmt.format(proforma.dateCreation), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${fmt.format(proforma.montantTotal)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
              // Actions rapides (brouillon seulement)
              if (proforma.isBrouillon) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.to(() => CreateProformaPage(editingProforma: proforma)),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text('proforma_edit'.tr),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Imprimer
                    IconButton(
                      onPressed: () => Get.find<ProformaController>().printProforma(proforma),
                      icon: const Icon(Icons.print_outlined, size: 20),
                      tooltip: 'proforma_print'.tr,
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GetBuilder<ProformaController>(
                        builder: (ctrl) => ElevatedButton.icon(
                          onPressed: ctrl.isValidating
                              ? null
                              : () => showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => ValidateProformaDialog(proforma: proforma, controller: ctrl),
                                  ),
                          icon: ctrl.isValidating
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle, size: 16),
                          label: Text('proforma_validate'.tr),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Bouton imprimer pour les proformas validées
              if (proforma.isValidee) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.find<ProformaController>().printProforma(proforma),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: Text('proforma_print'.tr),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
