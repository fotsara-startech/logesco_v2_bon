import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/proforma_controller.dart';
import '../models/proforma_invoice.dart';
import 'validate_proforma_dialog.dart';
import 'create_proforma_page.dart';

/// Page de détail d'une proforma avec possibilité de modifier ou valider
class ProformaDetailPage extends StatefulWidget {
  final ProformaInvoice proforma;

  const ProformaDetailPage({super.key, required this.proforma});

  @override
  State<ProformaDetailPage> createState() => _ProformaDetailPageState();
}

class _ProformaDetailPageState extends State<ProformaDetailPage> {
  late ProformaController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ProformaController>();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final proforma = widget.proforma;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        title: Text(proforma.numeroProforma),
        actions: [
          if (proforma.isBrouillon) ...[
            TextButton.icon(
              onPressed: () => _openForEdit(context),
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: Text('proforma_edit'.tr, style: const TextStyle(color: Colors.white)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'proforma_cancel'.tr,
              onPressed: () => _confirmCancel(context),
            ),
          ],
          if (!proforma.isAnnulee)
            IconButton(
              icon: const Icon(Icons.print_outlined, color: Colors.white),
              tooltip: 'proforma_print'.tr,
              onPressed: () => _ctrl.printProforma(proforma),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête statut
            _buildStatusBanner(proforma),
            const SizedBox(height: 16),

            // Infos générales
            _buildInfoCard(proforma, dateFmt),
            const SizedBox(height: 16),

            // Articles
            _buildItemsCard(proforma, fmt),
            const SizedBox(height: 16),

            // Totaux
            _buildTotalsCard(proforma, fmt),
            const SizedBox(height: 24),

            // Bouton valider (si brouillon)
            if (proforma.isBrouillon)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: GetBuilder<ProformaController>(
                  builder: (ctrl) => ElevatedButton.icon(
                    onPressed: ctrl.isValidating
                        ? null
                        : () => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => ValidateProformaDialog(proforma: proforma, controller: _ctrl),
                            ),
                    icon: ctrl.isValidating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle),
                    label: Text(
                      ctrl.isValidating ? 'proforma_validating'.tr : 'proforma_validate'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ProformaInvoice p) {
    Color color;
    String label;
    IconData icon;
    switch (p.statut) {
      case ProformaStatut.validee:
        color = Colors.green;
        label = 'proforma_status_validated'.tr;
        icon = Icons.check_circle;
        break;
      case ProformaStatut.annulee:
        color = Colors.red;
        label = 'proforma_status_cancelled'.tr;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        label = 'proforma_status_draft'.tr;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          Text('proforma_invoice_label'.tr, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ProformaInvoice p, DateFormat dateFmt) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('proforma_info'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 16),
            if (p.client != null) _infoRow(Icons.person_outline, 'proforma_client'.tr, p.client!.nom),
            _infoRow(Icons.calendar_today, 'proforma_date'.tr, dateFmt.format(p.dateCreation)),
            _infoRow(Icons.payment, 'proforma_payment_mode'.tr, p.modePaiement),
            if (p.vendeurNom != null) _infoRow(Icons.badge_outlined, 'proforma_seller'.tr, p.vendeurNom!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildItemsCard(ProformaInvoice p, NumberFormat fmt) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('proforma_items'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 16),
            ...p.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.produitNom ?? 'Produit ${item.produitId}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            if (item.produitReference != null) Text(item.produitReference!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('x${item.quantite}', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 16),
                      Text('${fmt.format(item.montantLigne)} F', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(ProformaInvoice p, NumberFormat fmt) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (p.montantRemise > 0) ...[
              _totalRow('proforma_subtotal'.tr, fmt.format(p.sousTotal)),
              _totalRow('proforma_discount'.tr, '-${fmt.format(p.montantRemise)}', color: Colors.red[700]),
            ],
            if (p.montantTva > 0) _totalRow('proforma_tva'.tr, '+${fmt.format(p.montantTva)}'),
            const Divider(),
            _totalRow('proforma_total'.tr, '${fmt.format(p.montantTotal)} FCFA', bold: true, fontSize: 18),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false, double fontSize = 14, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  void _openForEdit(BuildContext context) {
    Get.to(() => CreateProformaPage(editingProforma: widget.proforma));
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('proforma_cancel_confirm_title'.tr),
        content: Text('proforma_cancel_confirm_msg'.trParams({'number': widget.proforma.numeroProforma})),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('no'.tr)),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final ok = await _ctrl.cancelProforma(widget.proforma.id);
              if (ok) Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('yes'.tr),
          ),
        ],
      ),
    );
  }
}
