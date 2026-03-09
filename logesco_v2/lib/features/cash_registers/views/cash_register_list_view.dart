import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/cash_register_controller.dart';
import '../models/cash_register_model.dart';
import 'cash_register_form_view.dart';
import '../../../core/utils/currency_utils.dart';

/// Vue de la liste des caisses
class CashRegisterListView extends StatelessWidget {
  const CashRegisterListView({super.key});

  @override
  Widget build(BuildContext context) {
    final CashRegisterController controller = Get.find<CashRegisterController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('cash_register_management'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadCashRegisters(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(controller),

          // Liste des caisses
          Expanded(
            child: _buildCashRegistersList(controller),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewCashRegister(controller),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(CashRegisterController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => controller.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'cash_register_search'.tr,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildCashRegistersList(CashRegisterController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final cashRegisters = controller.filteredCashRegisters;

      if (cashRegisters.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.point_of_sale,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'cash_register_no_registers'.tr,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'cash_register_create_first'.tr,
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cashRegisters.length,
        itemBuilder: (context, index) {
          final cashRegister = cashRegisters[index];
          return _buildCashRegisterCard(cashRegister, controller);
        },
      );
    });
  }

  Widget _buildCashRegisterCard(CashRegister cashRegister, CashRegisterController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cashRegister.isOpen
              ? Colors.green.shade100
              : cashRegister.isActive
                  ? Colors.blue.shade100
                  : Colors.grey.shade100,
          child: Icon(
            cashRegister.isOpen ? Icons.lock_open : Icons.point_of_sale,
            color: cashRegister.isOpen
                ? Colors.green.shade700
                : cashRegister.isActive
                    ? Colors.blue.shade700
                    : Colors.grey.shade700,
          ),
        ),
        title: Text(
          cashRegister.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cashRegister.description != null && cashRegister.description!.isNotEmpty) Text(cashRegister.description!),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(cashRegister.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cashRegister.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(cashRegister.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'cash_register_balance_label'.trParams({'amount': CurrencyUtils.formatAmount(cashRegister.soldeActuel)}),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, cashRegister, controller),
          itemBuilder: (context) => [
            if (!cashRegister.isOpen)
              PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    const Icon(Icons.lock_open, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('cash_register_open_action'.tr),
                  ],
                ),
              ),
            if (cashRegister.isOpen)
              PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('cash_register_close_action'.tr),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text('cash_register_edit_action'.tr),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('cash_register_delete_action'.tr, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showCashRegisterDetails(cashRegister),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'cash_register_status_open'.tr || status == 'Ouverte') {
      return Colors.green;
    } else if (status == 'cash_register_status_closed'.tr || status == 'Fermée') {
      return Colors.orange;
    } else if (status == 'cash_register_status_inactive'.tr || status == 'Inactive') {
      return Colors.grey;
    }
    return Colors.blue;
  }

  void _createNewCashRegister(CashRegisterController controller) {
    controller.selectCashRegister(null);
    Get.to(() => const CashRegisterFormView());
  }

  void _handleMenuAction(String action, CashRegister cashRegister, CashRegisterController controller) {
    switch (action) {
      case 'open':
        _showOpenCashRegisterDialog(cashRegister, controller);
        break;
      case 'close':
        _showCloseCashRegisterDialog(cashRegister, controller);
        break;
      case 'edit':
        controller.selectCashRegister(cashRegister);
        Get.to(() => const CashRegisterFormView());
        break;
      case 'delete':
        controller.confirmDeleteCashRegister(cashRegister);
        break;
    }
  }

  void _showCashRegisterDetails(CashRegister cashRegister) {
    Get.dialog(
      AlertDialog(
        title: Text(cashRegister.nom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cashRegister.description != null) Text('cash_register_description_label'.trParams({'description': cashRegister.description!})),
            const SizedBox(height: 8),
            Text('cash_register_status_label'.trParams({'status': cashRegister.status})),
            const SizedBox(height: 8),
            Text('cash_register_initial_balance_label'.trParams({'amount': CurrencyUtils.formatAmount(cashRegister.soldeInitial)})),
            Text('cash_register_current_balance_label'.trParams({'amount': CurrencyUtils.formatAmount(cashRegister.soldeActuel)})),
            Text('cash_register_difference_label'.trParams({'amount': CurrencyUtils.formatDifference(cashRegister.soldeActuel, cashRegister.soldeInitial)})),
            if (cashRegister.nomUtilisateur != null) ...[
              const SizedBox(height: 8),
              Text('cash_register_user_label'.trParams({'user': cashRegister.nomUtilisateur!})),
            ],
            if (cashRegister.dateOuverture != null) ...[
              const SizedBox(height: 8),
              Text('cash_register_opened_on'.trParams({'date': _formatDateTime(cashRegister.dateOuverture!)})),
            ],
            if (cashRegister.dateFermeture != null) ...[
              const SizedBox(height: 8),
              Text('cash_register_closed_on'.trParams({'date': _formatDateTime(cashRegister.dateFermeture!)})),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  void _showOpenCashRegisterDialog(CashRegister cashRegister, CashRegisterController controller) {
    final TextEditingController amountController = TextEditingController(text: cashRegister.soldeInitial.toStringAsFixed(2));

    Get.dialog(
      AlertDialog(
        title: Text('cash_register_open_dialog_title'.trParams({'name': cashRegister.nom})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('cash_register_open_dialog_message'.tr),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'cash_register_initial_amount'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null) {
                Get.back();
                controller.openCashRegister(cashRegister.id!, amount);
              }
            },
            child: Text('cash_register_open_action'.tr),
          ),
        ],
      ),
    );
  }

  void _showCloseCashRegisterDialog(CashRegister cashRegister, CashRegisterController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('cash_register_close_dialog_title'.trParams({'name': cashRegister.nom})),
        content: Text('cash_register_close_dialog_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.closeCashRegister(cashRegister.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('cash_register_close_action'.tr),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
