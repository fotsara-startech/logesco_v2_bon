import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/products/widgets/product_type_selector.dart';

Widget _app({bool? estService, bool enEdition = false, required List<bool> choix}) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ProductTypeSelector(estService: estService, enEdition: enEdition, onChoisi: choix.add))));

void main() {
  group('création', () {
    testWidgets("aucun type présélectionné : on demande de choisir d'abord", (tester) async {
      await tester.pumpWidget(_app(choix: []));
      expect(find.text('1. Quel type de produit ?'), findsOneWidget);
      expect(find.textContaining("Choisissez d'abord"), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing, reason: 'rien de sélectionné');
    });

    testWidgets('choisir un type est immédiat, sans boîte de dialogue', (tester) async {
      final choix = <bool>[];
      await tester.pumpWidget(_app(choix: choix));
      await tester.tap(find.byKey(const ValueKey('type-service')));
      await tester.pump();
      expect(choix, [true]);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('type déjà choisi : on peut encore en changer librement (rien à perdre à la création)', (tester) async {
      final choix = <bool>[];
      await tester.pumpWidget(_app(estService: true, choix: choix));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('type-produit')));
      await tester.pump();
      expect(choix, [false]);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('modification : changer le type demande confirmation', () {
    testWidgets('produit → service : la boîte explique les répercussions ; annuler ne change rien', (tester) async {
      final choix = <bool>[];
      await tester.pumpWidget(_app(estService: false, enEdition: true, choix: choix));
      await tester.tap(find.byKey(const ValueKey('type-service')));
      await tester.pumpAndSettle();
      expect(find.text('Passer ce produit en SERVICE ?'), findsOneWidget);
      expect(find.textContaining('ne diminuent plus aucune quantité'), findsOneWidget);
      expect(find.textContaining('seront vidés'), findsOneWidget);
      expect(find.textContaining('Un article que vous stockez ne doit jamais être un service'), findsOneWidget);
      expect(find.textContaining('cliquerez sur « Modifier »'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(choix, isEmpty, reason: 'rien ne change tant que la personne ne confirme pas');
    });

    testWidgets('produit → service confirmé : le changement est appliqué', (tester) async {
      final choix = <bool>[];
      await tester.pumpWidget(_app(estService: false, enEdition: true, choix: choix));
      await tester.tap(find.byKey(const ValueKey('type-service')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Passer en service'));
      await tester.pumpAndSettle();
      expect(choix, [true]);
    });

    testWidgets('service → produit : la boîte explique le suivi du stock et le stock de départ', (tester) async {
      final choix = <bool>[];
      await tester.pumpWidget(_app(estService: true, enEdition: true, choix: choix));
      await tester.tap(find.byKey(const ValueKey('type-produit')));
      await tester.pumpAndSettle();
      expect(find.text('Passer ce service en PRODUIT (stock suivi) ?'), findsOneWidget);
      expect(find.textContaining('chaque vente diminuera sa quantité'), findsOneWidget);
      expect(find.textContaining('stock de départ est probablement à 0'), findsOneWidget);
      expect(find.textContaining('Un article que vous stockez'), findsNothing, reason: "l'avertissement ne concerne que le passage en service");

      await tester.tap(find.text('Passer en produit'));
      await tester.pumpAndSettle();
      expect(choix, [false]);
    });

    testWidgets('toucher le type déjà sélectionné ne fait rien', (tester) async {
      final choix = <bool>[];
      await tester.pumpWidget(_app(estService: false, enEdition: true, choix: choix));
      await tester.tap(find.byKey(const ValueKey('type-produit')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(choix, isEmpty);
    });
  });

  testWidgets('téléphone : les deux choix passent l’un sous l’autre, sans débordement', (tester) async {
    tester.view.physicalSize = const Size(380, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_app(choix: []));
    expect(tester.takeException(), isNull);
    final produit = tester.getTopLeft(find.byKey(const ValueKey('type-produit')));
    final service = tester.getTopLeft(find.byKey(const ValueKey('type-service')));
    expect(service.dy, greaterThan(produit.dy), reason: 'empilés');
  });
}
