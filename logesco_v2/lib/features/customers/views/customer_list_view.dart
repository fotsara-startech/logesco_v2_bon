import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/permission_widget.dart';
import '../../../core/services/permission_service.dart';
import '../controllers/customer_controller.dart';
import '../models/customer.dart';

/// Vue de la liste des clients
class CustomerListView extends GetView<CustomerController> {
  const CustomerListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          PermissionWidget(
            module: 'customers',
            privilege: 'CREATE',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: controller.goToCreateCustomer,
              tooltip: 'Ajouter un client',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: controller.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, prénom, téléphone ou email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: controller.clearSearch,
                      )
                    : const SizedBox.shrink()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Liste des clients
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.customers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.hasError.value && controller.customers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.refreshCustomers,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.customers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun client trouvé',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Commencez par ajouter votre premier client',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PermissionWidget(
                        module: 'customers',
                        privilege: 'CREATE',
                        child: ElevatedButton.icon(
                          onPressed: controller.goToCreateCustomer,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un client'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshCustomers,
                child: ListView.builder(
                  itemCount: controller.customers.length + (controller.hasMoreData.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.customers.length) {
                      // Indicateur de chargement pour la pagination
                      if (controller.isLoadingMore.value) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        // Charger plus d'éléments quand on arrive à la fin
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          controller.loadMoreCustomers();
                        });
                        return const SizedBox.shrink();
                      }
                    }

                    final customer = controller.customers[index];
                    return _CustomerListItem(
                      customer: customer,
                      onTap: () => controller.goToCustomerDetail(customer),
                      onEdit: () => controller.goToEditCustomer(customer),
                      onDelete: () => controller.deleteCustomer(customer),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Widget pour un élément de la liste des clients
class _CustomerListItem extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerListItem({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          customer.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.telephone != null) Text('Tél: ${customer.telephone}'),
            if (customer.email != null) Text('Email: ${customer.email}'),
            if (customer.adresse != null) Text('Adresse: ${customer.adresse}'),
          ],
        ),
        trailing: _buildActionsMenu(context, onEdit, onDelete),
        onTap: onTap,
      ),
    );
  }

  /// Construit le menu d'actions avec permissions
  Widget _buildActionsMenu(BuildContext context, VoidCallback onEdit, VoidCallback onDelete) {
    final permissionService = Get.find<PermissionService>();
    final canUpdate = permissionService.hasPermission('customers', 'UPDATE');
    final canDelete = permissionService.hasPermission('customers', 'DELETE');

    if (!canUpdate && !canDelete) {
      return const SizedBox.shrink();
    }

    final items = <PopupMenuEntry<String>>[];

    if (canUpdate) {
      items.add(
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Modifier'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    if (canDelete) {
      items.add(
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Supprimer', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => items,
    );
  }
}
