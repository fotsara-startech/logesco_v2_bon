import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

/// Bug Condition Exploration Test - Défauts de Hiérarchie Visuelle
///
/// **Validates: Requirements 1.4, 1.5, 1.6, 1.7, 1.8, 1.9**
///
/// **IMPORTANT**: Ce test DOIT ÉCHOUER sur le code non corrigé - l'échec confirme que le bug existe
/// **Property 1: Bug Condition** - Défauts de Hiérarchie Visuelle
///
/// Ce test vérifie que le code actuel manque les éléments de hiérarchie visuelle suivants :
/// - Bandeau coloré (#1565C0) dans l'en-tête
/// - Système de repli pour afficher les initiales quand le logo est manquant
/// - Badge de statut de paiement (vert/orange)
/// - Cartes séparées pour Émetteur et Client
/// - Zébrage dans le tableau des articles
/// - Mise en valeur du bloc TOTAL (fond coloré, texte blanc, police plus grande)
///
/// **RÉSULTAT ATTENDU**: Le test ÉCHOUE (c'est correct - cela prouve que les défauts visuels existent)
void main() {
  group('Bug Condition Exploration - Visual Hierarchy Defects', () {
    test('Property 1: En-tête should lack colored banner (#1565C0)', () async {
      final baseFile = File('lib/features/printing/widgets/receipt_template_base.dart');

      if (!baseFile.existsSync()) {
        fail('File not found - cannot run test');
      }

      final baseContent = await baseFile.readAsString();

      // Vérifier l'absence du bandeau coloré dans buildHeader()
      // On cherche si le Container d'en-tête utilise _headerBg ou Color(0xFF1565C0)
      final hasBuildHeaderMethod = baseContent.contains('Widget buildHeader(');
      final headerUsesColoredBackground = baseContent.contains('decoration: const BoxDecoration(color: _headerBg)') ||
          baseContent.contains('decoration: BoxDecoration(color: _headerBg)') ||
          (baseContent.contains('Container') && baseContent.contains('_headerBg') && baseContent.contains('buildHeader'));

      // Vérifier si les couleurs sont définies mais non utilisées (warnings)
      final hasHeaderBgDefined = baseContent.contains('static const Color _headerBg');
      final hasHeaderTextDefined = baseContent.contains('static const Color _headerText');

      print('\n════════════════════════════════════════════════════════════════');
      print('ANALYSE En-tête avec Bandeau Coloré:');
      print('════════════════════════════════════════════════════════════════');
      print('Méthode buildHeader() existe: ${hasBuildHeaderMethod ? "OUI" : "NON"}');
      print('Couleur _headerBg définie: ${hasHeaderBgDefined ? "OUI" : "NON"}');
      print('Couleur _headerText définie: ${hasHeaderTextDefined ? "OUI" : "NON"}');
      print('En-tête utilise bandeau coloré: ${headerUsesColoredBackground ? "OUI" : "NON"}');
      print('════════════════════════════════════════════════════════════════\n');

      final counterexamples = <String>[];

      if (hasHeaderBgDefined && !headerUsesColoredBackground) {
        counterexamples.add('✓ Couleur _headerBg définie mais NON UTILISÉE dans l\'en-tête');
      }
      if (!headerUsesColoredBackground) {
        counterexamples.add('✓ En-tête sans bandeau coloré (#1565C0)');
      }

      if (counterexamples.isNotEmpty) {
        print('CONTRE-EXEMPLES (Défauts Visuels):');
        for (final example in counterexamples) {
          print(example);
        }
        print('');
      }

      // Bug Condition 1.4: Absence de bandeau coloré dans l'en-tête
      final bugExists = !headerUsesColoredBackground;

      expect(
        bugExists,
        isFalse,
        reason: 'ATTENDU: Ce test échoue car l\'en-tête n\'a pas de bandeau coloré. '
            'Contre-exemples: ${counterexamples.join(", ")}. '
            'Quand ce test PASSE, cela signifie que le bandeau coloré est implémenté (bug corrigé).',
      );
    });

    test('Property 1: Logo should lack fallback to initials when missing', () async {
      final baseFile = File('lib/features/printing/widgets/receipt_template_base.dart');

      if (!baseFile.existsSync()) {
        fail('File not found - cannot run test');
      }

      final baseContent = await baseFile.readAsString();

      // Vérifier l'absence du système de repli logo/initiales
      // On cherche une logique conditionnelle qui affiche les initiales quand le logo est manquant
      final hasInitialsFallback = (baseContent.contains('hasLogo') || baseContent.contains('logoPath != null')) && baseContent.contains('initiales') || baseContent.contains('substring(0, 1)');

      // Vérifier si hasLogo est défini mais non utilisé (warning)
      final hasLogoVariableDefined = baseContent.contains('final hasLogo =');

      print('\n════════════════════════════════════════════════════════════════');
      print('ANALYSE Système de Repli Logo/Initiales:');
      print('════════════════════════════════════════════════════════════════');
      print('Variable hasLogo définie: ${hasLogoVariableDefined ? "OUI" : "NON"}');
      print('Système de repli initiales implémenté: ${hasInitialsFallback ? "OUI" : "NON"}');
      print('════════════════════════════════════════════════════════════════\n');

      final counterexamples = <String>[];

      if (hasLogoVariableDefined && !hasInitialsFallback) {
        counterexamples.add('✓ Variable hasLogo définie mais AUCUN système de repli implémenté');
      }
      if (!hasInitialsFallback) {
        counterexamples.add('✓ Absence de système de repli pour afficher les initiales quand le logo est manquant');
      }

      if (counterexamples.isNotEmpty) {
        print('CONTRE-EXEMPLES (Défauts Visuels):');
        for (final example in counterexamples) {
          print(example);
        }
        print('');
      }

      // Bug Condition 1.5: Absence de système de repli logo/initiales
      final bugExists = !hasInitialsFallback;

      expect(
        bugExists,
        isFalse,
        reason: 'ATTENDU: Ce test échoue car il n\'y a pas de repli vers les initiales quand le logo est manquant. '
            'Contre-exemples: ${counterexamples.join(", ")}. '
            'Quand ce test PASSE, cela signifie que le système de repli est implémenté (bug corrigé).',
      );
    });

    test('Property 1: Title should lack payment status badge (green/orange)', () async {
      final baseFile = File('lib/features/printing/widgets/receipt_template_base.dart');

      if (!baseFile.existsSync()) {
        fail('File not found - cannot run test');
      }

      final baseContent = await baseFile.readAsString();

      // Vérifier l'absence d'une méthode buildTitleAndStatus() ou similaire
      final hasTitleAndStatusMethod = baseContent.contains('Widget buildTitleAndStatus(') || baseContent.contains('buildTitleAndStatus');

      // Vérifier l'absence de badge de statut dans le code
      final hasPaymentStatusBadge =
          (baseContent.contains('4CAF50') || baseContent.contains('FF9800')) && (baseContent.contains('paid') || baseContent.contains('pending') || baseContent.contains('Payé'));

      print('\n════════════════════════════════════════════════════════════════');
      print('ANALYSE Badge de Statut de Paiement:');
      print('════════════════════════════════════════════════════════════════');
      print('Méthode buildTitleAndStatus() existe: ${hasTitleAndStatusMethod ? "OUI" : "NON"}');
      print('Badge de statut implémenté: ${hasPaymentStatusBadge ? "OUI" : "NON"}');
      print('════════════════════════════════════════════════════════════════\n');

      final counterexamples = <String>[];

      if (!hasTitleAndStatusMethod) {
        counterexamples.add('✓ Méthode buildTitleAndStatus() N\'EXISTE PAS');
      }
      if (!hasPaymentStatusBadge) {
        counterexamples.add('✓ Absence de badge de statut de paiement (vert pour "Payé", orange pour "En attente")');
      }

      if (counterexamples.isNotEmpty) {
        print('CONTRE-EXEMPLES (Défauts Visuels):');
        for (final example in counterexamples) {
          print(example);
        }
        print('');
      }

      // Bug Condition 1.6: Absence de badge de statut de paiement
      final bugExists = !hasPaymentStatusBadge;

      expect(
        bugExists,
        isFalse,
        reason: 'ATTENDU: Ce test échoue car il n\'y a pas de badge de statut de paiement. '
            'Contre-exemples: ${counterexamples.join(", ")}. '
            'Quand ce test PASSE, cela signifie que le badge de statut est implémenté (bug corrigé).',
      );
    });

    test('Property 1: Client and Vendor should not be separated in distinct cards', () async {
      final baseFile = File('lib/features/printing/widgets/receipt_template_base.dart');

      if (!baseFile.existsSync()) {
        fail('File not found - cannot run test');
      }

      final baseContent = await baseFile.readAsString();

      // Vérifier l'absence d'une méthode buildClientVendorCards() ou similaire
      final hasClientVendorCardsMethod = baseContent.contains('Widget buildClientVendorCards(') || baseContent.contains('buildClientVendorCards');

      // Vérifier l'absence de cartes séparées avec titres "Émetteur" et "Client"
      final hasSeparatedCards = baseContent.contains('Émetteur') && baseContent.contains('Client') && baseContent.contains('BoxDecoration') && baseContent.contains('border');

      print('\n════════════════════════════════════════════════════════════════');
      print('ANALYSE Cartes Séparées Émetteur/Client:');
      print('════════════════════════════════════════════════════════════════');
      print('Méthode buildClientVendorCards() existe: ${hasClientVendorCardsMethod ? "OUI" : "NON"}');
      print('Cartes séparées implémentées: ${hasSeparatedCards ? "OUI" : "NON"}');
      print('════════════════════════════════════════════════════════════════\n');

      final counterexamples = <String>[];

      if (!hasClientVendorCardsMethod) {
        counterexamples.add('✓ Méthode buildClientVendorCards() N\'EXISTE PAS');
      }
      if (!hasSeparatedCards) {
        counterexamples.add('✓ Absence de cartes visuellement séparées pour Émetteur et Client');
      }

      if (counterexamples.isNotEmpty) {
        print('CONTRE-EXEMPLES (Défauts Visuels):');
        for (final example in counterexamples) {
          print(example);
        }
        print('');
      }

      // Bug Condition 1.7: Absence de cartes séparées pour Émetteur et Client
      final bugExists = !hasSeparatedCards;

      expect(
        bugExists,
        isFalse,
        reason: 'ATTENDU: Ce test échoue car il n\'y a pas de cartes séparées pour Émetteur et Client. '
            'Contre-exemples: ${counterexamples.join(", ")}. '
            'Quand ce test PASSE, cela signifie que les cartes séparées sont implémentées (bug corrigé).',
      );
    });

    test('Property 1: Items table should lack zebra striping (alternating row colors)', () async {
      final baseFile = File('lib/features/printing/widgets/receipt_template_base.dart');

      if (!baseFile.existsSync()) {
        fail('File not found - cannot run test');
      }

      final baseContent = await baseFile.readAsString();

      // Vérifier l'absence de zébrage dans buildItemsList()
      // On cherche si les TableRow utilisent .asMap().entries.map() pour obtenir l'index
      // et appliquent une decoration avec couleur alternée
      final hasZebraStriping = baseContent.contains('.asMap().entries.map') &&
          baseContent.contains('decoration: BoxDecoration') &&
          (baseContent.contains('_rowEven') || baseContent.contains('_rowOdd')) &&
          baseContent.contains('isEven');

      // Vérifier si les couleurs sont définies mais non utilisées (warnings)
      final hasRowColorsDefined = baseContent.contains('static const Color _rowOdd') && baseContent.contains('static const Color _rowEven');

      print('\n════════════════════════════════════════════════════════════════');
      print('ANALYSE Zébrage du Tableau des Articles:');
      print('════════════════════════════════════════════════════════════════');
      print('Couleurs _rowOdd et _rowEven définies: ${hasRowColorsDefined ? "OUI" : "NON"}');
      print('Zébrage implémenté dans buildItemsList(): ${hasZebraStriping ? "OUI" : "NON"}');
      print('════════════════════════════════════════════════════════════════\n');

      final counterexamples = <String>[];

      if (hasRowColorsDefined && !hasZebraStriping) {
        counterexamples.add('✓ Couleurs _rowOdd et _rowEven définies mais NON UTILISÉES');
      }
      if (!hasZebraStriping) {
        counterexamples.add('✓ Absence de zébrage dans le tableau des articles (lignes alternées blanc / #F5F7FA)');
      }

      if (counterexamples.isNotEmpty) {
        print('CONTRE-EXEMPLES (Défauts Visuels):');
        for (final example in counterexamples) {
          print(example);
        }
        print('');
      }

      // Bug Condition 1.8: Absence de zébrage dans le tableau
      final bugExists = !hasZebraStriping;

      expect(
        bugExists,
        isFalse,
        reason: 'ATTENDU: Ce test échoue car il n\'y a pas de zébrage dans le tableau des articles. '
            'Contre-exemples: ${counterexamples.join(", ")}. '
            'Quand ce test PASSE, cela signifie que le zébrage est implémenté (bug corrigé).',
      );
    });

    test('Property 1: Total block should lack visual emphasis (colored bg, white text, larger font)', () async {
      final baseFile = File('lib/features/printing/widgets/receipt_template_base.dart');

      if (!baseFile.existsSync()) {
        fail('File not found - cannot run test');
      }

      final baseContent = await baseFile.readAsString();

      // Vérifier l'absence de mise en valeur du bloc TOTAL
      // On cherche si le total utilise _totalBg et un style distinct avec fontSize + 3
      final hasTotalEmphasis =
          baseContent.contains('_totalBg') && baseContent.contains('buildTotals') && baseContent.contains('Container') && baseContent.contains('decoration: BoxDecoration(color: _totalBg');

      // Vérifier si la couleur est définie mais non utilisée (warning)
      final hasTotalBgDefined = baseContent.contains('static const Color _totalBg');

      print('\n════════════════════════════════════════════════════════════════');
      print('ANALYSE Mise en Valeur du Bloc TOTAL:');
      print('════════════════════════════════════════════════════════════════');
      print('Couleur _totalBg définie: ${hasTotalBgDefined ? "OUI" : "NON"}');
      print('Bloc TOTAL avec emphase visuelle: ${hasTotalEmphasis ? "OUI" : "NON"}');
      print('════════════════════════════════════════════════════════════════\n');

      final counterexamples = <String>[];

      if (hasTotalBgDefined && !hasTotalEmphasis) {
        counterexamples.add('✓ Couleur _totalBg définie mais NON UTILISÉE dans buildTotals()');
      }
      if (!hasTotalEmphasis) {
        counterexamples.add('✓ Absence de mise en valeur du bloc TOTAL (fond coloré #1565C0, texte blanc, police plus grande)');
      }

      if (counterexamples.isNotEmpty) {
        print('CONTRE-EXEMPLES (Défauts Visuels):');
        for (final example in counterexamples) {
          print(example);
        }
        print('');
      }

      // Bug Condition 1.9: Absence de mise en valeur du bloc TOTAL
      final bugExists = !hasTotalEmphasis;

      expect(
        bugExists,
        isFalse,
        reason: 'ATTENDU: Ce test échoue car le bloc TOTAL n\'est pas mis en valeur. '
            'Contre-exemples: ${counterexamples.join(", ")}. '
            'Quand ce test PASSE, cela signifie que la mise en valeur du TOTAL est implémentée (bug corrigé).',
      );
    });

    test('Property 1: Summary - All visual hierarchy defects should be documented', () async {
      final baseFile = File('lib/features/printing/widgets/receipt_template_base.dart');

      if (!baseFile.existsSync()) {
        fail('File not found - cannot run test');
      }

      final baseContent = await baseFile.readAsString();

      // Récapitulatif de tous les défauts visuels
      final defects = <String, bool>{};

      // 1. Bandeau coloré dans l'en-tête
      final headerUsesColoredBackground = baseContent.contains('decoration: const BoxDecoration(color: _headerBg)') || baseContent.contains('decoration: BoxDecoration(color: _headerBg)');
      defects['Bandeau coloré en-tête (#1565C0)'] = headerUsesColoredBackground;

      // 2. Système de repli logo/initiales
      final hasInitialsFallback = (baseContent.contains('hasLogo') || baseContent.contains('logoPath != null')) && (baseContent.contains('initiales') || baseContent.contains('substring(0, 1)'));
      defects['Système de repli logo/initiales'] = hasInitialsFallback;

      // 3. Badge de statut de paiement
      final hasPaymentStatusBadge =
          (baseContent.contains('4CAF50') || baseContent.contains('FF9800')) && (baseContent.contains('paid') || baseContent.contains('pending') || baseContent.contains('Payé'));
      defects['Badge de statut de paiement'] = hasPaymentStatusBadge;

      // 4. Cartes séparées Émetteur/Client
      final hasSeparatedCards = baseContent.contains('Émetteur') && baseContent.contains('Client') && baseContent.contains('BoxDecoration') && baseContent.contains('border');
      defects['Cartes séparées Émetteur/Client'] = hasSeparatedCards;

      // 5. Zébrage du tableau
      final hasZebraStriping = baseContent.contains('.asMap().entries.map') &&
          baseContent.contains('decoration: BoxDecoration') &&
          (baseContent.contains('_rowEven') || baseContent.contains('_rowOdd')) &&
          baseContent.contains('isEven');
      defects['Zébrage du tableau des articles'] = hasZebraStriping;

      // 6. Mise en valeur du bloc TOTAL
      final hasTotalEmphasis =
          baseContent.contains('_totalBg') && baseContent.contains('buildTotals') && baseContent.contains('Container') && baseContent.contains('decoration: BoxDecoration(color: _totalBg');
      defects['Mise en valeur du bloc TOTAL'] = hasTotalEmphasis;

      print('\n════════════════════════════════════════════════════════════════');
      print('RÉCAPITULATIF DES DÉFAUTS DE HIÉRARCHIE VISUELLE:');
      print('════════════════════════════════════════════════════════════════');
      defects.forEach((feature, implemented) {
        final status = implemented ? '✓ IMPLÉMENTÉ' : '✗ MANQUANT';
        print('$status: $feature');
      });
      print('════════════════════════════════════════════════════════════════\n');

      // Compter le nombre de défauts
      final missingFeatures = defects.entries.where((e) => !e.value).length;
      final totalFeatures = defects.length;

      print('RÉSUMÉ: $missingFeatures/$totalFeatures éléments visuels MANQUANTS\n');

      // Bug Condition: Au moins un élément de hiérarchie visuelle est manquant
      final allFeaturesImplemented = missingFeatures == 0;

      expect(
        allFeaturesImplemented,
        isTrue,
        reason: 'ATTENDU: Ce test échoue car $missingFeatures/$totalFeatures éléments de hiérarchie visuelle sont manquants. '
            'Quand ce test PASSE, tous les éléments visuels sont implémentés (bug corrigé).',
      );
    });
  });
}
