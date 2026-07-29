import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

/// Bug Condition Exploration Test - Compilation et Structure Malformée
///
/// **Validates: Requirements 1.1, 1.2, 1.3**
///
/// **IMPORTANT**: Ce test DOIT ÉCHOUER sur le code non corrigé - l'échec confirme que le bug existe
/// **Property 1: Bug Condition** - Erreurs de Compilation et Structure Malformée
///
/// Ce test vérifie que le code actuel dans `receipt_template_base.dart` échoue à la compilation
/// avec les erreurs suivantes :
/// - Ligne 48 (environ) : Erreur "Expected to find ','" causée par `chilany.address.isNotEmpty)`
/// - Variables `subtitleStyle` et `textAlign` non définies
/// - Méthode `buildCompanyHeader()` non définie dans la classe de base mais appelée par A4/A5
///
/// **RÉSULTAT ATTENDU**: Le test ÉCHOUE (c'est correct - cela prouve que le bug existe)
void main() {
  group('Bug Condition Exploration - Compilation Errors', () {
    test('Property 1: receipt_template_base.dart should have compilation errors demonstrating the bug', () async {
      // Run flutter analyze on the specific file to capture compilation errors
      final result = await Process.run(
        'flutter',
        ['analyze', 'lib/features/printing/widgets/receipt_template_base.dart'],
        workingDirectory: Directory.current.path,
      );

      final output = result.stdout.toString() + result.stderr.toString();

      print('\n════════════════════════════════════════════════════════════════');
      print('ANALYSE OUTPUT (Contre-exemples démontrant l\'existence du bug):');
      print('════════════════════════════════════════════════════════════════');
      print(output);
      print('════════════════════════════════════════════════════════════════\n');

      // Bug Condition 1.1: Erreur de syntaxe "Expected to find ','" à la ligne 48
      final hasExpectedCommaError = output.contains("Expected to find ','") || output.contains('Expected to find","');

      // Bug Condition 1.1: Code orphelin avec typo "chilany" au lieu de "company"
      final hasChildanyTypo = output.contains("Undefined name 'chilany'") || output.contains('chilany');

      // Bug Condition 1.2: Variables subtitleStyle et textAlign non définies
      final hasSubtitleStyleError = output.contains("Undefined name 'subtitleStyle'") || output.contains('subtitleStyle');
      final hasTextAlignError = output.contains("Undefined name 'textAlign'") || output.contains('textAlign');

      // Documenter les contre-exemples trouvés
      final counterexamples = <String>[];

      if (hasExpectedCommaError) {
        counterexamples.add('✓ Erreur "Expected to find \',\'" détectée (ligne ~48)');
      }
      if (hasChildanyTypo) {
        counterexamples.add('✓ Typo "chilany" détectée (devrait être "company")');
      }
      if (hasSubtitleStyleError) {
        counterexamples.add('✓ Variable "subtitleStyle" non définie');
      }
      if (hasTextAlignError) {
        counterexamples.add('✓ Variable "textAlign" non définie');
      }

      print('\n════════════════════════════════════════════════════════════════');
      print('CONTRE-EXEMPLES TROUVÉS:');
      print('════════════════════════════════════════════════════════════════');
      for (final example in counterexamples) {
        print(example);
      }
      print('════════════════════════════════════════════════════════════════\n');

      // IMPORTANT: Ce test vérifie que les erreurs EXISTENT (Bug Condition)
      // Quand les erreurs sont présentes, le test échoue (c'est le comportement attendu)
      // Après la correction, ce même test passera, validant que le bug est résolu

      // On s'attend à trouver AU MOINS une des erreurs suivantes:
      // 1. Erreur "Expected to find ','"
      // 2. Typo "chilany"
      // 3. Variable "subtitleStyle" non définie
      // 4. Variable "textAlign" non définie

      final bugsFound = hasExpectedCommaError || hasChildanyTypo || hasSubtitleStyleError || hasTextAlignError;

      expect(
        bugsFound,
        isFalse,
        reason: 'ATTENDU: Ce test échoue sur le code non corrigé car des erreurs de compilation existent. '
            'Contre-exemples trouvés: ${counterexamples.join(", ")}. '
            'Quand ce test PASSE, cela signifie que le code compile sans erreur (bug corrigé).',
      );
    });

    test('Property 1: buildCompanyHeader() method should be missing from base class', () async {
      // Check that A4 and A5 templates call buildCompanyHeader() but it's not defined in the base class
      final baseFile = File('lib/features/printing/widgets/receipt_template_base.dart');
      final a4File = File('lib/features/printing/widgets/receipt_template_a4.dart');
      final a5File = File('lib/features/printing/widgets/receipt_template_a5.dart');

      if (!baseFile.existsSync() || !a4File.existsSync() || !a5File.existsSync()) {
        fail('Files not found - cannot run test');
      }

      final baseContent = await baseFile.readAsString();
      final a4Content = await a4File.readAsString();
      final a5Content = await a5File.readAsString();

      // Vérifier que buildCompanyHeader() n'existe PAS dans la classe de base
      final baseHasMethod = baseContent.contains('Widget buildCompanyHeader(');

      // Vérifier que buildCompanyHeader() EST APPELÉE dans A4 et A5
      final a4CallsMethod = a4Content.contains('buildCompanyHeader(');
      final a5CallsMethod = a5Content.contains('buildCompanyHeader(');

      print('\n════════════════════════════════════════════════════════════════');
      print('ANALYSE buildCompanyHeader():');
      print('════════════════════════════════════════════════════════════════');
      print('Méthode définie dans base class: ${baseHasMethod ? "OUI" : "NON"}');
      print('Méthode appelée dans A4: ${a4CallsMethod ? "OUI" : "NON"}');
      print('Méthode appelée dans A5: ${a5CallsMethod ? "OUI" : "NON"}');
      print('════════════════════════════════════════════════════════════════\n');

      final counterexamples = <String>[];

      if (!baseHasMethod && a4CallsMethod) {
        counterexamples.add('✓ A4 appelle buildCompanyHeader() mais elle n\'existe pas dans la classe de base');
      }
      if (!baseHasMethod && a5CallsMethod) {
        counterexamples.add('✓ A5 appelle buildCompanyHeader() mais elle n\'existe pas dans la classe de base');
      }

      if (counterexamples.isNotEmpty) {
        print('CONTRE-EXEMPLES:');
        for (final example in counterexamples) {
          print(example);
        }
        print('');
      }

      // Bug Condition 1.3: La méthode buildCompanyHeader() n'existe pas dans la base
      // mais elle est appelée par les classes dérivées
      final bugExists = !baseHasMethod && (a4CallsMethod || a5CallsMethod);

      expect(
        bugExists,
        isFalse,
        reason: 'ATTENDU: Ce test échoue car buildCompanyHeader() est appelée mais non définie. '
            'Contre-exemples: ${counterexamples.join(", ")}. '
            'Quand ce test PASSE, cela signifie que la méthode est définie (bug corrigé).',
      );
    });
  });
}
