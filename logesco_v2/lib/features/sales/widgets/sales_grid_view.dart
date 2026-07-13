import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/sale.dart';

class SalesGridView extends StatelessWidget {
  final List<Sale> sales;
  final void Function(Sale) onTap;
  final bool hasMoreData;
  final VoidCallback onLoadMore;

  const SalesGridView({
    super.key,
    required this.sales,
    required this.onTap,
    required this.hasMoreData,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 155,
      ),
      itemCount: sales.length + (hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sales.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
          return const Center(child: CircularProgressIndicator());
        }
        final sale = sales[index];
        return _SaleGridCard(sale: sale, onTap: () => onTap(sale));
      },
    );
  }
}

class _SaleGridCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;

  const _SaleGridCard({required this.sale, required this.onTap});

  Color get _statusColor => sale.isCancelled ? Colors.red : Colors.green;

  String get _formattedDate {
    final d = sale.dateCreation;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numéro + statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sale.numeroVente,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Client
              if (sale.client != null)
                Text(
                  '${sale.client!.nom} ${sale.client!.prenom ?? ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'sales_walk_in'.tr,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic),
                ),

              const Spacer(),

              // Montant
              Text(
                '${sale.montantFinal.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _statusColor,
                ),
              ),

              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 11, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text(
                    _formattedDate,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
