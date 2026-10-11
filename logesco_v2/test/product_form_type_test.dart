import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/products/controllers/product_form_controller.dart';
import 'package:logesco_v2/features/products/models/category_model.dart';
import 'package:logesco_v2/features/products/models/product.dart';
import 'package:logesco_v2/features/products/services/api_product_service.dart';
import 'package:logesco_v2/features/products/services/category_service.dart';

class _Produits extends Fake implements ApiProductService {
  @override
  Future<String> generateProductReference() async => 'PRD0001';
}

class _Categories extends Fake implements CategoryService {
  @override
  Future<List<Category>> getCategories() async => [];
}

Product _produit({required bool service}) => Product(
      id: 7,
      reference: 'PRD7',
      nom: 'LUSTRE',
      prixUnitaire: 38000,
      prixAchat: 17000,
      seuilStockMinimum: 5,
      remiseMaxAutorisee: 0,
      estActif: true,
      estService: service,
      gestionPeremption: !service,
      dateCreation: DateTime(2026, 1, 1),
      dateModification: DateTime(2026, 1, 1),
    );

ProductFormController _controleur() {
  Get.testMode = true;
  final c = ProductFormController(productService: _Produits(), categoryService: _Categories());
  c.onInit();
  return c;
}

void main() {
  tearDown(() => Get.reset());

  test('création : le type n\'est pas défini au départ, le formulaire ne peut pas être validé', () async {
    final c = _controleur();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.typeDefini.value, isFalse);
    c.nomController.text = 'LUSTRE';
    c.prixUnitaireController.text = '38000';
    expect(c.isFormValid, isFalse, reason: 'tant que le type n\'est pas choisi');
    c.appliquerType(false);
    expect(c.isFormValid, isTrue);
  });

  test('choisir « service » vide et neutralise prix d\'achat, seuil de stock et péremption', () async {
    final c = _controleur();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    c.nomController.text = 'LIVRAISON';
    c.prixUnitaireController.text = '2000';
    c.appliquerType(false);
    c.prixAchatController.text = '1500';
    c.seuilStockController.text = '9';
    c.gestionPeremption.value = true;

    c.appliquerType(true);
    expect(c.estService.value, isTrue);
    expect(c.typeDefini.value, isTrue);
    expect(c.prixAchatController.text, '');
    expect(c.seuilStockController.text, '0');
    expect(c.gestionPeremption.value, isFalse);
    expect(c.isFormValid, isTrue, reason: 'un service est valide sans prix d\'achat ni seuil');
  });

  test('modification produit → service puis retour : les valeurs d\'origine sont retrouvées', () async {
    final c = _controleur();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final p = _produit(service: false);
    c.isEditing.value = true;
    c.editingProduct.value = p;
    c.typeDefini.value = true;
    c.estService.value = false;
    c.prixAchatController.text = '17000.0';
    c.seuilStockController.text = '5';
    c.gestionPeremption.value = true;
    expect(c.typeModifie, isFalse);

    c.appliquerType(true);
    expect(c.typeModifie, isTrue);
    expect(c.prixAchatController.text, '');
    expect(c.seuilStockController.text, '0');

    c.appliquerType(false); // la personne revient au type d'origine
    expect(c.typeModifie, isFalse);
    expect(c.prixAchatController.text, '17000.0');
    expect(c.seuilStockController.text, '5');
    expect(c.gestionPeremption.value, isTrue);
  });

  test('modification service → produit : seuil et prix d\'achat restent à renseigner, le type est marqué modifié', () async {
    final c = _controleur();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    c.isEditing.value = true;
    c.editingProduct.value = _produit(service: true);
    c.typeDefini.value = true;
    c.estService.value = true;
    c.appliquerType(false);
    expect(c.typeModifie, isTrue);
    expect(c.estService.value, isFalse);
  });

  group("avertissement : prix de vente inférieur au prix d'achat", () {
    Future<ProductFormController> produit() async {
      final c = _controleur();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      c.appliquerType(false);
      c.nomController.text = 'BATTERIE';
      return c;
    }

    test("apparaît dès que le prix de vente saisi est inférieur au prix d'achat, avec la perte par unité", () async {
      final c = await produit();
      c.prixUnitaireController.text = '15000';
      c.prixAchatController.text = '17000';
      expect(c.avertissementPrix.value, contains('inférieur au prix d\'achat'));
      expect(c.avertissementPrix.value, contains('2'), reason: 'la perte par unité (2 000) est indiquée');
      expect(c.avertissementPrix.value, contains('erreur de saisie'));
    });

    test("ne bloque jamais l'enregistrement : le formulaire reste valide", () async {
      final c = await produit();
      c.prixUnitaireController.text = '15000';
      c.prixAchatController.text = '17000';
      expect(c.avertissementPrix.value, isNotEmpty);
      expect(c.isFormValid, isTrue);
    });

    test('disparaît quand le prix est corrigé, dans un sens comme dans l\'autre', () async {
      final c = await produit();
      c.prixUnitaireController.text = '15000';
      c.prixAchatController.text = '17000';
      c.prixUnitaireController.text = '20000'; // on corrige le prix de vente
      expect(c.avertissementPrix.value, isEmpty);
      c.prixAchatController.text = '25000'; // puis l'achat redépasse la vente
      expect(c.avertissementPrix.value, isNotEmpty);
      c.prixAchatController.text = '19000'; // et on corrige le prix d'achat
      expect(c.avertissementPrix.value, isEmpty);
    });

    test("pas d'avertissement quand rien n'est comparable : prix d'achat vide, nul, ou marge nulle", () async {
      final c = await produit();
      c.prixUnitaireController.text = '1000';
      expect(c.avertissementPrix.value, isEmpty, reason: "prix d'achat vide");
      c.prixAchatController.text = '0';
      expect(c.avertissementPrix.value, isEmpty, reason: "prix d'achat nul");
      c.prixAchatController.text = '1000';
      expect(c.avertissementPrix.value, isEmpty, reason: 'marge nulle : pas incohérent');
    });

    test("un service n'a pas de prix d'achat : l'avertissement disparaît avec le type", () async {
      final c = await produit();
      c.prixUnitaireController.text = '15000';
      c.prixAchatController.text = '17000';
      expect(c.avertissementPrix.value, isNotEmpty);
      c.appliquerType(true);
      expect(c.avertissementPrix.value, isEmpty);
    });
  });
}
