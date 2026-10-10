import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/sync/services/sync_status_service.dart';
import 'package:logesco_v2/features/sync/widgets/sync_drift_card.dart';

Widget _carte(SyncDriftReport? r, {bool checking = false, VoidCallback? onCheck}) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SyncDriftCard(report: r, checking: checking, onCheck: onCheck ?? () {}))));

void main() {
  test('le rapport du serveur est lu : résumé, groupes, exemples, ancienneté', () {
    final r = SyncDriftReport.fromJson({
      'verifieLe': '2026-10-10T10:00:00.000Z',
      'resume': {'inexpliques': 18, 'anciens': 3, 'connus': 2},
      'ecarts': [
        {
          'tableLabel': 'Mouvement de stock',
          'sens': 'a_envoyer',
          'libelle': 'Présent sur ce poste mais jamais arrivé dans le cloud',
          'connue': false,
          'nombre': 4,
          'anciens': 3,
          'depuis': '2026-10-08T10:00:00.000Z',
          'exemples': [
            {'id': 1, 'resume': 'MC4 (Petit) — achat +400'}
          ],
        }
      ],
    });
    expect(r.inexpliques, 18);
    expect(r.anciens, 3);
    expect(r.ecarts.single.nombre, 4);
    expect(r.ecarts.single.connue, isFalse);
    expect(r.ecarts.single.exemples.single.resume, 'MC4 (Petit) — achat +400');
    expect(r.ecarts.single.depuis, isNotNull);
  });

  test('le résumé de /sync/status est lu (absent = pas encore contrôlé)', () {
    final base = {'mode': 'hybrid', 'cloudEnabled': true, 'cloudAvailable': true, 'pendingCount': 0, 'failedCount': 0};
    expect(SyncStatus.fromJson(base).driftInexpliques, isNull);
    final s = SyncStatus.fromJson({
      ...base,
      'drift': {'inexpliques': 5, 'anciens': 2}
    });
    expect([s.driftInexpliques, s.driftAnciens], [5, 2]);
  });

  testWidgets('pas encore vérifié : invite à lancer la vérification', (tester) async {
    var appels = 0;
    await tester.pumpWidget(_carte(null, onCheck: () => appels++));
    expect(find.text('Écart avec le cloud : pas encore vérifié'), findsOneWidget);
    await tester.tap(find.text("Vérifier l'écart avec le cloud"));
    expect(appels, 1);
  });

  testWidgets('concordance : message rassurant, aucune liste', (tester) async {
    await tester.pumpWidget(_carte(const SyncDriftReport(inexpliques: 0, anciens: 0, connus: 0, ecarts: [])));
    expect(find.text('Ce poste et le cloud concordent'), findsOneWidget);
    expect(find.textContaining('élément(s) en écart'), findsNothing);
  });

  testWidgets('écart : nombre, cause en clair, exemples, ancienneté ; les écarts déjà connus ne sont pas listés', (tester) async {
    await tester.pumpWidget(_carte(const SyncDriftReport(
      inexpliques: 4,
      anciens: 2,
      connus: 1,
      ecarts: [
        SyncDriftGroup(
          tableLabel: 'Mouvement de stock',
          sens: 'a_envoyer',
          libelle: 'Présent sur ce poste mais jamais arrivé dans le cloud',
          connue: false,
          nombre: 4,
          anciens: 2,
          exemples: [SyncDriftExample('MC4 (Petit) — achat +400'), SyncDriftExample('MC4 (Grand) — achat +250')],
        ),
        SyncDriftGroup(tableLabel: 'Produit', sens: 'a_envoyer', libelle: 'Envoi en attente', connue: true, nombre: 1, anciens: 0, exemples: [SyncDriftExample('NOUVEAU')]),
      ],
    )));
    expect(find.text('4 élément(s) en écart avec le cloud'), findsOneWidget);
    expect(find.text('Mouvement de stock · Ici, pas dans le cloud (4)'), findsOneWidget);
    expect(find.text('• MC4 (Petit) — achat +400'), findsOneWidget);
    expect(find.text('… et 2 autre(s)'), findsOneWidget);
    expect(find.textContaining("durent depuis plus d'un jour"), findsOneWidget);
    expect(find.textContaining('NOUVEAU'), findsNothing, reason: "ce que le système connaît déjà est dans « ce qui n'est pas synchronisé »");
  });

  SyncDriftGroup groupe({SyncDriftRenvoi? renvoi, String sens = 'a_envoyer', List<SyncDriftId> ids = const []}) => SyncDriftGroup(
        tableLabel: 'Mouvement de stock',
        sens: sens,
        libelle: 'Présent sur ce poste mais jamais arrivé dans le cloud',
        connue: false,
        nombre: 1,
        anciens: 0,
        exemples: const [SyncDriftExample('CONTROLLEUR DE TENSION 230V — achat +100')],
        renvoi: renvoi,
        ids: ids,
      );

  Widget carte(SyncDriftReport r, {VoidCallback? onResend, void Function(SyncDriftGroup)? onForce, void Function(SyncDriftGroup)? onIgnore, VoidCallback? onRestore}) =>
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SyncDriftCard(report: r, checking: false, onCheck: () {}, onResend: onResend, onForce: onForce, onIgnore: onIgnore, onRestore: onRestore))));

  testWidgets("renvoi : le verdict est écrit dans la carte ; le bouton « Renvoyer » n'apparaît que s'il y a quelque chose d'envoyable", (tester) async {
    var envois = 0;
    // refusé (cas du contrôleur de tension) : la raison est visible sans cliquer, pas de bouton Renvoyer
    await tester.pumpWidget(carte(
      SyncDriftReport(inexpliques: 1, anciens: 0, connus: 0, ecarts: [
        groupe(renvoi: const SyncDriftRenvoi(envoyables: 0, refuses: 1, raisons: ["Le cloud a déjà 3 mouvement(s) pour ce produit"], forcable: true))
      ]),
      onResend: () => envois++,
    ));
    expect(find.textContaining('Le cloud a déjà 3 mouvement(s)'), findsOneWidget);
    expect(find.textContaining('ne sera/seront pas renvoyé'), findsOneWidget);
    expect(find.text('Renvoyer vers le cloud'), findsNothing, reason: 'rien à envoyer sans risque');

    // envoyable : le bouton apparaît
    await tester.pumpWidget(carte(
      SyncDriftReport(inexpliques: 1, anciens: 0, connus: 0, ecarts: [groupe(renvoi: const SyncDriftRenvoi(envoyables: 1, refuses: 0, raisons: [], forcable: false))]),
      onResend: () => envois++,
    ));
    expect(find.textContaining('sans risque'), findsOneWidget);
    await tester.tap(find.text('Renvoyer vers le cloud'));
    expect(envois, 1);

    // écart « à recevoir » : jamais de bouton de renvoi
    await tester.pumpWidget(carte(SyncDriftReport(inexpliques: 1, anciens: 0, connus: 0, ecarts: [groupe(sens: 'a_recevoir')]), onResend: () => envois++));
    expect(find.text('Renvoyer vers le cloud'), findsNothing);
  });

  testWidgets('« Envoyer quand même » seulement si le refus est levable ; « Ignorer cet écart » pour les écarts de présence', (tester) async {
    final forces = <SyncDriftGroup>[];
    final ignores = <SyncDriftGroup>[];
    const ids = [SyncDriftId(table: 'mouvements_stock', id: 16, sens: 'a_envoyer')];

    await tester.pumpWidget(carte(
      SyncDriftReport(inexpliques: 1, anciens: 0, connus: 0, ecarts: [
        groupe(ids: ids, renvoi: const SyncDriftRenvoi(envoyables: 0, refuses: 1, raisons: ['historique déjà présent'], forcable: true))
      ]),
      onForce: forces.add,
      onIgnore: ignores.add,
    ));
    await tester.tap(find.text('Envoyer quand même'));
    await tester.tap(find.text('Ignorer cet écart'));
    expect(forces.single.ids.single.id, 16);
    expect(ignores.single.ids.single.table, 'mouvements_stock');

    // refus NON levable (produit supprimé dans le cloud) : pas de « Envoyer quand même », mais on peut l'ignorer
    await tester.pumpWidget(carte(
      SyncDriftReport(inexpliques: 1, anciens: 0, connus: 0, ecarts: [
        groupe(renvoi: const SyncDriftRenvoi(envoyables: 0, refuses: 1, raisons: ['produit supprimé dans le cloud'], forcable: false))
      ]),
      onForce: forces.add,
      onIgnore: ignores.add,
    ));
    expect(find.text('Envoyer quand même'), findsNothing);
    expect(find.text('Ignorer cet écart'), findsOneWidget);

    // une valeur différente (stock, solde) ne s'ignore pas
    await tester.pumpWidget(carte(SyncDriftReport(inexpliques: 1, anciens: 0, connus: 0, ecarts: [groupe(sens: 'valeur')]), onIgnore: ignores.add));
    expect(find.text('Ignorer cet écart'), findsNothing);
  });

  testWidgets('écarts ignorés : comptés, avec un bouton pour les réafficher', (tester) async {
    var restaures = 0;
    await tester.pumpWidget(carte(const SyncDriftReport(inexpliques: 0, anciens: 0, connus: 0, ignores: 2, ecarts: []), onRestore: () => restaures++));
    expect(find.text('2 écart(s) ignoré(s)'), findsOneWidget);
    await tester.tap(find.text('Réafficher'));
    expect(restaures, 1);
  });

  test("le verdict du renvoi, les références et le nombre d'ignorés sont lus", () {
    final r = SyncDriftReport.fromJson({
      'resume': {'inexpliques': 1, 'anciens': 0, 'connus': 0, 'ignores': 3},
      'ecarts': [
        {
          'tableLabel': 'Mouvement de stock',
          'sens': 'a_envoyer',
          'libelle': 'x',
          'connue': false,
          'nombre': 1,
          'anciens': 0,
          'exemples': [],
          'ids': [
            {'table': 'mouvements_stock', 'id': 16, 'sens': 'a_envoyer'}
          ],
          'renvoi': {'envoyables': 0, 'refuses': 1, 'raisons': ['historique déjà présent'], 'forcable': true},
        }
      ],
    });
    expect(r.ignores, 3);
    final g = r.ecarts.single;
    expect(g.renvoi!.forcable, isTrue);
    expect(g.ids.single.toJson(), {'table': 'mouvements_stock', 'id': 16, 'sens': 'a_envoyer'});
    expect(g.ignorable, isTrue);
  });

  test("le résultat du renvoi est lu : compte, lignes envoyables, refus et leur raison", () {
    final r = SyncResendResult.fromJson({
      'dryRun': true,
      'aEnvoyer': 14,
      'envoyes': 0,
      'details': {
        'envoyables': [
          {'tableLabel': 'Stock boutique', 'resume': 'MC4 (Petit) — quantité 400'}
        ],
        'refuses': [
          {'tableLabel': 'Mouvement de stock', 'resume': 'CONTROLLEUR — achat +100', 'raison': 'Le cloud a déjà 3 mouvement(s)'}
        ],
      },
    });
    expect([r.dryRun, r.aEnvoyer, r.envoyes], [true, 14, 0]);
    expect(r.envoyables.single.resume, 'MC4 (Petit) — quantité 400');
    expect(r.refuses.single.raison, 'Le cloud a déjà 3 mouvement(s)');
  });

  testWidgets('vérification en cours : bouton désactivé', (tester) async {
    await tester.pumpWidget(_carte(null, checking: true));
    expect(find.text('Comparaison en cours…'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
  });
}
