import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/sale.dart';

/// Vue détaillée des ventes : une ligne par produit vendu
class SalesDetailsView extends StatelessWidget {
  final List<Sale> sales;
  final Function(Sale) onTap;
  final VoidCallback? onLoadMore;
  final bool hasMoreData;

  const SalesDetailsView({
    super.key,
    required this.sales,
    required this.onTap,
    this.onLoadMore,
    this.hasMoreData = false,
  });

  @override
  Widget build(BuildContext context) {
    // Aplatir toutes les ventes en lignes de détails
    final List<_DetailRow> detailRows = [];
    for (final sale in sales) {
      if (sale.details.isNotEmpty) {
        for (final detail in sale.details) {
          detailRows.add(_DetailRow(sale: sale, detail: detail));
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // En-tête du tableau
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5), // N° Vente
                1: FlexColumnWidth(2), // Client
                2: FlexColumnWidth(2.5), // Produit
                3: FlexColumnWidth(1.2), // Prix Unit.
                4: FlexColumnWidth(0.8), // Qté
                5: FlexColumnWidth(1), // Remise
                6: FlexColumnWidth(1.2), // Total
              },
              children: [
                TableRow(
                  children: [
                    _buildHeaderCell('sales_number'.tr),
                    _buildHeaderCell('sales_client'.tr),
                    _buildHeaderCell('sales_product'.tr),
                    _buildHeaderCell('sales_unit_price'.tr),
                    _buildHeaderCell('sales_quantity'.tr),
                    _buildHeaderCell('sales_discount'.tr),
                    _buildHeaderCell('sales_total'.tr),
                  ],
                ),
              ],
            ),
          ),

          // Corps du tableau
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2.5),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(0.8),
                  5: FlexColumnWidth(1),
                  6: FlexColumnWidth(1.2),
                },
                children: [
                  ...detailRows.map((row) => _buildDetailRow(context, row)),
                  if (hasMoreData)
                    TableRow(
                      children: List.generate(
                        7,
                        (index) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: index == 3 ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Résumé en bas
          if (detailRows.isNotEmpty) _buildSummary(detailRows),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  TableRow _buildDetailRow(BuildContext context, _DetailRow row) {
    final sale = row.sale;
    final detail = row.detail;
    final isCancelled = sale.statut.toLowerCase() == 'annulée';

    return TableRow(
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red[50] : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      children: [
        // N° Vente
        _buildDataCell(
          InkWell(
            onTap: () => onTap(sale),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                sale.numeroVente,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),

        // Client
        _buildDataCell(
          Text(
            sale.client?.nom ?? 'sales_no_client'.tr,
            style: TextStyle(
              color: sale.client != null ? Colors.black87 : Colors.grey[500],
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Produit
        _buildDataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.produit?.nom ?? 'Produit ${detail.produitId}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (detail.produit?.reference != null)
                Text(
                  detail.produit!.reference,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),

        // Prix unitaire
        _buildDataCell(
          Text(
            '${detail.prixUnitaire.toStringAsFixed(0)} F',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Quantité
        _buildDataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${detail.quantite}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Remise
        _buildDataCell(
          detail.remiseAppliquee > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${detail.remiseAppliquee.toStringAsFixed(0)} F',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    if (detail.pourcentageRemise > 0)
                      Text(
                        '(-${detail.pourcentageRemise.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green[600],
                        ),
                      ),
                  ],
                )
              : Text(
                  '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
        ),

        // Total ligne
        _buildDataCell(
          Text(
            '${detail.montantLigne.toStringAsFixed(0)} F',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }

  Widget _buildSummary(List<_DetailRow> rows) {
    final totalQuantity = rows.fold<int>(0, (sum, row) => sum + row.detail.quantite);
    final totalDiscount = rows.fold<double>(0, (sum, row) => sum + row.detail.economieClient);
    final totalAmount = rows.fold<double>(0, (sum, row) => sum + row.detail.montantLigne);

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.blue[200]!, width: 2)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5), // N° Vente
          1: FlexColumnWidth(2), // Client
          2: FlexColumnWidth(2.5), // Produit
          3: FlexColumnWidth(1.2), // Prix Unit.
          4: FlexColumnWidth(0.8), // Qté
          5: FlexColumnWidth(1), // Remise
          6: FlexColumnWidth(1.2), // Total
        },
        children: [
          TableRow(
            children: [
              // Colonnes 0-3 : Label "Total"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(
                  'sales_summary_total'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox.shrink(), // Client
              const SizedBox.shrink(), // Produit
              const SizedBox.shrink(), // Prix Unit.

              // Colonne 4 : Total Quantité
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$totalQuantity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Colonne 5 : Total Remise
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(
                  '${totalDiscount.toStringAsFixed(0)} F',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
              ),

              // Colonne 6 : Total Montant
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(
                  '${totalAmount.toStringAsFixed(0)} F',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Classe helper pour représenter une ligne de détail
class _DetailRow {
  final Sale sale;
  final SaleDetail detail;

  _DetailRow({required this.sale, required this.detail});
}
