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

  testWidgets('vérification en cours : bouton désactivé', (tester) async {
    await tester.pumpWidget(_carte(null, checking: true));
    expect(find.text('Comparaison en cours…'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
  });
}
