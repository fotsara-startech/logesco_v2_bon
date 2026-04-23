import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'features/boutiques/controllers/boutique_controller.dart';
import 'core/services/boutique_context_service.dart';
import 'features/financial_movements/models/financial_movement_form.dart';
import 'features/financial_movements/services/financial_movement_service.dart';

/// Page de debug pour tester le contexte boutique
class DebugBoutiqueContextPage extends StatefulWidget {
  const DebugBoutiqueContextPage({super.key});

  @override
  State<DebugBoutiqueContextPage> createState() => _DebugBoutiqueContextPageState();
}

class _DebugBoutiqueContextPageState extends State<DebugBoutiqueContextPage> {
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Diagnostic en cours...\n\n';
    });

    final buffer = StringBuffer();
    buffer.writeln('=== DIAGNOSTIC CONTEXTE BOUTIQUE ===\n');

    try {
      // 1. Vérifier si BoutiqueController existe
      buffer.writeln('1. Test BoutiqueController:');
      try {
        final boutiqueController = Get.find<BoutiqueController>();
        buffer.writeln('   ✅ BoutiqueController trouvé');
        buffer.writeln('   - Boutiques chargées: ${boutiqueController.boutiques.length}');
        buffer.writeln('   - Boutique active: ${boutiqueController.boutiquesActive.value?.nom ?? "null"}');
        buffer.writeln('   - ID boutique active: ${boutiqueController.activeBoutiqueId ?? "null"}');
        buffer.writeln('   - Multi-boutique: ${boutiqueController.isMultiBoutique}');

        // Lister toutes les boutiques
        if (boutiqueController.boutiques.isNotEmpty) {
          buffer.writeln('   - Liste des boutiques:');
          for (final boutique in boutiqueController.boutiques) {
            buffer.writeln('     * ${boutique.nom} (ID: ${boutique.id}, Principale: ${boutique.estPrincipale}, Active: ${boutique.isActive})');
          }
        }
      } catch (e) {
        buffer.writeln('   ❌ BoutiqueController non trouvé: $e');
      }

      buffer.writeln('\n2. Test BoutiqueContextService:');
      try {
        final contextService = Get.find<BoutiqueContextService>();
        buffer.writeln('   ✅ BoutiqueContextService trouvé');
        buffer.writeln('   - ID boutique active: ${contextService.activeBoutiqueId ?? "null"}');
        buffer.writeln('   - A boutique active: ${contextService.hasBoutiqueActive}');

        // Test d'injection
        final testParams = {'test': 'value'};
        final injectedParams = contextService.injectBoutiqueId(testParams);
        buffer.writeln('   - Test injection: $injectedParams');
      } catch (e) {
        buffer.writeln('   ❌ BoutiqueContextService non trouvé: $e');
      }

      buffer.writeln('\n3. Test méthode statique:');
      try {
        final staticId = BoutiqueController.getActiveBoutiqueId();
        buffer.writeln('   - ID via méthode statique: ${staticId ?? "null"}');
      } catch (e) {
        buffer.writeln('   ❌ Erreur méthode statique: $e');
      }

      buffer.writeln('\n4. Test FinancialMovementService:');
      try {
        final financialService = Get.find<FinancialMovementService>();
        buffer.writeln('   ✅ FinancialMovementService trouvé');

        // Test de création d'un mouvement fictif
        buffer.writeln('   - Test création mouvement fictif...');
        final testForm = FinancialMovementForm(
          reference: 'TEST-DEBUG',
          montant: 1000.0,
          categorieId: 1,
          description: 'Test debug contexte boutique',
          date: DateTime.now(),
        );

        // Vérifier les données avant envoi
        final formData = testForm.toJson();
        buffer.writeln('   - Données formulaire: $formData');

        // Simuler l'injection du boutiqueId
        try {
          final contextService = Get.find<BoutiqueContextService>();
          final injectedData = contextService.injectBoutiqueId(formData);
          buffer.writeln('   - Données après injection: $injectedData');
        } catch (e) {
          buffer.writeln('   ❌ Erreur injection: $e');
        }
      } catch (e) {
        buffer.writeln('   ❌ FinancialMovementService non trouvé: $e');
      }

      buffer.writeln('\n5. Test GetStorage:');
      try {
        final storage = GetStorage();
        final storedBoutiqueId = storage.read('active_boutique_id');
        buffer.writeln('   ✅ GetStorage accessible');
        buffer.writeln('   - ID stocké: $storedBoutiqueId (type: ${storedBoutiqueId.runtimeType})');
      } catch (e) {
        buffer.writeln('   ⚠️ GetStorage: $e');
        // Essayer via Get.find si disponible
        try {
          if (Get.isRegistered<GetStorage>()) {
            final storage = Get.find<GetStorage>();
            final storedBoutiqueId = storage.read('active_boutique_id');
            buffer.writeln('   ✅ GetStorage via Get.find');
            buffer.writeln('   - ID stocké: $storedBoutiqueId (type: ${storedBoutiqueId.runtimeType})');
          }
        } catch (e2) {
          buffer.writeln('   ❌ GetStorage totalement inaccessible: $e2');
        }
      }

      buffer.writeln('\n6. Test chargement boutiques:');
      try {
        final boutiqueController = Get.find<BoutiqueController>();
        buffer.writeln('   - Rechargement des boutiques...');
        await boutiqueController.loadBoutiques();
        buffer.writeln('   ✅ Boutiques rechargées');
        buffer.writeln('   - Nouvelles données:');
        buffer.writeln('     * Nombre: ${boutiqueController.boutiques.length}');
        buffer.writeln('     * Active: ${boutiqueController.boutiquesActive.value?.nom ?? "null"}');
        buffer.writeln('     * ID active: ${boutiqueController.activeBoutiqueId ?? "null"}');
      } catch (e) {
        buffer.writeln('   ❌ Erreur rechargement: $e');
      }
    } catch (e) {
      buffer.writeln('❌ Erreur générale: $e');
    }

    buffer.writeln('\n=== FIN DIAGNOSTIC ===');

    setState(() {
      _debugInfo = buffer.toString();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Contexte Boutique'),
        actions: [
          IconButton(
            onPressed: _runDiagnostics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      _debugInfo,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testCreateMovement,
                    child: const Text('Test Création Mouvement'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testSwitchBoutique,
                    child: const Text('Test Switch Boutique'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testCreateMovement() async {
    try {
      final contextService = Get.find<BoutiqueContextService>();
      final financialService = Get.find<FinancialMovementService>();

      print('🧪 Test création mouvement...');
      print('   Boutique ID avant: ${contextService.activeBoutiqueId}');

      final form = FinancialMovementForm(
        reference: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
        montant: 500.0,
        categorieId: 1,
        description: 'Test debug création mouvement',
        date: DateTime.now(),
      );

      final formData = form.toJson();
      print('   Données formulaire: $formData');

      final injectedData = contextService.injectBoutiqueId(formData);
      print('   Données injectées: $injectedData');

      // Tentative de création (sera probablement en erreur mais on verra les logs)
      try {
        await financialService.createMovement(form);
        print('   ✅ Mouvement créé avec succès');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Mouvement de test créé avec succès'),
              backgroundColor: Colors.green[100],
            ),
          );
        }
      } catch (e) {
        print('   ❌ Erreur création: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la création: $e'),
              backgroundColor: Colors.red[100],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur test: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur test: $e'),
            backgroundColor: Colors.red[100],
          ),
        );
      }
    }

    // Relancer le diagnostic
    await _runDiagnostics();
  }

  Future<void> _testSwitchBoutique() async {
    try {
      final boutiqueController = Get.find<BoutiqueController>();

      if (boutiqueController.boutiques.isEmpty) {
        await boutiqueController.loadBoutiques();
      }

      if (boutiqueController.boutiques.isNotEmpty) {
        final firstBoutique = boutiqueController.boutiques.first;
        print('🧪 Test switch vers: ${firstBoutique.nom} (ID: ${firstBoutique.id})');

        boutiqueController.switchBoutique(firstBoutique);

        print('   Boutique active après switch: ${boutiqueController.boutiquesActive.value?.nom}');
        print('   ID après switch: ${boutiqueController.activeBoutiqueId}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Basculé vers: ${firstBoutique.nom}'),
              backgroundColor: Colors.blue[100],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Aucune boutique disponible'),
              backgroundColor: Colors.orange[100],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur switch: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur switch: $e'),
            backgroundColor: Colors.red[100],
          ),
        );
      }
    }

    // Relancer le diagnostic
    await _runDiagnostics();
  }
}
