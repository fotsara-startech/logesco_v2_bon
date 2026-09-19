import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/commercial_controller.dart';
import '../models/commercial.dart';
import '../../../core/widgets/permission_widget.dart';
import '../../../shared/widgets/loading_widget.dart';

/// Vue de gestion des commerciaux terrain (liste + accès à la création de
/// villes/zones). Fonctionnalité optionnelle : n'apparaît dans le menu que
/// pour les clients qui l'utilisent (voir modern_dashboard_page.dart).
class CommercialListView extends StatelessWidget {
  const CommercialListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommercialController());

    return PermissionWidget(
      module: 'commercials',
      privilege: 'READ',
      showFallback: true,
      fallback: Scaffold(
        appBar: AppBar(title: const Text('Commerciaux')),
        body: const Center(child: Text('Accès refusé')),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Commerciaux terrain'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadAll(),
              tooltip: 'Rafraîchir',
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const LoadingWidget();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un commercial...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onChanged: controller.updateSearchQuery,
                ),
              ),
              Expanded(
                child: controller.commerciauxFiltres.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.badge_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun commercial pour le moment',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: controller.commerciauxFiltres.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final commercial = controller.commerciauxFiltres[index];
                          return _buildTile(context, controller, commercial);
                        },
                      ),
              ),
            ],
          );
        }),
        floatingActionButton: PermissionWidget(
          module: 'commercials',
          privilege: 'CREATE',
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Get.toNamed('/commercials/create');
              if (result == null) controller.loadAll();
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Nouveau commercial'),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, CommercialController controller, Commercial commercial) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: commercial.isActive ? Colors.blue.shade100 : Colors.grey.shade300,
        child: Icon(Icons.badge_outlined, color: commercial.isActive ? Colors.blue.shade700 : Colors.grey.shade600),
      ),
      title: Text(commercial.nomComplet, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text([
        if (commercial.zone != null) '${commercial.zone!.nom}, ${commercial.zone!.ville?.nom ?? ''}',
        if (commercial.telephone != null) commercial.telephone!,
      ].where((s) => s.isNotEmpty).join(' · ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!commercial.isActive)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Inactif', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          PermissionWidget(
            module: 'commercials',
            privilege: 'UPDATE',
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () async {
                final result = await Get.toNamed('/commercials/${commercial.id}/edit', arguments: commercial);
                if (result == null) controller.loadAll();
              },
            ),
          ),
          PermissionWidget(
            module: 'commercials',
            privilege: 'DELETE',
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => controller.deleteCommercial(commercial),
            ),
          ),
        ],
      ),
    );
  }
}
