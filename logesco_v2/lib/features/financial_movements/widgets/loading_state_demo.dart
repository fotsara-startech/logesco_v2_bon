import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/financial_movement_controller.dart';
import '../widgets/loading_state_widget.dart';

/// Widget de démonstration pour les états de chargement
class LoadingStateDemo extends StatelessWidget {
  const LoadingStateDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FinancialMovementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('États de chargement'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LoadingStateBar(
                loadingState: controller.loadingState,
              ),
              Expanded(
                child: LoadingStateWidget(
                  loadingState: controller.loadingState,
                  showProgressBar: true,
                  showLoadingMessage: true,
                  onRetry: () => controller.loadMovements(forceRefresh: true),
                  child: _buildContent(controller),
                ),
              ),
            ],
          ),
          FloatingLoadingIndicator(
            loadingState: controller.loadingState,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FinancialMovementController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Informations sur l'état actuel
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'État actuel',
                    style: Theme.of(Get.context!).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${controller.currentLoadingState.type}'),
                          if (controller.currentLoadingState.message != null) Text('Message: ${controller.currentLoadingState.message}'),
                          if (controller.currentLoadingState.operation != null) Text('Opération: ${controller.currentLoadingState.operation}'),
                          if (controller.currentLoadingState.hasProgress) Text('Progrès: ${controller.progressPercentage}%'),
                          Text('Est en chargement: ${controller.currentLoadingState.isLoading}'),
                          Text('Est une erreur: ${controller.currentLoadingState.isError}'),
                          Text('Est un succès: ${controller.currentLoadingState.isSuccess}'),
                        ],
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Boutons de test
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions de test',
                    style: Theme.of(Get.context!).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => controller.loadMovements(),
                        child: const Text('Charger'),
                      ),
                      ElevatedButton(
                        onPressed: () => controller.loadMovements(forceRefresh: true),
                        child: const Text('Actualiser'),
                      ),
                      ElevatedButton(
                        onPressed: () => controller.loadMovements(append: true),
                        child: const Text('Charger plus'),
                      ),
                      ElevatedButton(
                        onPressed: () => _simulateCreate(controller),
                        child: const Text('Simuler création'),
                      ),
                      ElevatedButton(
                        onPressed: () => _simulateUpdate(controller),
                        child: const Text('Simuler mise à jour'),
                      ),
                      ElevatedButton(
                        onPressed: () => _simulateDelete(controller),
                        child: const Text('Simuler suppression'),
                      ),
                      ElevatedButton(
                        onPressed: () => _simulateError(controller),
                        child: const Text('Simuler erreur'),
                      ),
                      ElevatedButton(
                        onPressed: () => controller.setIdle(),
                        child: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Liste des mouvements
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mouvements (${controller.movements.length})',
                      style: Theme.of(Get.context!).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Obx(() => ListView.builder(
                            itemCount: controller.movements.length,
                            itemBuilder: (context, index) {
                              final movement = controller.movements[index];
                              return ListTile(
                                title: Text(movement.description),
                                subtitle: Text('${movement.montant} FCFA'),
                                trailing: Text(movement.date.toString().split(' ')[0]),
                              );
                            },
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateCreate(FinancialMovementController controller) {
    controller.setCreating(
      message: 'Création d\'un nouveau mouvement...',
      operation: 'simulateCreate',
    );

    Future.delayed(const Duration(seconds: 2), () {
      controller.setSuccess(
        message: 'Mouvement créé avec succès',
        operation: 'simulateCreate',
      );

      Future.delayed(const Duration(seconds: 2), () {
        controller.setIdle();
      });
    });
  }

  void _simulateUpdate(FinancialMovementController controller) {
    controller.setUpdating(
      message: 'Mise à jour du mouvement...',
      operation: 'simulateUpdate',
    );

    Future.delayed(const Duration(seconds: 2), () {
      controller.setSuccess(
        message: 'Mouvement mis à jour avec succès',
        operation: 'simulateUpdate',
      );

      Future.delayed(const Duration(seconds: 2), () {
        controller.setIdle();
      });
    });
  }

  void _simulateDelete(FinancialMovementController controller) {
    controller.setDeleting(
      message: 'Suppression du mouvement...',
      operation: 'simulateDelete',
    );

    Future.delayed(const Duration(seconds: 2), () {
      controller.setSuccess(
        message: 'Mouvement supprimé avec succès',
        operation: 'simulateDelete',
      );

      Future.delayed(const Duration(seconds: 2), () {
        controller.setIdle();
      });
    });
  }

  void _simulateError(FinancialMovementController controller) {
    controller.setError(
      message: 'Erreur de simulation pour tester l\'affichage',
      operation: 'simulateError',
      metadata: {'errorCode': 'SIMULATION_ERROR'},
    );
  }
}
