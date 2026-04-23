import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/boutique_controller.dart';
import '../models/boutique_model.dart';
import '../services/boutique_service.dart';
import 'stock_transfert_page.dart';

class BoutiquesManagementPage extends StatelessWidget {
  const BoutiquesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BoutiqueController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des boutiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transferts de stock',
            onPressed: () => Get.to(() => const StockTransfertPage()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadBoutiques,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBoutiqueForm(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle boutique'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.boutiques.isEmpty) {
          return const Center(child: Text('Aucune boutique'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.boutiques.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _BoutiqueCard(
            boutique: controller.boutiques[i],
            isActive: controller.boutiquesActive.value?.id == controller.boutiques[i].id,
            onSwitch: () => controller.switchBoutique(controller.boutiques[i]),
            onEdit: () => _showBoutiqueForm(context, controller, boutique: controller.boutiques[i]),
            onDelete: controller.boutiques[i].estPrincipale ? null : () => _confirmDelete(context, controller, controller.boutiques[i]),
            onManageUsers: () => _showUsersDialog(context, controller, controller.boutiques[i]),
          ),
        );
      }),
    );
  }

  void _showBoutiqueForm(BuildContext context, BoutiqueController controller, {Boutique? boutique}) {
    final nomCtrl = TextEditingController(text: boutique?.nom);
    final adresseCtrl = TextEditingController(text: boutique?.adresse);
    final telCtrl = TextEditingController(text: boutique?.telephone);
    final emailCtrl = TextEditingController(text: boutique?.email);
    final descCtrl = TextEditingController(text: boutique?.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(boutique == null ? 'Nouvelle boutique' : 'Modifier la boutique'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *', prefixIcon: Icon(Icons.store)),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(controller: adresseCtrl, decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on))),
                const SizedBox(height: 12),
                TextFormField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 12),
                TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 12),
                TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes)), maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              bool ok;
              if (boutique == null) {
                final result = await controller.createBoutique(
                  nom: nomCtrl.text.trim(),
                  adresse: adresseCtrl.text.trim().isEmpty ? null : adresseCtrl.text.trim(),
                  telephone: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                ok = result != null;
              } else {
                ok = await controller.updateBoutique(boutique.id, {
                  'nom': nomCtrl.text.trim(),
                  'adresse': adresseCtrl.text.trim().isEmpty ? null : adresseCtrl.text.trim(),
                  'telephone': telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
                  'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                });
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Boutique enregistrée' : controller.errorMessage.value),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BoutiqueController controller, Boutique boutique) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Désactiver la boutique'),
        content: Text('Désactiver "${boutique.nom}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await controller.deleteBoutique(boutique.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  void _showUsersDialog(BuildContext context, BoutiqueController controller, Boutique boutique) {
    Get.to(() => _BoutiqueUsersPage(boutique: boutique, controller: controller));
  }
}

class _BoutiqueCard extends StatelessWidget {
  final Boutique boutique;
  final bool isActive;
  final VoidCallback onSwitch;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onManageUsers;

  const _BoutiqueCard({
    required this.boutique,
    required this.isActive,
    required this.onSwitch,
    required this.onEdit,
    this.onDelete,
    required this.onManageUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[200],
          child: Icon(boutique.estPrincipale ? Icons.store : Icons.storefront, color: isActive ? Colors.white : Colors.grey[600]),
        ),
        title: Row(
          children: [
            Text(boutique.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (boutique.estPrincipale) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)),
                child: Text('Principale', style: TextStyle(fontSize: 10, color: Colors.amber[800])),
              ),
            ],
            if (!boutique.isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
                child: Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.red[800])),
              ),
            ],
          ],
        ),
        subtitle: boutique.adresse != null ? Text(boutique.adresse!, style: const TextStyle(fontSize: 12)) : null,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'switch') onSwitch();
            if (v == 'edit') onEdit();
            if (v == 'users') onManageUsers();
            if (v == 'delete') onDelete?.call();
          },
          itemBuilder: (_) => [
            if (!isActive) const PopupMenuItem(value: 'switch', child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Activer'))),
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Modifier'))),
            const PopupMenuItem(value: 'users', child: ListTile(leading: Icon(Icons.people), title: Text('Utilisateurs'))),
            if (onDelete != null) const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Désactiver', style: TextStyle(color: Colors.red)))),
          ],
        ),
      ),
    );
  }
}

class _BoutiqueUsersPage extends StatefulWidget {
  final Boutique boutique;
  final BoutiqueController controller;

  const _BoutiqueUsersPage({required this.boutique, required this.controller});

  @override
  State<_BoutiqueUsersPage> createState() => _BoutiqueUsersPageState();
}

class _BoutiqueUsersPageState extends State<_BoutiqueUsersPage> {
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = Get.find<BoutiqueService>();
      final list = await service.getBoutiqueUsers(widget.boutique.id);
      setState(() => _assignments = list
          .map((a) => {
                'id': a.id,
                'utilisateurId': a.utilisateurId,
                'nom': a.utilisateur?['nomUtilisateur'] ?? 'Utilisateur #${a.utilisateurId}',
                'email': a.utilisateur?['email'] ?? '',
                'role': a.role?.displayName ?? 'Aucun rôle',
                'isActive': a.isActive,
              })
          .toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Utilisateurs — ${widget.boutique.nom}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? const Center(child: Text('Aucun utilisateur assigné'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  itemBuilder: (_, i) {
                    final a = _assignments[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(a['nom'] as String),
                        subtitle: Text('${a['email']} • ${a['role']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () async {
                            await widget.controller.removeUser(widget.boutique.id, a['utilisateurId'] as int);
                            _load();
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// Extension pour accéder au service depuis la page users
extension _BoutiqueControllerExt on BoutiqueController {
  Future<void> removeUser(int boutiqueId, int userId) => Get.find<BoutiqueService>().removeUser(boutiqueId, userId);
}
