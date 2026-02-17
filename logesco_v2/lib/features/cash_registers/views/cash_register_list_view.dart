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
        title: const Text('Gestion des Caisses'),
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
          hintText: 'Rechercher une caisse...',
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
                'Aucune caisse trouvée',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez votre première caisse pour commencer',
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
                  'Solde: ${CurrencyUtils.formatAmount(cashRegister.soldeActuel)}',
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
              const PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.lock_open, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Ouvrir'),
                  ],
                ),
              ),
            if (cashRegister.isOpen)
              const PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Fermer'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
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
    switch (status) {
      case 'Ouverte':
        return Colors.green;
      case 'Fermée':
        return Colors.orange;
      case 'Inactive':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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
            if (cashRegister.description != null) Text('Description: ${cashRegister.description}'),
            const SizedBox(height: 8),
            Text('Statut: ${cashRegister.status}'),
            const SizedBox(height: 8),
            Text('Solde initial: ${CurrencyUtils.formatAmount(cashRegister.soldeInitial)}'),
            Text('Solde actuel: ${CurrencyUtils.formatAmount(cashRegister.soldeActuel)}'),
            Text('Différence: ${CurrencyUtils.formatDifference(cashRegister.soldeActuel, cashRegister.soldeInitial)}'),
            if (cashRegister.nomUtilisateur != null) ...[
              const SizedBox(height: 8),
              Text('Utilisateur: ${cashRegister.nomUtilisateur}'),
            ],
            if (cashRegister.dateOuverture != null) ...[
              const SizedBox(height: 8),
              Text('Ouverte le: ${_formatDateTime(cashRegister.dateOuverture!)}'),
            ],
            if (cashRegister.dateFermeture != null) ...[
              const SizedBox(height: 8),
              Text('Fermée le: ${_formatDateTime(cashRegister.dateFermeture!)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showOpenCashRegisterDialog(CashRegister cashRegister, CashRegisterController controller) {
    final TextEditingController amountController = TextEditingController(text: cashRegister.soldeInitial.toStringAsFixed(2));

    Get.dialog(
      AlertDialog(
        title: Text('Ouvrir ${cashRegister.nom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le montant initial en caisse:'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Montant initial (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null) {
                Get.back();
                controller.openCashRegister(cashRegister.id!, amount);
              }
            },
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  void _showCloseCashRegisterDialog(CashRegister cashRegister, CashRegisterController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('Fermer ${cashRegister.nom}'),
        content: const Text('Êtes-vous sûr de vouloir fermer cette caisse ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
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
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
