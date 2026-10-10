import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/products/services/service_products_review_service.dart';
import 'package:logesco_v2/features/products/views/service_products_review_page.dart';
import 'package:logesco_v2/features/products/widgets/service_products_alert.dart';

class _FakeService implements ServiceProductsReviewService {
  List<ServiceProductToReview>? items;
  final List<int> marques = [];
  String? erreur;

  _FakeService(this.items);

  @override
  Future<List<ServiceProductToReview>?> fetch() async => items == null ? null : [...items!];

  @override
  Future<void> markPhysical(int productId) async {
    if (erreur != null) throw Exception(erreur);
    marques.add(productId);
    items = items!.where((p) => p.id != productId).toList();
  }
}

const _lustre = ServiceProductToReview(id: 104, reference: 'PRD20260097', nom: 'LUSTRE MODÈLE D6328 P', quantiteRecue: 98, quantiteVendue: 8, stockAffiche: 98);
const _disj = ServiceProductToReview(id: 102, reference: 'PRD1', nom: 'DISJONCTEUR COMPACT 250A', quantiteRecue: 3, quantiteVendue: 0, stockAffiche: 3);

Widget _app(Widget child) => GetMaterialApp(home: Scaffold(body: child));

void main() {
  tearDown(() => Get.reset());

  group('bannière', () {
    testWidgets('visible quand des produits sont à vérifier, avec les unités vendues sans sortie', (tester) async {
      await tester.pumpWidget(_app(ServiceProductsAlert(service: _FakeService([_lustre, _disj]))));
      await tester.pumpAndSettle();
      expect(find.text('2 produit(s) marqué(s) « service » ont du stock — à vérifier'), findsOneWidget);
      expect(find.text("8 unité(s) vendues n'ont jamais diminué le stock"), findsOneWidget);
    });

    testWidgets('invisible quand il n\'y a rien à vérifier', (tester) async {
      await tester.pumpWidget(_app(ServiceProductsAlert(service: _FakeService([]))));
      await tester.pumpAndSettle();
      expect(find.textContaining('marqué(s) « service »'), findsNothing);
    });

    testWidgets('invisible quand le serveur ne fournit pas la liste (ancienne version)', (tester) async {
      await tester.pumpWidget(_app(ServiceProductsAlert(service: _FakeService(null))));
      await tester.pumpAndSettle();
      expect(find.textContaining('marqué(s) « service »'), findsNothing);
    });
  });

  group('écran « Produits à vérifier »', () {
    testWidgets('liste chaque produit avec reçu / vendu / stock et l\'alerte de ventes sans sortie', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: ServiceProductsReviewPage(service: _FakeService([_lustre, _disj]))));
      await tester.pumpAndSettle();
      expect(find.text('LUSTRE MODÈLE D6328 P'), findsOneWidget);
      expect(find.text('Reçu : 98'), findsOneWidget);
      expect(find.text('Vendu : 8'), findsOneWidget);
      expect(find.text('Stock affiché : 98'), findsOneWidget);
      expect(find.textContaining('8 unité(s) vendue(s) sans sortie de stock'), findsOneWidget);
      expect(find.text('8 unité(s) ont été vendues sans sortir du stock.'), findsOneWidget);
      // le produit sans vente n'a pas ce message
      expect(find.text('DISJONCTEUR COMPACT 250A'), findsOneWidget);
    });

    testWidgets('« C\'est un produit physique » : confirmation, puis le produit quitte la liste', (tester) async {
      final fake = _FakeService([_lustre, _disj]);
      await tester.pumpWidget(GetMaterialApp(home: ServiceProductsReviewPage(service: fake)));
      await tester.pumpAndSettle();

      await tester.tap(find.text("C'est un produit physique").first);
      await tester.pumpAndSettle();
      // la confirmation prévient que le stock affiché n'est pas corrigé
      expect(find.text('Remettre en produit physique ?'), findsOneWidget);
      expect(find.textContaining('Cela ne corrige pas le stock affiché (98)'), findsOneWidget);

      await tester.tap(find.text("Oui, c'est un produit physique"));
      await tester.pumpAndSettle();
      expect(fake.marques, [104]);
      expect(find.text('LUSTRE MODÈLE D6328 P'), findsNothing);
      expect(find.text('DISJONCTEUR COMPACT 250A'), findsOneWidget);
    });

    testWidgets('annuler la confirmation ne modifie rien', (tester) async {
      final fake = _FakeService([_lustre]);
      await tester.pumpWidget(GetMaterialApp(home: ServiceProductsReviewPage(service: fake)));
      await tester.pumpAndSettle();
      await tester.tap(find.text("C'est un produit physique"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(fake.marques, isEmpty);
      expect(find.text('LUSTRE MODÈLE D6328 P'), findsOneWidget);
    });

    testWidgets('liste vide : message rassurant', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: ServiceProductsReviewPage(service: _FakeService([]))));
      await tester.pumpAndSettle();
      expect(find.text('Aucun produit à vérifier'), findsOneWidget);
    });

    testWidgets('serveur injoignable ou trop ancien : possibilité de réessayer', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: ServiceProductsReviewPage(service: _FakeService(null))));
      await tester.pumpAndSettle();
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('aucun débordement sur mobile', (tester) async {
      tester.view.physicalSize = const Size(380, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(GetMaterialApp(home: ServiceProductsReviewPage(service: _FakeService([_lustre, _disj]))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
