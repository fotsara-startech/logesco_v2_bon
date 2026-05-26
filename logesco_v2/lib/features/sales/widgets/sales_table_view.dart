import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';

class SalesTableView extends StatelessWidget {
  final List<Sale> sales;
  final Function(Sale) onTap;
  final VoidCallback? onLoadMore;
  final bool hasMoreData;

  const SalesTableView({
    super.key,
    required this.sales,
    required this.onTap,
    this.onLoadMore,
    this.hasMoreData = false,
  });

  @override
  Widget build(BuildContext context) {
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
                0: FlexColumnWidth(2), // N° Vente
                1: FlexColumnWidth(2.5), // Client
                2: FlexColumnWidth(1.5), // Date
                3: FlexColumnWidth(1.5), // Montant
                4: FlexColumnWidth(1.5), // Payé
                5: FlexColumnWidth(1.2), // Statut
                6: FlexColumnWidth(1), // Actions
              },
              children: [
                TableRow(
                  children: [
                    _buildHeaderCell('sales_number'.tr),
                    _buildHeaderCell('sales_client'.tr),
                    _buildHeaderCell('sales_date'.tr),
                    _buildHeaderCell('sales_amount'.tr),
                    _buildHeaderCell('sales_paid'.tr),
                    _buildHeaderCell('sales_status'.tr),
                    _buildHeaderCell(''),
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
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(1.5),
                  5: FlexColumnWidth(1.2),
                  6: FlexColumnWidth(1),
                },
                children: [
                  ...sales.map((sale) => _buildSaleRow(context, sale)),
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

  TableRow _buildSaleRow(BuildContext context, Sale sale) {
    final dateFormat = DateFormat('dd/MM/yy HH:mm');
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
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Date
        _buildDataCell(
          Text(
            dateFormat.format(sale.dateCreation),
            style: const TextStyle(fontSize: 13),
          ),
        ),

        // Montant
        _buildDataCell(
          Text(
            '${sale.montantFinal.toStringAsFixed(0)} F',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),

        // Payé
        _buildDataCell(
          Text(
            '${sale.montantPaye.toStringAsFixed(0)} F',
            style: TextStyle(
              fontSize: 13,
              color: sale.montantPaye >= sale.montantFinal ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ),

        // Statut
        _buildDataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(sale.statut),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              sale.statut,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getStatusTextColor(sale.statut),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Actions
        _buildDataCell(
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => onTap(sale),
            tooltip: 'sales_view_details'.tr,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'terminée':
        return Colors.green[50]!;
      case 'annulée':
        return Colors.red[50]!;
      case 'en attente':
        return Colors.orange[50]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'terminée':
        return Colors.green[700]!;
      case 'annulée':
        return Colors.red[700]!;
      case 'en attente':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
