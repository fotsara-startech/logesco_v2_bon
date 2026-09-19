import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/commercial_form_controller.dart';
import '../controllers/commercial_controller.dart';
import '../models/ville.dart';
import '../models/zone.dart';

/// Formulaire de création/modification d'un commercial terrain.
///
/// La ville et la zone sont des listes fermées (voir contexte du module) :
/// on choisit une ville existante, ou on en crée une à la volée, puis on
/// choisit/crée une zone rattachée à cette ville.
class CommercialFormView extends StatelessWidget {
  const CommercialFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommercialFormController());
    final commercialController = Get.find<CommercialController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditing.value ? 'Modifier le commercial' : 'Nouveau commercial')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.nomController,
              decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.prenomController,
              decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.telephoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Localisation', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Obx(() => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Ville>(
                        value: controller.selectedVille.value,
                        decoration: const InputDecoration(labelText: 'Ville *', border: OutlineInputBorder()),
                        items: commercialController.villes
                            .map((v) => DropdownMenuItem(value: v, child: Text(v.nom)))
                            .toList(),
                        onChanged: controller.setVille,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Nouvelle ville',
                      onPressed: () async {
                        final ville = await commercialController.createVilleDialog();
                        if (ville != null) controller.setVille(ville);
                      },
                    ),
                  ],
                )),
            const SizedBox(height: 12),

            Obx(() => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Zone>(
                        value: controller.selectedZone.value,
                        decoration: const InputDecoration(labelText: 'Zone (quartier) *', border: OutlineInputBorder()),
                        items: controller.zonesDisponibles
                            .map((z) => DropdownMenuItem(value: z, child: Text(z.nom)))
                            .toList(),
                        onChanged: controller.selectedVille.value == null ? null : controller.setZone,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Nouvelle zone',
                      onPressed: controller.selectedVille.value == null
                          ? null
                          : () async {
                              final zone = await commercialController.createZoneDialog(controller.selectedVille.value!.id);
                              if (zone != null) controller.setZone(zone);
                            },
                    ),
                  ],
                )),
            if (controller.selectedVille.value == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Choisissez une ville pour voir ses zones', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            const SizedBox(height: 20),

            Obx(() => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Actif'),
                  subtitle: const Text('Un commercial inactif n\'apparaît plus dans le sélecteur de vente'),
                  value: controller.isActive.value,
                  onChanged: (v) => controller.isActive.value = v,
                )),
            const SizedBox(height: 24),

            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.saveCommercial,
                    child: controller.isLoading.value
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Enregistrer'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
