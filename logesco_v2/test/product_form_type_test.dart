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
}
