import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/sync/controllers/sync_controller.dart';
import 'package:logesco_v2/features/sync/services/sync_status_service.dart';
import 'package:logesco_v2/features/sync/views/sync_status_page.dart';

class _FakeSync extends GetxController implements SyncController {
  @override
  final Rx<SyncStatus?> status = Rx<SyncStatus?>(null);
  @override
  final RxBool isLoading = false.obs;
  @override
  final RxBool isSyncing = false.obs;
  @override
  final RxList<SyncDetailItem> details = <SyncDetailItem>[].obs;

  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SyncStatus _status({int pending = 2, DateTime? oldest}) => SyncStatus.fromJson({
      'mode': 'hybrid',
      'cloudEnabled': true,
      'cloudAvailable': true,
      'pendingCount': pending,
      'pendingByTable': {'stock_boutiques': pending},
      'failedCount': pending,
      'oldestPendingAt': (oldest ?? DateTime.now().subtract(const Duration(days: 7))).toUtc().toIso8601String(),
    });

/// Les trois éléments réels du client (base du 10/10/2026)
List<SyncDetailItem> _itemsDuClient() {
  const erreur = SyncErrorInfo(
    code: 'doublon',
    titre: "Doublon : cet élément existe déjà de l'autre côté",
    explication: 'Une fiche existe déjà pour la même boutique et le même produit avec un autre identifiant.',
    action: 'Corrigé automatiquement : les deux fiches sont fusionnées à la prochaine synchronisation, sans perte.',
    technique: 'duplicate key value violates unique constraint "stock_boutiques_boutique_id_produit_id_key"',
  );
  const resume = 'LAMPADAIRE SOLAIRE RSK 120 — boutique SMART ENERGY SARL — quantité 52';
  return [
    SyncDetailItem(source: 'envoi', table: 'stock_boutiques', tableLabel: 'Stock boutique', operationLabel: 'Modification', summary: resume, status: 'failed', error: erreur, createdAt: DateTime(2026, 10, 3, 8, 55)),
    SyncDetailItem(source: 'envoi', table: 'stock_boutiques', tableLabel: 'Stock boutique', operationLabel: 'Création', summary: resume, status: 'failed', error: erreur, createdAt: DateTime(2026, 10, 3, 8, 55)),
    SyncDetailItem(source: 'reception', table: 'stock_boutiques', tableLabel: 'Stock boutique', operationLabel: 'Reçu du cloud, non appliqué', summary: resume, status: 'failed', attempts: 19, error: erreur),
  ];
}

Future<_FakeSync> _open(WidgetTester tester, {List<SyncDetailItem>? items, Size size = const Size(1000, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  Get.testMode = true;
  final fake = _FakeSync();
  fake.status.value = _status();
  if (items != null) fake.details.assignAll(items);
  Get.put<SyncController>(fake);
  await tester.pumpWidget(const GetMaterialApp(home: SyncStatusPage()));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  tearDown(() => Get.reset());

  testWidgets('affiche chaque élément en clair : produit, boutique, quantité, cause et action', (tester) async {
    await _open(tester, items: _itemsDuClient());
    expect(find.text("Détail de ce qui n'est pas synchronisé (3)"), findsOneWidget);
    // le nom clair de l'élément, pas seulement le module
    expect(find.text('LAMPADAIRE SOLAIRE RSK 120 — boutique SMART ENERGY SARL — quantité 52'), findsNWidgets(3));
    expect(find.text('Stock boutique · Modification · 03/10 08:55'), findsOneWidget);
    expect(find.text('Stock boutique · Reçu du cloud, non appliqué'), findsOneWidget);
    // les éléments refusés sont dépliés : cause, action, message technique
    expect(find.text("Doublon : cet élément existe déjà de l'autre côté"), findsNWidgets(3));
    expect(find.textContaining('Corrigé automatiquement'), findsNWidgets(3));
    expect(find.textContaining('stock_boutiques_boutique_id_produit_id_key'), findsNWidgets(3));
    expect(find.text('Application tentée 19 fois'), findsOneWidget);
    expect(find.text('3 élément(s) refusé(s) par le cloud. Touchez un élément pour voir pourquoi et que faire.'), findsOneWidget);
  });

  testWidgets('sans détail (serveur ancien) : retombe sur l\'affichage par module', (tester) async {
    await _open(tester, items: null);
    expect(find.textContaining('Détail de ce qui n\'est pas synchronisé'), findsNothing);
    expect(find.text('Stock boutiques'), findsOneWidget); // ancien affichage par module
  });

  testWidgets('un élément simplement en attente (réseau) n\'est pas présenté comme une erreur', (tester) async {
    await _open(tester, items: [
      const SyncDetailItem(
        source: 'envoi',
        table: 'ventes',
        tableLabel: 'Vente',
        operationLabel: 'Création',
        summary: 'VTE-20261010-1 — 50000 FCFA — client FOTSARA',
        status: 'pending',
        error: SyncErrorInfo(code: 'attente', titre: "En attente d'envoi", explication: 'Pas encore envoyé.', action: 'Aucune action.'),
      ),
    ]);
    expect(find.text('VTE-20261010-1 — 50000 FCFA — client FOTSARA'), findsOneWidget);
    expect(find.text('En attente'), findsWidgets);
    expect(find.textContaining('refusé(s) par le cloud'), findsNothing);
  });

  testWidgets('aucun débordement : grand écran et mobile', (tester) async {
    await _open(tester, items: _itemsDuClient(), size: const Size(1000, 900));
    expect(tester.takeException(), isNull);
    Get.reset();
    await _open(tester, items: _itemsDuClient(), size: const Size(400, 800));
    expect(tester.takeException(), isNull);
  });

  test('le rapport copié contient tout ce dont le support a besoin', () {
    final ligne = _itemsDuClient().first.toReportLine();
    expect(ligne, contains('LAMPADAIRE SOLAIRE RSK 120'));
    expect(ligne, contains('Doublon'));
    expect(ligne, contains('Action : Corrigé automatiquement'));
    expect(ligne, contains('stock_boutiques_boutique_id_produit_id_key'));
    expect(ligne, contains('[03/10 08:55]'));
  });
}
