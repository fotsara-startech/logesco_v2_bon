import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/core/services/permission_service.dart';
import 'package:logesco_v2/features/products/controllers/product_controller.dart';
import 'package:logesco_v2/features/products/models/product.dart';
import 'package:logesco_v2/features/products/services/api_product_service.dart';
import 'package:logesco_v2/features/products/widgets/product_card.dart';
import 'package:logesco_v2/features/products/widgets/product_price_alert.dart';

Product _p({double vente = 1000, double? achat, bool service = false, int id = 1, String nom = 'ARTICLE'}) => Product(
      id: id,
      reference: 'R$id',
      nom: nom,
      prixUnitaire: vente,
      prixAchat: achat,
      seuilStockMinimum: 0,
      estActif: true,
      estService: service,
      dateCreation: DateTime(2026, 1, 1),
      dateModification: DateTime(2026, 1, 1),
    );

class _Permissions extends PermissionService {
  final bool modifier;
  _Permissions(this.modifier);

  @override
  bool hasPermission(String module, String privilege) => privilege == 'UPDATE' ? modifier : false;
}

class _Service extends Fake implements ApiProductService {}

void main() {
  tearDown(() => Get.reset());

  group("règle : vendu moins cher que le prix d'achat", () {
    test("prix de vente inférieur au prix d'achat : à perte, avec le montant perdu par unité", () {
      final p = _p(vente: 15000, achat: 17000);
      expect(p.vendAPerte, isTrue);
      expect(p.perteUnitaire, 2000);
    });

    test('cas qui ne sont PAS une anomalie', () {
      expect(_p(vente: 17000, achat: 17000).vendAPerte, isFalse, reason: 'marge nulle : discutable mais pas incohérent');
      expect(_p(vente: 20000, achat: 17000).vendAPerte, isFalse);
      expect(_p(vente: 100, achat: null).vendAPerte, isFalse, reason: "prix d'achat inconnu : rien à comparer");
      expect(_p(vente: 100, achat: 0).vendAPerte, isFalse, reason: "prix d'achat nul : pas renseigné");
      expect(_p(vente: 100, achat: 500, service: true).vendAPerte, isFalse, reason: "un service n'a pas de prix d'achat");
      expect(_p(vente: 20000, achat: 17000).perteUnitaire, 0);
    });
  });

  group('bandeau', () {
    Widget app(int n, {bool filtering = false, VoidCallback? onToggle}) => MaterialApp(home: Scaffold(body: ProductPriceAlert(count: n, filtering: filtering, onToggle: onToggle ?? () {})));

    testWidgets('invisible sans produit concerné', (tester) async {
      await tester.pumpWidget(app(0));
      expect(find.textContaining('moins cher'), findsNothing);
    });

    testWidgets('singulier / pluriel et bouton « Voir ces produits »', (tester) async {
      var n = 0;
      await tester.pumpWidget(app(1, onToggle: () => n++));
      expect(find.text("1 produit vendu moins cher que son prix d'achat"), findsOneWidget);
      await tester.tap(find.text('Voir ces produits'));
      expect(n, 1);

      await tester.pumpWidget(app(7));
      expect(find.text("7 produits vendus moins cher que leur prix d'achat"), findsOneWidget);
    });

    testWidgets('liste déjà filtrée : le bouton propose de tout afficher', (tester) async {
      await tester.pumpWidget(app(3, filtering: true));
      expect(find.text('Tout afficher'), findsOneWidget);
      expect(find.text('Voir ces produits'), findsNothing);
    });
  });

  group('carte produit', () {
    Future<void> carte(WidgetTester tester, Product p, {bool modifier = true, VoidCallback? onEdit}) async {
      Get.put<PermissionService>(_Permissions(modifier));
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: SingleChildScrollView(child: ProductCard(product: p, onEdit: onEdit)))));
    }

    testWidgets('produit à perte : alerte avec la perte par unité et accès direct à la correction', (tester) async {
      var edits = 0;
      await carte(tester, _p(vente: 15000, achat: 17000), onEdit: () => edits++);
      expect(find.textContaining("Prix de vente inférieur au prix d'achat"), findsOneWidget);
      expect(find.textContaining('par unité vendue'), findsOneWidget);
      await tester.tap(find.text('Corriger'));
      expect(edits, 1);
    });

    testWidgets("sans droit de modification : l'alerte reste visible, pas le bouton Corriger", (tester) async {
      await carte(tester, _p(vente: 15000, achat: 17000), modifier: false, onEdit: () {});
      expect(find.textContaining("Prix de vente inférieur au prix d'achat"), findsOneWidget);
      expect(find.text('Corriger'), findsNothing);
    });

    testWidgets('produit cohérent : aucune alerte', (tester) async {
      await carte(tester, _p(vente: 20000, achat: 17000), onEdit: () {});
      expect(find.textContaining('Prix de vente inférieur'), findsNothing);
      expect(find.text('Corriger'), findsNothing);
    });
  });

  group('filtre de la liste', () {
    ProductController controleur(List<Product> produits) {
      final c = ProductController(productService: _Service());
      c.products.assignAll(produits);
      return c;
    }

    final liste = [
      _p(id: 1, vente: 15000, achat: 17000, nom: 'A PERTE'),
      _p(id: 2, vente: 20000, achat: 17000),
      _p(id: 3, vente: 500, achat: 900, nom: 'B PERTE'),
      _p(id: 4, vente: 100, service: true),
    ];

    test('compte les produits à perte ; sans filtre, toute la liste est affichée', () {
      final c = controleur(liste);
      expect(c.produitsAPerte.map((p) => p.id), [1, 3]);
      expect(c.priceFilteredProducts.length, 4);
    });

    test('filtre « prix à vérifier » : seulement ces produits ; « effacer les filtres » le retire', () {
      final c = controleur(liste);
      c.basculerFiltrePrixAPerte();
      expect(c.priceFilteredProducts.map((p) => p.id), [1, 3]);
      c.clearFilters();
      expect(c.filtrePrixAPerte.value, isFalse);
      expect(c.priceFilteredProducts.length, 4);
    });

    test('une fois tous les prix corrigés, le filtre se retire de lui-même (pas de liste vide trompeuse)', () {
      final c = controleur(liste);
      c.basculerFiltrePrixAPerte();
      c.products.assignAll([_p(id: 1, vente: 18000, achat: 17000), _p(id: 2, vente: 20000, achat: 17000)]);
      expect(c.produitsAPerte, isEmpty);
      expect(c.priceFilteredProducts.length, 2, reason: "le filtre est ignoré quand plus rien n'est à corriger");
    });
  });
}
