import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/decisions/services/decisions_service.dart';
import 'package:logesco_v2/features/decisions/views/decision_center_page.dart';
import 'package:logesco_v2/features/decisions/widgets/decisions_alert.dart';

class _Appel {
  final String caseKey;
  final String optionId;
  final int stockVu;
  final int? cible;
  _Appel(this.caseKey, this.optionId, this.stockVu, this.cible);
}

class _FakeService implements DecisionsService {
  List<DecisionCase>? cases;
  List<SyncConflict> conflits;
  final List<_Appel> appels = [];
  final List<List<String?>> appelsConflit = []; // [clé, option, valeur]
  String? erreur;

  _FakeService(this.cases, {this.conflits = const []});

  @override
  Future<List<DecisionCase>?> fetch() async => cases == null ? null : [...cases!];

  @override
  Future<DecisionsData?> fetchAll() async => cases == null ? null : DecisionsData(cases: [...cases!], conflits: [...conflits], cloud: 'ok');

  @override
  Future<void> applyConflict({required String caseKey, required String optionId, String? valeur}) async {
    if (erreur != null) throw Exception(erreur);
    appelsConflit.add([caseKey, optionId, valeur]);
    conflits = conflits.where((c) => c.key != caseKey).toList();
  }

  @override
  Future<void> apply({required String caseKey, required String optionId, required int stockVu, int? cible}) async {
    if (erreur != null) throw Exception(erreur);
    appels.add(_Appel(caseKey, optionId, stockVu, cible));
    cases = cases!.where((c) => c.key != caseKey).toList();
  }
}

DecisionCase _lustre() => const DecisionCase(
      key: 'stock:104:1',
      produitId: 104,
      produitNom: 'LUSTRE MODÈLE D6328 P',
      produitReference: 'PRD20260097',
      produitEstService: true,
      boutiqueNom: 'SMART ENERGY SARL',
      stockAffiche: 98,
      priorite: 1,
      raisons: [DecisionReason(code: 'vente_sans_mouvement', titre: 'Produit marqué « service » : 8 unité(s) vendue(s) sans sortie de stock', detail: "Un service n'a pas de stock.")],
      ventes: [DecisionSale(numeroVente: 'VTE-1', quantite: 3), DecisionSale(numeroVente: 'VTE-2', quantite: 5)],
      doublons: [],
      options: [
        DecisionOption(id: 'garder', label: 'Produit physique : garder le stock affiché (98)', description: 'Sans correction.', cible: 98, delta: 0, consequence: 'Stock 98 → 98 (+0)', marquePhysique: true),
        DecisionOption(id: 'apres_ventes', label: 'Produit physique : déduire les 8 unité(s) vendue(s) (90)', description: 'À confirmer par un comptage.', cible: 90, delta: -8, consequence: 'Stock 98 → 90 (-8)', recommandee: true, marquePhysique: true),
        DecisionOption(id: 'service_zero', label: "C'est un vrai service : remettre son stock à 0", description: 'Reste un service.', cible: 0, delta: -98, consequence: 'Stock 98 → 0 (-98)'),
      ],
    );

DecisionCase _doublon() => const DecisionCase(
      key: 'stock:3:1',
      produitId: 3,
      produitNom: 'LAMPADAIRE SOLAIRE RSK 120',
      produitReference: 'R3',
      produitEstService: false,
      stockAffiche: 104,
      dernierMouvementStock: 52,
      priorite: 2,
      raisons: [DecisionReason(code: 'reception_en_double', titre: '1 réception(s) peut-être saisie(s) deux fois (52 unité(s))', detail: 'Même livraison sur deux postes ?')],
      ventes: [],
      doublons: [DecisionDuplicate(quantite: 52)],
      options: [
        DecisionOption(id: 'garder', label: 'Garder le stock affiché (104)', description: 'Aucune correction.', cible: 104, delta: 0, consequence: 'Stock 104 → 104 (+0)'),
        DecisionOption(id: 'sans_doublon', label: 'Annuler la réception en double (52)', description: 'Livraison saisie deux fois.', cible: 52, delta: -52, consequence: 'Stock 104 → 52 (-52)'),
      ],
    );

SyncConflict _conflitProduit() => const SyncConflict(
      key: 'sync:produits:150000005',
      table: 'produits',
      libelle: 'Produit',
      titre: 'Deux produits avec la même référence',
      explication: 'Un produit portant cette référence existe déjà dans le cloud.',
      cleMot: 'référence',
      cleValeur: 'LUS-1',
      local: SyncConflictSide(id: 150000005, resume: ['Nom : LUSTRE LOCAL']),
      cloud: SyncConflictSide(id: 7, resume: ['Nom : LUSTRE CLOUD']),
      options: [
        SyncConflictOption(id: 'fusionner', label: "C'est la même fiche : garder celle du cloud", description: 'Fusion.', consequence: 'Tout est rattaché à la fiche du cloud n° 7.'),
        SyncConflictOption(id: 'renommer', label: 'Ce sont deux fiches différentes : renommer celle de ce poste', description: 'Renommage.', consequence: 'Les deux fiches coexistent.', valeurSuggeree: 'LUS-1-2'),
      ],
    );

SyncConflict _conflitCompte() => const SyncConflict(
      key: 'sync:comptes_clients:150000001',
      table: 'comptes_clients',
      libelle: 'Compte client',
      titre: 'Compte client de MBARGA Paul en double',
      explication: '',
      cleMot: 'client',
      cleValeur: '4',
      local: SyncConflictSide(id: 150000001, resume: ['Solde : -5 000 FCFA']),
      cloud: SyncConflictSide(id: 3, resume: ['Solde : -20 000 FCFA']),
      options: [
        SyncConflictOption(id: 'additionner', label: 'Additionner les deux soldes', description: 'Cumul.', consequence: 'Solde final : -25 000 FCFA', recommandee: true),
        SyncConflictOption(id: 'garder_cloud', label: 'Garder le solde du cloud', description: 'Cloud.', consequence: 'Solde final : -20 000 FCFA'),
      ],
    );

Future<void> _ouvrir(WidgetTester tester, _FakeService svc, {bool canDecide = true, Size size = const Size(900, 1400)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(GetMaterialApp(home: DecisionCenterPage(service: svc, canDecide: canDecide)));
  await tester.pumpAndSettle();
}

/// Laisse disparaître les messages affichés (SnackBar) : ils recouvrent les boutons et gardent des minuteries.
Future<void> _viderMessages(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  tearDown(() => Get.reset());

  group('bannière', () {
    testWidgets('visible avec le nombre de décisions et les unités vendues sans sortie', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: DecisionsAlert(service: _FakeService([_lustre(), _doublon()])))));
      await tester.pumpAndSettle();
      expect(find.text('2 décision(s) à prendre sur le stock'), findsOneWidget);
      expect(find.text("8 unité(s) vendues n'ont jamais diminué le stock"), findsOneWidget);
    });

    testWidgets('invisible sans cas, ou si le serveur ne fournit pas la liste', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: DecisionsAlert(service: _FakeService([])))));
      await tester.pumpAndSettle();
      expect(find.textContaining('décision(s) à prendre'), findsNothing);
    });

    testWidgets('serveur ancien : invisible', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: DecisionsAlert(service: _FakeService(null)))));
      await tester.pumpAndSettle();
      expect(find.textContaining('décision(s) à prendre'), findsNothing);
    });
  });

  group('écran', () {
    testWidgets('affiche les faits (ventes concernées), les options chiffrées et marque l\'option conseillée', (tester) async {
      await _ouvrir(tester, _FakeService([_lustre(), _doublon()]));
      expect(find.text('2 cas où l\'application ne peut pas trancher seule'), findsOneWidget);
      expect(find.text('LUSTRE MODÈLE D6328 P'), findsOneWidget);
      expect(find.text('SMART ENERGY SARL · Stock affiché : 98 · marqué « service »'), findsOneWidget);
      expect(find.textContaining('VTE-1'), findsOneWidget);
      expect(find.text('Stock 98 → 90 (-8)'), findsOneWidget);
      expect(find.text('conseillé'), findsOneWidget);
      expect(find.textContaining('le produit sera marqué « produit physique »'), findsWidgets);
      expect(find.text('Saisir la quantité comptée'), findsWidgets);
    });

    testWidgets('l\'option conseillée est présélectionnée : un clic + confirmation applique la décision', (tester) async {
      final svc = _FakeService([_lustre()]);
      await _ouvrir(tester, svc);
      await tester.tap(find.text('Appliquer ma décision'));
      await tester.pumpAndSettle();
      // récapitulatif avant d'appliquer
      expect(find.text('Confirmer cette décision ?'), findsOneWidget);
      expect(find.text('Stock 98 → 90 (-8)'), findsWidgets);
      expect(find.text('Le produit sera marqué « produit physique » (géré en stock).'), findsOneWidget);

      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();
      expect(svc.appels.length, 1);
      expect(svc.appels.first.caseKey, 'stock:104:1');
      expect(svc.appels.first.optionId, 'apres_ventes');
      expect(svc.appels.first.stockVu, 98, reason: 'le serveur compare au stock vu pour détecter un changement entre-temps');
      expect(find.text('Aucune décision à prendre'), findsOneWidget, reason: 'le cas traité disparaît');
      await _viderMessages(tester);
    });

    testWidgets("quantité comptée : sans quantité saisie, rien n'est envoyé", (tester) async {
      final svc = _FakeService([_doublon()]);
      await _ouvrir(tester, svc);
      await tester.tap(find.text('LAMPADAIRE SOLAIRE RSK 120')); // cas non prioritaire : replié par défaut
      await tester.pumpAndSettle();
      // aucune option conseillée : rien n'est sélectionné, le bouton est désactivé
      expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Appliquer ma décision')).onPressed, isNull);

      await tester.tap(find.text('Saisir la quantité comptée'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer ma décision'));
      await tester.pump();
      expect(svc.appels, isEmpty, reason: 'quantité vide : refusée');
      expect(find.text('Confirmer cette décision ?'), findsNothing);
      await _viderMessages(tester);
    });

    testWidgets('quantité comptée : une quantité valide est confirmée puis envoyée', (tester) async {
      final svc = _FakeService([_doublon()]);
      await _ouvrir(tester, svc);
      await tester.tap(find.text('LAMPADAIRE SOLAIRE RSK 120'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saisir la quantité comptée'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '60');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Appliquer ma décision'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer ma décision'));
      await tester.pumpAndSettle();
      expect(find.text('Stock 104 → 60 (-44)'), findsOneWidget);
      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();
      expect(svc.appels.single.optionId, 'manuel');
      expect(svc.appels.single.cible, 60);
      await _viderMessages(tester);
    });

    testWidgets('laisser tel quel : confirmation puis option « ignorer »', (tester) async {
      final svc = _FakeService([_doublon()]);
      await _ouvrir(tester, svc);
      await tester.tap(find.text('LAMPADAIRE SOLAIRE RSK 120')); // cas non prioritaire : replié par défaut
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laisser tel quel'));
      await tester.pumpAndSettle();
      expect(find.text('Laisser tel quel ?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Laisser tel quel'));
      await tester.pumpAndSettle();
      expect(svc.appels.single.optionId, 'ignorer');
      await _viderMessages(tester);
    });

    testWidgets('annuler la confirmation ne modifie rien', (tester) async {
      final svc = _FakeService([_lustre()]);
      await _ouvrir(tester, svc);
      await tester.tap(find.text('Appliquer ma décision'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(svc.appels, isEmpty);
      expect(find.text('LUSTRE MODÈLE D6328 P'), findsOneWidget);
      await _viderMessages(tester);
    });

    testWidgets('non-administrateur : consultation seulement', (tester) async {
      await _ouvrir(tester, _FakeService([_lustre()]), canDecide: false);
      expect(find.text('Seul un administrateur peut appliquer une décision.'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Appliquer ma décision')).onPressed, isNull);
    });

    testWidgets('refus du serveur (stock changé) : message affiché, liste rechargée, cas conservé', (tester) async {
      final svc = _FakeService([_lustre()])..erreur = "Le stock a changé depuis l'affichage (98 → 95). Actualisez la liste avant de décider.";
      await _ouvrir(tester, svc);
      await tester.tap(find.text('Appliquer ma décision'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();
      expect(svc.appels, isEmpty);
      expect(find.text('LUSTRE MODÈLE D6328 P'), findsOneWidget);
    });

    testWidgets('liste vide et serveur injoignable', (tester) async {
      await _ouvrir(tester, _FakeService([]));
      expect(find.text('Aucune décision à prendre'), findsOneWidget);
    });

    testWidgets('serveur injoignable ou trop ancien : possibilité de réessayer', (tester) async {
      await _ouvrir(tester, _FakeService(null));
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('aucun débordement sur mobile', (tester) async {
      await _ouvrir(tester, _FakeService([_lustre(), _doublon()]), size: const Size(380, 800));
      expect(tester.takeException(), isNull);
    });
  });

  group('conflits de synchronisation', () {
    testWidgets("la bannière les compte et l'écran montre les deux fiches côte à côte", (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: DecisionsAlert(service: _FakeService([], conflits: [_conflitProduit(), _conflitCompte()])))));
      await tester.pumpAndSettle();
      expect(find.text('2 décision(s) à prendre'), findsOneWidget);
      expect(find.textContaining('2 conflit(s) de synchronisation'), findsOneWidget);

      await _ouvrir(tester, _FakeService([], conflits: [_conflitProduit()]));
      expect(find.text('Conflits de synchronisation'), findsOneWidget);
      await tester.tap(find.text('Deux produits avec la même référence'));
      await tester.pumpAndSettle();
      expect(find.text('Sur ce poste'), findsOneWidget);
      expect(find.text('Dans le cloud'), findsOneWidget);
      expect(find.text('Nom : LUSTRE LOCAL'), findsOneWidget);
      expect(find.text('Nom : LUSTRE CLOUD'), findsOneWidget);
      expect(find.text('Appliquer cette décision'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Appliquer cette décision')).onPressed, isNull, reason: 'aucune option conseillée : on choisit');
    });

    testWidgets('renommer : valeur proposée modifiable, confirmation, envoi avec la valeur choisie', (tester) async {
      final svc = _FakeService([], conflits: [_conflitProduit()]);
      await _ouvrir(tester, svc);
      await tester.tap(find.text('Deux produits avec la même référence'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ce sont deux fiches différentes : renommer celle de ce poste'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'LUS-1-2'), findsOneWidget, reason: 'valeur proposée');
      await tester.enterText(find.byType(TextField), 'LUS-LOCAL');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Appliquer cette décision'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer cette décision'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmer cette décision ?'), findsOneWidget);
      expect(find.text('Nouveau référence : LUS-LOCAL'), findsOneWidget);
      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();
      expect(svc.appelsConflit, [
        ['sync:produits:150000005', 'renommer', 'LUS-LOCAL']
      ]);
      expect(find.text('Aucune décision à prendre'), findsOneWidget, reason: 'le conflit résolu disparaît');
      await _viderMessages(tester);
    });

    testWidgets("compte : l'option conseillée (additionner) est présélectionnée, annuler n'envoie rien", (tester) async {
      final svc = _FakeService([], conflits: [_conflitCompte()]);
      await _ouvrir(tester, svc);
      await tester.tap(find.text('Compte client de MBARGA Paul en double'));
      await tester.pumpAndSettle();
      expect(find.text('conseillé'), findsOneWidget);
      await tester.ensureVisible(find.text('Appliquer cette décision'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer cette décision'));
      await tester.pumpAndSettle();
      expect(find.text('Solde final : -25 000 FCFA'), findsWidgets);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(svc.appelsConflit, isEmpty);
    });

    testWidgets("refus du serveur : conflit conservé, rien n'est enregistré", (tester) async {
      final svc = _FakeService([], conflits: [_conflitCompte()])..erreur = "Ce conflit n'existe plus";
      await _ouvrir(tester, svc);
      await tester.tap(find.text('Compte client de MBARGA Paul en double'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Appliquer cette décision'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer cette décision'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();
      expect(svc.appelsConflit, isEmpty);
      expect(find.text('Compte client de MBARGA Paul en double'), findsOneWidget, reason: 'conservé');
      await _viderMessages(tester);
    });

    testWidgets('non-administrateur : consultation seulement', (tester) async {
      await _ouvrir(tester, _FakeService([], conflits: [_conflitCompte()]), canDecide: false);
      await tester.tap(find.text('Compte client de MBARGA Paul en double'));
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Appliquer cette décision')).onPressed, isNull);
    });
  });
}
