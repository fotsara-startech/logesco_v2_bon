import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/sync/models/sync_doublons.dart';
import 'package:logesco_v2/features/sync/services/sync_status_service.dart';
import 'package:logesco_v2/features/sync/widgets/sync_doublons_card.dart';

Widget _carte(List<SyncDoublonGroup> g, {VoidCallback? onActualiser}) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SyncDoublonsCard(groupes: g, onActualiser: onActualiser))));

final _clients = {
  'table': 'clients',
  'libelle': 'Client',
  'nombre': 2,
  'fiches': [
    {'id': 10000001, 'libelle': 'Jean Dupont · 699000111', 'solde': -3000},
    {'id': 20000001, 'libelle': 'Jean Dupont · 699000111', 'solde': -1300},
  ],
};

void main() {
  test('les groupes de doublons envoyés par le serveur sont lus (fiches, soldes, total)', () {
    final g = SyncDoublonGroup.listeDepuis([_clients]);
    expect(g, hasLength(1));
    expect(g.first.libelle, 'Client');
    expect(g.first.nombre, 2);
    expect(g.first.titre, 'Jean Dupont · 699000111');
    expect(g.first.fiches.map((f) => f.solde), [-3000.0, -1300.0]);
    expect(g.first.soldeTotal, -4300.0);
  });

  test('une boutique n\'a pas de solde : pas de total', () {
    final g = SyncDoublonGroup.fromJson({
      'table': 'boutiques',
      'libelle': 'Boutique',
      'fiches': [
        {'id': 1, 'libelle': 'Annexe'},
        {'id': 20000001, 'libelle': 'Annexe'},
      ],
    });
    expect(g.soldeTotal, isNull);
    expect(g.fiches.every((f) => f.solde == null), isTrue);
  });

  test('absent ou mal formé : liste vide, sans erreur (serveur ancien)', () {
    expect(SyncDoublonGroup.listeDepuis(null), isEmpty);
    expect(SyncDoublonGroup.listeDepuis([]), isEmpty);
  });

  test('le rapport d\'écart porte les doublons ; sans eux il en a zéro', () {
    final base = SyncDriftReport.fromJson({
      'resume': {'inexpliques': 0, 'anciens': 0, 'connus': 0},
      'ecarts': [],
    });
    expect(base.doublons, isEmpty);
    final avec = base.avecDoublons(SyncDoublonGroup.listeDepuis([_clients]));
    expect(avec.doublons, hasLength(1));
    expect(avec.inexpliques, 0, reason: 'le reste du rapport est conservé');
  });

  test('le poste d\'origine d\'une fiche se déduit de son identifiant', () {
    expect(SyncDoublonsCard.posteDe(1), 'poste d\'origine');
    expect(SyncDoublonsCard.posteDe(10000001), 'poste n°1');
    expect(SyncDoublonsCard.posteDe(20000015), 'poste n°2');
  });

  test('les montants sont lisibles : séparateur de milliers et signe', () {
    expect(SyncDoublonsCard.montant(-3000), '-3 000');
    expect(SyncDoublonsCard.montant(1234567), '1 234 567');
    expect(SyncDoublonsCard.montant(0), '0');
    expect(SyncDoublonsCard.montant(-45), '-45');
  });

  testWidgets('aucun doublon : la carte ne s\'affiche pas du tout', (tester) async {
    await tester.pumpWidget(_carte(const []));
    expect(find.byType(Card), findsNothing);
    expect(find.textContaining('doublon'), findsNothing);
  });

  testWidgets('doublons : titre, fiches avec leur poste et leur solde', (tester) async {
    await tester.pumpWidget(_carte(SyncDoublonGroup.listeDepuis([_clients])));
    expect(find.text('1 doublon(s) probable(s) de fiches'), findsOneWidget);
    expect(find.text('Client · Jean Dupont · 699000111'), findsOneWidget);
    expect(find.textContaining('fiche n°10000001 (poste n°1) — solde -3 000'), findsOneWidget);
    expect(find.textContaining('fiche n°20000001 (poste n°2) — solde -1 300'), findsOneWidget);
  });

  testWidgets('deux fiches avec un solde : mise en garde avec le total avant de supprimer', (tester) async {
    await tester.pumpWidget(_carte(SyncDoublonGroup.listeDepuis([_clients])));
    expect(find.textContaining('ne supprimez aucune fiche avant d\'avoir regroupé les montants (total -4 300)'), findsOneWidget);
  });

  testWidgets('une seule fiche porte un solde : pas de mise en garde', (tester) async {
    final g = {
      'table': 'clients',
      'libelle': 'Client',
      'fiches': [
        {'id': 1, 'libelle': 'Marie Ngono · 690000009', 'solde': 0},
        {'id': 20000001, 'libelle': 'Marie Ngono · 690000009', 'solde': -500},
      ],
    };
    await tester.pumpWidget(_carte(SyncDoublonGroup.listeDepuis([g])));
    expect(find.textContaining('ne supprimez aucune fiche'), findsNothing);
  });

  testWidgets('l\'application ne propose AUCUNE fusion : elle explique et laisse décider', (tester) async {
    await tester.pumpWidget(_carte(SyncDoublonGroup.listeDepuis([_clients])));
    expect(find.textContaining('ne les fusionne pas toute seule'), findsOneWidget);
    expect(find.text('Fusionner'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('le bouton « Revérifier » relance le contrôle', (tester) async {
    var appels = 0;
    await tester.pumpWidget(_carte(SyncDoublonGroup.listeDepuis([_clients]), onActualiser: () => appels++));
    await tester.tap(find.byTooltip('Revérifier'));
    expect(appels, 1);
  });
}
