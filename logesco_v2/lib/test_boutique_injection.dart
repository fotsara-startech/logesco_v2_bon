import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/services/http_boutique_service.dart';
import 'core/services/boutique_context_service.dart';
import 'features/financial_movements/models/financial_movement_form.dart';
import 'features/financial_movements/services/financial_movement_service.dart';

/// Test spécifique pour vérifier l'injection du boutiqueId
class TestBoutiqueInjectionPage extends StatefulWidget {
  const TestBoutiqueInjectionPage({super.key});

  @override
  State<TestBoutiqueInjectionPage> createState() => _TestBoutiqueInjectionPageState();
}

class _TestBoutiqueInjectionPageState extends State<TestBoutiqueInjectionPage> {
  String _results = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Injection BoutiqueId'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testInjection,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Tester Injection BoutiqueId'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _results,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testInjection() async {
    setState(() {
      _isLoading = true;
      _results = 'Test en cours...\n\n';
    });

    final buffer = StringBuffer();
    buffer.writeln('=== TEST INJECTION BOUTIQUE ID ===\n');

    try {
      // 1. Vérifier le contexte
      final contextService = Get.find<BoutiqueContextService>();
      final boutiqueId = contextService.activeBoutiqueId;
      buffer.writeln('1. Boutique ID actuel: ${boutiqueId ?? "null"}');

      if (boutiqueId == null) {
        buffer.writeln('❌ ERREUR: Aucune boutique active !');
        setState(() {
          _results = buffer.toString();
          _isLoading = false;
        });
        return;
      }

      // 2. Test du service HTTP
      buffer.writeln('\n2. Test HttpBoutiqueService:');
      try {
        final httpService = Get.find<HttpBoutiqueService>();
        buffer.writeln('   ✅ Service trouvé');

        // Test d'injection dans les données
        final testData = {'test': 'value', 'montant': 1000.0, 'description': 'Test injection'};

        buffer.writeln('   - Données originales: $testData');

        // Le service HTTP devrait automatiquement injecter le boutiqueId
        // On ne peut pas tester directement sans faire un vrai appel HTTP
        // Mais on peut vérifier la logique d'injection
      } catch (e) {
        buffer.writeln('   ❌ Erreur: $e');
      }

      // 3. Test de création de mouvement avec logs détaillés
      buffer.writeln('\n3. Test création mouvement avec logs:');
      try {
        final financialService = Get.find<FinancialMovementService>();

        final form = FinancialMovementForm(
          reference: 'TEST-INJECTION-${DateTime.now().millisecondsSinceEpoch}',
          montant: 999.0,
          categorieId: 1,
          description: 'Test injection définitive boutiqueId',
          date: DateTime.now(),
          notes: 'Test pour vérifier que boutiqueId arrive en base',
        );

        buffer.writeln('   - Formulaire créé: ${form.toJson()}');
        buffer.writeln('   - Tentative de création...');

        // Capturer les logs de la console
        print('🧪 === DÉBUT TEST INJECTION ===');
        print('🧪 BoutiqueId attendu: $boutiqueId');

        try {
          await financialService.createMovement(form);
          buffer.writeln('   ✅ Mouvement créé avec succès !');
          buffer.writeln('   📋 Vérifiez maintenant en base de données si boutiqueId = $boutiqueId');
        } catch (e) {
          buffer.writeln('   ❌ Erreur création: $e');
          buffer.writeln('   📋 Vérifiez les logs de la console pour plus de détails');
        }

        print('🧪 === FIN TEST INJECTION ===');
      } catch (e) {
        buffer.writeln('   ❌ Erreur service: $e');
      }

      // 4. Instructions pour vérification
      buffer.writeln('\n4. VÉRIFICATION MANUELLE:');
      buffer.writeln('   1. Regardez les logs de la console');
      buffer.writeln('   2. Vérifiez en base de données le dernier mouvement créé');
      buffer.writeln('   3. Le champ boutiqueId devrait être: $boutiqueId');
      buffer.writeln('   4. Si c\'est encore null, le problème est côté serveur');
    } catch (e) {
      buffer.writeln('❌ Erreur générale: $e');
    }

    buffer.writeln('\n=== FIN TEST ===');

    setState(() {
      _results = buffer.toString();
      _isLoading = false;
    });
  }
}
