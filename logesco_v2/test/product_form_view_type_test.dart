import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/products/models/category_model.dart';
import 'package:logesco_v2/features/products/services/api_product_service.dart';
import 'package:logesco_v2/features/products/services/category_service.dart';
import 'package:logesco_v2/features/products/views/product_form_view.dart';

// Remplaçants enregistrés dans Get : ils héritent de GetxService (cycle de vie) et n'implémentent que ce qui sert
class _Produits extends GetxService implements ApiProductService {
  @override
  Future<String> generateProductReference() async => 'PRD0001';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories extends GetxService implements CategoryService {
  @override
  Future<List<Category>> getCategories() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _ouvrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  Get.testMode = true;
  // le formulaire retrouve ses services par Get.find : on y enregistre des remplaçants
  Get.put<ApiProductService>(_Produits());
  Get.put<CategoryService>(_Categories());
  await tester.pumpWidget(const GetMaterialApp(home: ProductFormView()));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => Get.reset());

  testWidgets("création : tant que le type n'est pas choisi, aucun champ n'est affiché", (tester) async {
    await _ouvrir(tester);
    expect(find.text('1. Quel type de produit ?'), findsOneWidget);
    expect(find.text('Choisissez le type ci-dessus pour afficher le formulaire.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing, reason: 'pas de bouton de création avant le choix');
  });

  testWidgets('produit physique : tous les champs, y compris prix d\'achat, seuil de stock et péremption', (tester) async {
    await _ouvrir(tester);
    await tester.tap(find.byKey(const ValueKey('type-produit')));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez le type ci-dessus pour afficher le formulaire.'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(9)); // référence, nom, description, prix, prix d'achat, remise, code-barre, catégorie, seuil
    expect(find.byType(SwitchListTile), findsNWidgets(3)); // référence auto, péremption, actif
  });

  testWidgets("service : prix d'achat, seuil de stock et péremption disparaissent", (tester) async {
    await _ouvrir(tester);
    await tester.tap(find.byKey(const ValueKey('type-service')));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(7), reason: "9 champs d'un produit moins prix d'achat et seuil");
    expect(find.byType(SwitchListTile), findsNWidgets(2), reason: 'référence auto et actif : plus de péremption');
    expect(find.text('Statut'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing, reason: 'en création, aucune confirmation');
  });

  testWidgets('changer de type en création garde ce qui a été saisi', (tester) async {
    await _ouvrir(tester);
    await tester.tap(find.byKey(const ValueKey('type-produit')));
    await tester.pumpAndSettle();
    final nom = find.byType(TextFormField).at(1); // 0 = référence, 1 = nom
    await tester.enterText(nom, 'INSTALLATION');
    await tester.tap(find.byKey(const ValueKey('type-service')));
    await tester.pumpAndSettle();
    expect(find.text('INSTALLATION'), findsOneWidget);
  });
}
